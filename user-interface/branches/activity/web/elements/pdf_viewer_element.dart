library pdf_viewer_element;

import 'dart:convert';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';
import '../models/models.dart';

@CustomTag('pdf-viewer-element')
/// Our implementation of an object-element.
class PdfViewerElement extends IceciteElement {   
  DivElement iFrameWrapper;
  Map<LibraryEntry, IFrameElement> iFrames = {};
    
  // The name of "annot-deleted" event
  static const String EVENT_ANNOT_ADDED = "annot-added";
  // The name of "annot-updated" event
  static const String EVENT_ANNOT_UPDATED = "annot-updated";
  // The name of "annot-deleted" event
  static const String EVENT_ANNOT_DELETED = "annot-deleted";
  // The name of "import-from-pdf" event
  static const String EVENT_IMPORT_FROM_PDF = "import-from-pdf";
  // The name of "prev-entry-request" event
  static const String EVENT_PREVIOUS_ENTRY_REQUEST = "prev-entry-request";
  // The name of "next-entry-request" event
  static const String EVENT_NEXT_ENTRY_REQUEST = "next-entry-request";
  // The name of "scroll-history-start" event
  static const String EVENT_START_SCROLL_HISTORY = "scroll-history-start";
  // The name of "scroll-history-end" event
  static const String EVENT_END_SCROLL_HISTORY = "scroll-history-end";
  // The name of "fullscreen-toggle" event
  static const String EVENT_FULLSCREEN_TOGGLE_REQUEST = "fullscreen-toggle-request";
  // ___________________________________________________________________________
  
  /// The constructor.
  PdfViewerElement.created() : super.created() {
    listenForPdfMessages();
  }
  
  void attached() {
    super.attached();
    this.iFrameWrapper = get("pdf-viewer-wrapper");
  }
  
  void onPreviousViewRequest() => handlePreviousViewRequest();
      
  void onNextViewRequest() => handleNextViewRequest();
  
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
    // Wait for the load of iFrame, so that it is able to receive messages.
    iframe.onLoad.listen((e) {
      // TODO: Avoid the conversion into list.
      List annotList = [];
      List referencesList = [];
      for (var annot in annots) {
        annotList.add(annot.map);
      }
      if (references != null) {
        for (var reference in references) {
          referencesList.add(reference.map);
        }
      }
        
      postMessage(iframe, {
        "type": "load", 
        "entryId": entry.id,
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
    if (iFrame == null) return;
    for (var frame in iFrames.values) {
      hideIFrame(frame);
    }
    iFrame.style.display = "block";
  }
  
  void hideIFrame(IFrameElement iFrame) {
    if (iFrame == null) return;
    iFrame.style.display = "none";
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
            handlePreviousEntryRequest();
            break;           
          case "next-entry":
            handleNextEntryRequest();
            break;
          case "scroll-history-start":
            handleStartScrollHistoryRequest();
            break;
          case "scroll-history-end":
            handleEndScrollHistoryRequest();
            break;
          case "fullscreen-toggle":
            handleFullscreenToggleRequest();
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
    print("(icecite) handle annot added: ${json}");
    if (json != null) {
      fireAnnotAddedEvent(new PdfAnnotation.fromMap(JSON.decode(json)));
    }
  }
  
  /// Handles an annotation, updated in pdf.
  void handleAnnotationUpdated(String json) {
    print("(icecite) handle annot updated: ${json}");
    if (json != null) {
      fireAnnotUpdatedEvent(new PdfAnnotation.fromMap(JSON.decode(json)));
    }
  }
  
  /// Handles an annotation, deleted in pdf.
  void handleAnnotationDeleted(String json) {
    print("(icecite) handle annot deleted: ${json}");
    if (json != null) {
      fireAnnotDeletedEvent(new PdfAnnotation.fromMap(JSON.decode(json)));
    }
  }
  
  /// Handles an import request.
  void handleImportRequest(String json) {
    print("(icecite) handle import request: ${json}");
    if (json != null) {
      fireImportFromPdfEvent(new LibraryEntry.fromMap(JSON.decode(json)));
    }
  }
  
  /// Handles a prev-entry request.
  void handlePreviousEntryRequest() {
    print("(icecite) handle prev-entry request.");
    firePreviousEntryRequestEvent();
  }
  
  /// Handles a next-entry request.
  void handleNextEntryRequest() {
    print("(icecite) handle next-entry request.");
    fireNextEntryRequestEvent();
  }
  
  /// Handles a scroll-history-start request.
  void handleStartScrollHistoryRequest() {
    print("(icecite) handle start-scroll-history request.");
    fireStartScrollHistoryRequestEvent();
  }
  
  /// Handles a scroll-history-end request.
  void handleEndScrollHistoryRequest() {
    print("(icecite) handle end-scroll-history request.");
    fireEndScrollHistoryRequestEvent();
  }
  
  void handleFullscreenToggleRequest() {
    print("(icecite) handle fullscreen-toggle request.");
    fireFullscreenToggleRequestEvent();
  }
  
  void handlePreviousViewRequest() {
    if (selectedEntry != null) {
      postMessage(iFrames[selectedEntry.id], {"type": "prev-view"});  
    }
  }
    
  void handleNextViewRequest() {
    if (selectedEntry != null) {
      postMessage(iFrames[selectedEntry.id], {"type": "next-view"});  
    }
  }
    
  
  // ___________________________________________________________________________
  // Send messages to pdf.
    
  /// Adds the given annotation to pdf.
  void addAnnotation(LibraryEntry entry, PdfAnnotation annot) {
    if (entry == null) return;
    var iFrame = iFrames[entry.id];
    print("(icecite) add annot: ${annot.toJson()}");
    postMessage(iFrame, {"type": "set-annotation", "annot": annot.toJson()});
  }
  
  /// Updates the given annotation in pdf.
  void updateAnnotation(LibraryEntry entry, PdfAnnotation annot) {
    if (entry == null) return;
    var iFrame = iFrames[entry.id];
    if (iFrame == null) return;
    print("(icecite) update annot: ${annot.toJson()}");
    postMessage(iFrame, {"type": "set-annotation", "annot": annot.toJson()});
  }
  
  /// Deletes the given annotation from pdf.
  void deleteAnnotation(LibraryEntry entry, PdfAnnotation annot) {
    if (entry == null) return;
    var iFrame = iFrames[entry.id];
    if (iFrame == null) return;
    print("(icecite) delete annot: ${annot.toJson()}");
    postMessage(iFrame, {"type": "delete-annotation", "annot": annot.toJson()});
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
  void fireImportFromPdfEvent(LibraryEntry entry) {
    fire(EVENT_IMPORT_FROM_PDF, detail: entry);
  }
  
  /// Fires a prev-entry request event
  void firePreviousEntryRequestEvent() {
    fire(EVENT_PREVIOUS_ENTRY_REQUEST);
  }
  
  /// Fires a next-entry request event
  void fireNextEntryRequestEvent() {
    fire(EVENT_NEXT_ENTRY_REQUEST);
  }
  
  /// Fires a scroll-history-start-request event
  void fireStartScrollHistoryRequestEvent() {
    fire(EVENT_START_SCROLL_HISTORY);
  }
  
  /// Fires a scroll-history-end-request event
  void fireEndScrollHistoryRequestEvent() {
    fire(EVENT_END_SCROLL_HISTORY);
  }
  
  void fireFullscreenToggleRequestEvent() {
    fire(EVENT_FULLSCREEN_TOGGLE_REQUEST);
  }
}
