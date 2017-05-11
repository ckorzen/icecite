@MirrorsUsed(targets: 'LibraryEntry')
library display_view;

import 'dart:html' hide Entry;
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
  // TODO: Is this cache still needed? 
  Map<String, String> annotRevsCache = {};
  /// Cache, mapping an annotId to the queue of its modifications.
  Map<String, Queue<PdfAnnotation>> dbQueues = {};
  
  /// The pdf viewer.
  PdfViewerElement pdfViewer;
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  DisplayView.created() : super.created();
     
  @override
  void reset() {
    super.reset();
    this.annotRevsCache.clear();
    this.dbQueues.clear();
    this.pdfViewer.clear();
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever this view was revealed.
  void onRevealed() => handleRevealed();
     
  /// This method is called, whenever an annotation was added in pdf locally.
  void onAnnotAdded(event, annot) => handlePdfAnnotAdded(event, annot);
  
  /// This method is called, whenever an annotation was updated in pdf locally.
  void onAnnotUpdated(event, annot) => handlePdfAnnotUpdated(event, annot);
  
  /// This method is called, whenever an annotation was deleted in pdf locally.
  void onAnnotDeleted(event, annot) => handlePdfAnnotDeleted(event, annot);
          
  // ___________________________________________________________________________
  // Actions.
  
  /// Reveals the elements of this view.
  void handleRevealed() {
    this.pdfViewer = get("pdf-viewer-element");
  }
      
  /// Handles the change of an annot in db.
  void handlePdfAnnotUpdatedInDb(PdfAnnotation annot) {
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
  
  /// Handles the addition of a pdf annotation.
  void handlePdfAnnotAdded(Event event, PdfAnnotation annot) {
    retardEvent(event);
    enqueue(annot);
  }
  
  /// Handles the update of a pdf annotation.
  void handlePdfAnnotUpdated(Event event, PdfAnnotation annot) {
    retardEvent(event);
    enqueue(annot);
  }
  
  /// Handles the deletion of a pdf annotation.
  void handlePdfAnnotDeleted(Event event, PdfAnnotation annot) {
    retardEvent(event);
    enqueue(annot..["_deleted"] = true);
  }
    
  // ___________________________________________________________________________
       
  /// Handles the change of selected entry.
  void selectEntry(Entry entry) {
    clearNotification();
    
    if (entry == null) return;
    if (!entry.isLibraryEntry) return;
    this.selectedEntry = entry;
        
    // TODO: Remove listener on unselect.
    this.selectedEntry.onAnnotUpdated.listen(handlePdfAnnotUpdatedInDb);
    this.selectedEntry.onAnnotDeleted.listen(handlePdfAnnotDeletedInDb);
    
    dbQueues.clear();
    if (this.selectedEntry.attachments == null) {
      error("There is no pdf available for this entry!");
      pdfViewer.hideIFrames();
    } else {
      this.selectedEntry.getPdf().then((blob) {
        this.selectedEntry.getPdfAnnotations().then((annots) {
          if (annots != null) {
            for (var annot in annots) {
              annotRevsCache[annot.id] = annot.rev;
            }
          }
                
          // Sort the references by their positions in bibliography.
          this.selectedEntry.getReferences().then((references) {
            references.sort((a, b) {
              return a.positionInBibliography.compareTo(b.positionInBibliography);
            });
            pdfViewer.display(selectedEntry, blob, annots: annots, references: references);
          });
        });
      }); 
    }
  }
  
  // Deletes the data for given entry.
  void deleteEntry(Entry entry) {
    if (entry == null) return;
    if (selectedEntry == null) return;
    
    if (entry.id == selectedEntry.id) {
      pdfViewer.removeIFrame(entry);
    }
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
    
  /// Ensures, that the given annotation isn't displayed anymore.
  void unrevealAnnotation(PdfAnnotation annot) {
    if (annot == null) return;
    annotRevsCache.remove(annot.id);
    pdfViewer.deleteAnnotation(selectedEntry, annot);
    dbQueues[annot.id] = null;
  }
    
  /// Jumps to the previous pdf view.
  void jumpToPreviousPdfView() { 
    pdfViewer.jumpToPreviousPdfView();
  }
  
  /// Jumps to the next pdf view.
  void jumpToNextPdfView() {
    pdfViewer.jumpToNextPdfView();
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
    this.selectedEntry.setPdfAnnotation(annot).then((cachedAnnot) {
      annotRevsCache[cachedAnnot.id] = cachedAnnot.rev;
      queue.removeFirst();
      if (queue.isNotEmpty) processDbQueue(queue);
    }).catchError((e) => errorHandler);
  }
}