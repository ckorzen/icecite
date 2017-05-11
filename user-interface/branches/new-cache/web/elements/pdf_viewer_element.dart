library pdf_viewer_element;

import 'dart:convert';
import 'dart:html';
import 'icecite_element.dart';
import '../models/models.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('pdf-viewer-element')
/// Our implementation of an object-element.
class PdfViewerElement extends IceciteElement {   
  Logger LOG = logging.get("pdf-viewer-element");
  
  DivElement iFrameWrapper;
  Map<String, IFrameElement> iFrames = {};
    
  // The name of "annot-deleted" event
  static const String EVENT_ANNOT_ADDED = "annot-added";
  // The name of "annot-updated" event
  static const String EVENT_ANNOT_UPDATED = "annot-updated";
  // The name of "annot-deleted" event
  static const String EVENT_ANNOT_DELETED = "annot-deleted";
  // The name of "import-from-pdf" event
  static const String IMPORT_REQUEST = "import-request";
  // The name of "prev-entry-request" event
  static const String SELECT_PREV_ENTRY_REQUEST = "select-prev-request";
  // The name of "next-entry-request" event
  static const String SELECT_NEXT_ENTRY_REQUEST = "select-next-request";
  // The name of "scroll-history-start" event
  static const String START_HISTORY_REQUEST = "start-history-request";
  // The name of "scroll-history-end" event
  static const String END_HISTORY_REQUEST = "end-history-request";
  // The name of "fullscreen-toggle" event
  static const String TOGGLE_FULLSCREEN_REQUEST = "toggle-fullscreen-request";
  
  /// The constructor.
  PdfViewerElement.created() : super.created() {
    listenForPdfMessages();
  }
  
  @override
  void attached() {
    super.attached();
    this.iFrameWrapper = get("pdf-viewer-wrapper");
  }
    
  // ___________________________________________________________________________
  // Actions.

  /// Displays the given blob of given entry.
  void display(LibraryEntry entry, Blob blob, {Iterable annots, List references}) {
    if (entry == null) return;
    
    if (iFrames.containsKey(entry.id)) {
      displayIFrame(iFrames[entry.id]);
    } else {
      IFrameElement iFrame = createIFrame(entry);
      appendIFrame(iFrame);
      displayIFrame(iFrame);
      load(iFrame, entry, blob, annots, references);
    }
  }
      
  /// Creates an iFrame containing the pdf, given by blob.
  IFrameElement createIFrame(LibraryEntry entry) {
    IFrameElement iframe = document.createElement('iFrame');
    iframe.id = "pdf-viewer";
    iframe.className = "pdf-viewer";
    iframe.src = "external-scripts/pdfjs-annot/generic/web/viewer.html";
    iframe.onClick.listen((e) => print("iframe click"));
    iFrames[entry.id] = iframe;
    return iframe;
  }
  
  void load(iframe, entry, blob, annots, references) {
    LOG.finer("Loading entry $entry.");
    // Wait for the load of iFrame, so that it is able to receive messages.
    iframe.onLoad.listen((e) {
      // TODO: Avoid the conversion into list.
      List annotList = [];
      List referencesList = [];
      for (var annot in annots) {
        annotList.add(annot.data);
      }
      if (references != null) {
        for (var reference in references) {
          referencesList.add(reference.data);
        }
      }
        
      postMessage(iframe, {
        "type": "load", 
        "data": entry.toJson(), 
        "pdf": blob, 
        "annots": JSON.encode(annotList),
        "references": JSON.encode(referencesList),
        "author": "${user.firstName} ${user.lastName}"}
      );
    });
  }

  void appendIFrame(IFrameElement iFrame) {
    this.iFrameWrapper.children.add(iFrame);
  }
  
  void displayIFrame(IFrameElement iFrame) {
    hideIFrames();
    if (iFrame != null) {
      iFrame.style.display = "block";
    }
  }
  
  void hideIFrames() {
    for (var frame in iFrames.values) {
      hideIFrame(frame);
    }
  }
   
  void hideIFrame(IFrameElement iFrame) {
    if (iFrame == null) return;
    iFrame.style.display = "none";
  }
  
  void removeIFrame(LibraryEntry entry) {
    if (entry == null) return;
    if (!iFrames.containsKey(entry.id)) return;
    this.iFrameWrapper.children.remove(iFrames[entry.id]);
  }
  
  /// Clears the viewer.
  void clear() {
    this.iFrameWrapper.children.clear();
  }
  
  // ___________________________________________________________________________
  // Handler methods.
  
  /// Setups the message handler.
  void listenForPdfMessages() {
    // Add message event handler to window.
    window.onMessage.listen((event) {
      var message = event.data;
      if (message is Map) {
        switch (message['type']) {
          case "click":
            handlePdfClick();
            break;
          case "annotation-added":
            handleAnnotationAdded(message['data']);
            break;
          case "annotation-updated":
            handleAnnotationUpdated(message['data']);
            break;
          case "annotation-deleted":
            handleAnnotationDeleted(message['data']);
            break;
          case "import":
            handleImportRequest(message['data']);
            break;
          case "prev-entry":
            handleSelectPreviousEntryRequest();
            break;           
          case "next-entry":
            handleSelectNextEntryRequest();
            break;
          case "scroll-history-start":
            handleStartHistoryRequest();
            break;
          case "scroll-history-end":
            handleEndHistoryRequest();
            break;
          case "fullscreen-toggle":
            handleToggleFullscreenRequest();
            break;
          default:
            break;
        }
      }
    });
  }
     
  void handlePdfClick() {
    document.body.click();
  }
  
  /// Handles an annotation, added in pdf.
  void handleAnnotationAdded(String json) {
    LOG.finer("Handle annot added: ${json}");
    if (json != null) {
      fireAnnotAddedEvent(new PdfAnnotation.fromData(JSON.decode(json)));
    }
  }
  
  /// Handles an annotation, updated in pdf.
  void handleAnnotationUpdated(String json) {
    LOG.finer("Handle annot updated: ${json}");
    if (json != null) {
      fireAnnotUpdatedEvent(new PdfAnnotation.fromData(JSON.decode(json)));
    }
  }
  
  /// Handles an annotation, deleted in pdf.
  void handleAnnotationDeleted(String json) {
    LOG.finer("Handle annot deleted: ${json}");
    if (json != null) {
      fireAnnotDeletedEvent(new PdfAnnotation.fromData(JSON.decode(json)));
    }
  }
  
  /// Handles an import request.
  void handleImportRequest(String json) {
    LOG.finer("Handle import request: ${json}");
    if (json != null) {
      fireImportRequest(new ReferenceEntry.fromData(JSON.decode(json)));
    }
  }
  
  /// Handles a prev-entry request.
  void handleSelectPreviousEntryRequest() {
    LOG.finer("Handle prev-entry request.");
    fireSelectPreviousEntryEvent();
  }
  
  /// Handles a next-entry request.
  void handleSelectNextEntryRequest() {
    LOG.finer("Handle next-entry request.");
    fireSelectNextEntryRequest();
  }
  
  /// Handles a scroll-history-start request.
  void handleStartHistoryRequest() {
    LOG.finer("Handle start-scroll-history request.");
    fireStartHistoryRequest();
  }
  
  /// Handles a scroll-history-end request.
  void handleEndHistoryRequest() {
    LOG.finer("Handle end-scroll-history request.");
    fireEndHistoryRequest();
  }
  
  void handleToggleFullscreenRequest() {
    LOG.finer("Handle fullscreen-toggle request.");
    fireToggleFullscreenRequest();
  }
  
  // ___________________________________________________________________________
  // Send messages to pdf.
    
  /// Adds the given annotation to pdf.
  void addAnnotation(LibraryEntry entry, PdfAnnotation annot) {
    if (entry == null) return;
    var iFrame = iFrames[entry.id];
    LOG.finer("Add annot: ${annot.toJson()}");
    postMessage(iFrame, {"type": "set-annotation", "annot": annot.toJson()});
  }
  
  /// Updates the given annotation in pdf.
  void updateAnnotation(LibraryEntry entry, PdfAnnotation annot) {
    if (entry == null) return;
    var iFrame = iFrames[entry.id];
    if (iFrame == null) return;
    LOG.finer("Update annot: ${annot.toJson()}");
    postMessage(iFrame, {"type": "set-annotation", "annot": annot.toJson()});
  }
  
  /// Deletes the given annotation from pdf.
  void deleteAnnotation(LibraryEntry entry, PdfAnnotation annot) {
    if (entry == null) return;
    var iFrame = iFrames[entry.id];
    if (iFrame == null) return;
    LOG.finer("Delete annot: ${annot.toJson()}");
    postMessage(iFrame, {"type": "delete-annotation", "annot": annot.toJson()});
  }
  
  /// Jumps to the previous pdf view. 
  void jumpToPreviousPdfView() {
    LOG.finer("Jump to previous pdf view.");
    if (selectedEntry != null) {
      postMessage(iFrames[selectedEntry.id], {"type": "prev-view"});  
    }
  }
  
  /// Jumps to the next pdf view.
  void jumpToNextPdfView() {
    LOG.finer("Jump to next pdf view.");
    if (selectedEntry != null) {
      postMessage(iFrames[selectedEntry.id], {"type": "next-view"});  
    }
  }
  
  // ___________________________________________________________________________
  // Helper methods.
  
  /// Posts a message to the pdf.
  void postMessage(iFrame, message) {
    if (iFrame == null) return;
    iFrame.contentWindow.postMessage(message, "*"); 
  }
  
  /// Fires an annot-added event
  void fireAnnotAddedEvent(PdfAnnotation annot) {
    fire(EVENT_ANNOT_ADDED, detail: annot);
  }
  
  /// Fires an annot-updated event
  void fireAnnotUpdatedEvent(PdfAnnotation annot) {
    fire(EVENT_ANNOT_UPDATED, detail: annot);
  }
  
  /// Fires a annot-deleted event
  void fireAnnotDeletedEvent(PdfAnnotation annot) {
    fire(EVENT_ANNOT_DELETED, detail: annot);
  }
  
  /// Fires a import-from-pdf event
  void fireImportRequest(ReferenceEntry entry) {
    fire(IMPORT_REQUEST, detail: entry);
  }
  
  /// Fires a prev-entry request event
  void fireSelectPreviousEntryEvent() {
    fire(SELECT_PREV_ENTRY_REQUEST);
  }
  
  /// Fires a next-entry request event
  void fireSelectNextEntryRequest() {
    fire(SELECT_NEXT_ENTRY_REQUEST);
  }
  
  /// Fires a scroll-history-start-request event
  void fireStartHistoryRequest() {
    fire(START_HISTORY_REQUEST);
  }
  
  /// Fires a scroll-history-end-request event
  void fireEndHistoryRequest() {
    fire(END_HISTORY_REQUEST);
  }
  
  void fireToggleFullscreenRequest() {
    fire(TOGGLE_FULLSCREEN_REQUEST);
  }
}
