@MirrorsUsed(targets: 'LibraryEntry')
library display_view;

import 'dart:html' hide ObjectElement;
import 'dart:mirrors';
import 'dart:collection';
import 'package:polymer/polymer.dart';
import '../elements/icecite_element.dart';
import '../elements/pdf_viewer_element.dart';
import '../models/models.dart';

/// The display view of Icecite, displaying the pdf of a library entry.
@CustomTag('display-view')
class DisplayView extends IceciteElement {  
  /// Cache, mapping an annotId to the current rev of an annotation.
  Map<String, String> annotRevsCache = {};
  /// Cache, mapping an annotId to the queue of its modifications.
  Map<String, Queue<PdfAnnotation>> dbQueues = {};
  
  /// The pdf viewer.
  PdfViewerElement pdfViewer;
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  DisplayView.created() : super.created();
  
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    reset();
  }
    
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever this view was revealed.
  void onRevealed() => handleRevealed(); // _revealElements();
  
  /// This method is called, whenever the selected entry was changed.
  void selectedEntryChanged(prevSelectedEntry) => handleSelectedEntryChange();
    
  /// Define the behavior when an annot in storage was added or updated.
  void onPdfAnnotChangedInDb(annot) => handlePdfAnnotChangedInDb(annot);
    
  /// Define the behavior when an entry in storage was deleted.
  void onPdfAnnotDeletedInDb(annot) => handlePdfAnnotDeletedInDb(annot);
  
  /// Define the behavior when an entry in storage was added or updated.
  void onLibraryEntryChangedInDb(entry) => handleLibraryEntryChangedInDb(entry);
            
  /// Define the behavior when an entry in storage was deleted.
  void onLibraryEntryDeletedInDb(entry) => handleLibraryEntryDeletedInDb(entry);
      
  /// This method is called, whenever an entry was selected.
  void onLibraryEntrySelected(entry) => handleLibraryEntrySelected(entry);
  
  /// This method is called, whenever an annotation was added in pdf locally.
  void onAnnotAdded(event, annot) => handleAnnotAdded(event, annot);
  
  /// This method is called, whenever an annotation was updated in pdf locally.
  void onAnnotUpdated(event, annot) => handleAnnotUpdated(event, annot);

  /// This method is called, whenever an annotation was deleted in pdf locally.
  void onAnnotDeleted(event, annot) => handleAnnotDeleted(event, annot);
    
  void onPreviousViewRequest() => handlePreviousViewRequest();
      
  void onNextViewRequest() => handleNextViewRequest();
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Reveals the elements of this view.
  void handleRevealed() {
    this.pdfViewer = get("pdf-viewer-element");
//    this.pdfViewer = get("pdf-object");
  }
  
  /// Handles the selection of a library entry.
  void handleLibraryEntrySelected(LibraryEntry entry) {
    // Set the selected entry, if it is a library entry.
    if (entry != null && entry.brand != 'entry') return;
    selectedEntry = entry; // Will trigger the call of selectedEntryChanged.
  }
  
  /// Handles the change of selected entry.
  void handleSelectedEntryChange() {
    if (selectedEntry == null) return;    
    if (actions.areSupplementsFilled(selectedEntry)) fill();
    actions.onSupplementsFilled(selectedEntry).listen((_) => fill());
    actions.onPdfAnnotChanged(selectedEntry).listen(onPdfAnnotChangedInDb);
    actions.onPdfAnnotDeleted(selectedEntry).listen(onPdfAnnotDeletedInDb);
    actions.onLibraryEntryChanged.listen(onLibraryEntryChangedInDb);
    actions.onLibraryEntryDeleted.listen(onLibraryEntryDeletedInDb);
  }
  
  /// Handles the change of an annot in db.
  void handlePdfAnnotChangedInDb(PdfAnnotation annot) {
    print("(icecite) annot db-update-change: ${annot.toJson()}");
    // Reveal the annotation.
    revealAnnotation(annot);
  }
  
  /// Handles the deletion of an annot in db.
  void handlePdfAnnotDeletedInDb(PdfAnnotation annot) {
    print("(icecite) annot db-delete-change: ${annot.toJson()}");
    // Unreveal the annotation.
    unrevealAnnotation(annot);
  }
  
  /// Handles the change of a library entry in db.
  void handleLibraryEntryChangedInDb(LibraryEntry entry) {
    // Handle the entry as deleted, if the user isn't the owner or a participant
    if (user.isOwnerOrParticipant(entry)) return; 
    handleLibraryEntryDeletedInDb(entry);
  }
  
  /// Handles the deletion of a library entry in db.
  void handleLibraryEntryDeletedInDb(LibraryEntry entry) {
    if (entry != selectedEntry) return;
    // Reset the view.
    reset();
  }

  /// Handles the addition of a pdf annotation.
  void handleAnnotAdded(Event event, PdfAnnotation annot) {
    retardEvent(event);
    enqueue(annot);
  }
  
  /// Handles the update of a pdf annotation.
  void handleAnnotUpdated(Event event, PdfAnnotation annot) {
    retardEvent(event);
    enqueue(annot);
  }
  
  /// Handles the deletion of a pdf annotation.
  void handleAnnotDeleted(Event event, PdfAnnotation annot) {
    retardEvent(event);
    enqueue(annot..["_deleted"] = true);
  }
  
  void handlePreviousViewRequest() { 
    pdfViewer.onPreviousViewRequest();
  }
    
  void handleNextViewRequest() {
    pdfViewer.onNextViewRequest();
  }
  
  // ___________________________________________________________________________
  
  /// Fills the display for the given entry.
  void fill() {
    dbQueues.clear();
    print("selected entry: $selectedEntry");
    actions.getPdf(selectedEntry).then((blob) {
      Iterable annots = actions.getPdfAnnots(selectedEntry).values;
      if (annots != null) {
        for (var annot in annots) {
          annotRevsCache[annot.id] = annot.rev;
        }
      }
      // Sort the references by their positions in bibliography.
      List refs = new List.from(actions.getReferences(selectedEntry).values);
      refs.sort((a, b) {
        return a.positionInBibliography.compareTo(b.positionInBibliography);
      });
      pdfViewer.display(selectedEntry, blob, annots: annots, references: refs);
    });
  }
          
  /// Ensures, that the given annotation is displayed.
  void revealAnnotation(PdfAnnotation annot) {
    if (annot == null) return;
    if (selectedEntry == null) return;
    // Check, if annotation belongs to the currently displayed entry.
    if (annot.entryId != selectedEntry.id) return;
    annotRevsCache[annot.id] = annot.rev;
    pdfViewer.addAnnotation(selectedEntry, annot);
  }
  
  // TODO: Implement updateAnnotation().
  
  /// Ensures, that the given annotation isn't displayed anymore.
  void unrevealAnnotation(PdfAnnotation annot) {
    if (annot == null) return;
    annotRevsCache.remove(annot.id);
    pdfViewer.deleteAnnotation(selectedEntry, annot);
    dbQueues[annot.id] = null;
  }
  
  /// Resets the db queues and the pdf container.
  void reset() {
    if (dbQueues != null) dbQueues.clear();
    if (annotRevsCache != null) annotRevsCache.clear();
    if (pdfViewer != null) pdfViewer.clear();
    selectedEntry = null;
  }
  
  // ___________________________________________________________________________
  // Db actions.  
      
  /// Enqueues the given annotation to ensure, that the proper rev is used.
  void enqueue(PdfAnnotation annot) {
    Queue<PdfAnnotation> queue = dbQueues[annot.id];
    if (queue != null) {
      if (queue.isEmpty) {
        queue.add(annot);
        processDbQueue(dbQueues[annot.id]);
      } else {
        queue.add(annot);
      }
    } else {
      dbQueues[annot.id] = new Queue.from([annot]);
      processDbQueue(dbQueues[annot.id]);
    }
  }
  
  /// Processes the queue.
  void processDbQueue(Queue<PdfAnnotation> queue) {
    PdfAnnotation annot = queue.first;
    if (annotRevsCache.containsKey(annot.id)) {
      annot.rev = annotRevsCache[annot.id];
    }
    actions.setPdfAnnot(selectedEntry, annot).then((cachedAnnot) {
      annotRevsCache[cachedAnnot.id] = cachedAnnot.rev;
      queue.removeFirst();
      if (queue.isNotEmpty) processDbQueue(queue);
    }).catchError((e) => errorHandler);
  }
}