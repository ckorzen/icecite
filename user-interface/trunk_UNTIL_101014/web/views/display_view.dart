@MirrorsUsed(targets: 'LibraryEntry')
library display_view;

import 'dart:mirrors';
import 'dart:collection';
import 'package:polymer/polymer.dart';
import '../elements/icecite_element.dart';
import '../elements/object_element.dart';
import '../models/models.dart';

/// The display view of Icecite, displaying the pdf of a library entry.
@CustomTag('display-view')
class DisplayView extends IceciteElement {  
  /// Internal variables.
  Map<String, Queue<PdfAnnotation>> dbQueues = {};
  ObjectElement pdfContainer;  
    
  /// The default constructor.
  DisplayView.created() : super.created();
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    reset();
  }
  
  void reset() {
    if (dbQueues != null) dbQueues.clear();
    if (pdfContainer != null) pdfContainer.clear();
    selectedEntry = null;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever this view was revealed.
  void revealedHandler() {
    this.pdfContainer = get("pdf-object");
  }
  
  /// This method is automatically called, whenever the selected entry was
  /// changed.
  void selectedEntryChanged(LibraryEntry prevSelectedEntry) {
    if (selectedEntry == null) return;
     
    print("selected entry changed: $selectedEntry");
    
    if (actions.areSupplementsFilled(selectedEntry)) fill();
    actions.onSupplementsFilled(selectedEntry).listen((_) => fill());
        
    actions.onPdfAnnotChanged(selectedEntry).listen(pdfAnnotChangedHandler);
    actions.onPdfAnnotDeleted(selectedEntry).listen(pdfAnnotDeletedHandler);
    actions.onLibraryEntryChanged.listen(libraryEntryChangedHandler);
    actions.onLibraryEntryDeleted.listen(libraryEntryDeletedHandler);
  }
    
  /// Define the behavior when an annot in storage was added or updated.
  void pdfAnnotChangedHandler(annot) => revealAnnotation(annot); 
    
  /// Define the behavior when an entry in storage was deleted.
  void pdfAnnotDeletedHandler(annot) => unrevealAnnotation(annot);
  
  /// Define the behavior when an entry in storage was added or updated.
  void libraryEntryChangedHandler(LibraryEntry entry) {
    if (entry == null) return;
    if ((entry.formerUserIds == null || !entry.formerUserIds.contains(user.id)) 
     && (entry.userIds == null || !entry.userIds.contains(user.id))) {
      libraryEntryDeletedHandler(entry);
    }
  }
            
  /// Define the behavior when an entry in storage was deleted.
  void libraryEntryDeletedHandler(entry) {
    if (entry == selectedEntry) reset();
  }
  
  // ___________________________________________________________________________
  // On-purpose methods.
    
  /// This method is called, whenever an entry was selected.
  void onSelectLibraryEntryPurpose(event, entry, target) { 
    selectedEntry = entry; // Will trigger the call of selectedEntryChanged.
  }
  
  /// This method is called, whenever an annotation was added in pdf locally.
  void onAddAnnotPurpose(event, annot, target) => _enqueue(annot);
  
  /// This method is called, whenever an annotation was updated in pdf locally.
  void onUpdateAnnotPurpose(event, annot, target) => _enqueue(annot); 

  /// This method is called, whenever an annotation was deleted in pdf locally.
  void onDeleteAnnotPurpose(event, annot, target) {
    if (annot != null) _enqueue(annot..["_deleted"] = true);
  }
    
  // ___________________________________________________________________________
  // Display methods.
    
  /// Fills the display for the given entry.
  void fill() {
    dbQueues.clear();
    actions.getPdf(selectedEntry).then((blob) {
      Iterable annots = actions.getPdfAnnotations(selectedEntry).values;
      pdfContainer.display(selectedEntry, blob, annots: annots);
    });
  }
          
  /// Ensures, that the given annotations are displayed.
  void revealAnnotations(List<PdfAnnotation> annots) {
    if (annots != null) pdfContainer.importAnnotations(annots); 
  }
  
  /// Ensures, that the given annotation is displayed.
  void revealAnnotation(PdfAnnotation annot) {
    // Check, if annotation belongs to the currently displayed entry.
    if (annot != null && selectedEntry != null 
     && annot.entryId == selectedEntry.id) {
      pdfContainer.addAnnotation(annot);
    }
  }
  
  /// Ensures, that the given annotation isn't displayed anymore.
  void unrevealAnnotation(PdfAnnotation annot) {
    if (annot != null) {
      pdfContainer.removeAnnotation(annot);
      dbQueues[annot.id] = null;
    }
  }
       
  // ___________________________________________________________________________
  // Db actions.  
      
  /// Enqueues the given annotation to ensure, that the proper rev is used.
  void _enqueue(PdfAnnotation annot) {
    Queue<PdfAnnotation> queue = dbQueues[annot.id];
    if (queue != null) {
      if (queue.isEmpty) {
        queue.add(annot);
        _processDbQueue(dbQueues[annot.id]);
      } else {
        queue.add(annot);
      }
    } else {
      dbQueues[annot.id] = new Queue.from([annot]);
      _processDbQueue(dbQueues[annot.id]);
    }
  }
  
  /// Processes the queue.
  void _processDbQueue(Queue<PdfAnnotation> queue) {
    PdfAnnotation annot = queue.first;
    actions.setPdfAnnotation(selectedEntry, annot).then((_) {
      queue.removeFirst();
      if (queue.isNotEmpty) _processDbQueue(queue);
    }).catchError((e) => errorHandler);
  }
}