//library object_element;
//
//import 'dart:js';
//import 'dart:html';
//import 'dart:convert';
//import 'package:polymer/polymer.dart';
//import 'icecite_element.dart';
//import '../models/models.dart';
//
//@CustomTag('object-element')
////// Our implementation of an object-element.
//class ObjectElement extends IceciteElement {   
//  /// The annotations cache (needed to decide, which annots were added, deleted, 
//  /// removed and to cache the rev of each annot).
//  Map<String, PdfAnnotation> annotsCache = {};
//  /// The pdf container.
//  HtmlElement pdfContainer;
//
//  // The name of "annot-deleted" event
//  static const String EVENT_ANNOT_ADDED = "annot-added";
//  // The name of "annot-updated" event
//  static const String EVENT_ANNOT_UPDATED = "annot-updated";
//  // The name of "annot-deleted" event
//  static const String EVENT_ANNOT_DELETED = "annot-deleted";
//  // The name of "import-from-pdf" event
//  static const String EVENT_IMPORT_FROM_PDF = "import-from-pdf";
//  
//  // ___________________________________________________________________________
//  
//  /// The constructor.
//  ObjectElement.created() : super.created();
//    
//  @override
//  void attached() {
//    super.attached();
//    this.pdfContainer = get("object");
//  }
//  
//  @override
//  void resetOnLogout() {
//    super.resetOnLogout();
//    if (this.annotsCache != null) this.annotsCache.clear();
//  }
//  
//  // ___________________________________________________________________________
//  // Handlers.
//    
//  /// This method is called, whenever a message from pdf was sent.
//  void onPdfMessage(message) => handlePdfMessage(message);
//        
//  /// This method is called, whenever an error in pdf occurs.
//  void onErrorMessage(error, message) => handleErrorMessage(message);
//  
//  /// This method is called, whenever an annot was added.
//  void onAnnotAdded(annot) => handleAnnotAdded(annot);
//  
//  /// This method is called, whenever an annot was updated.
//  void onAnnotUpdated(annot) => handleAnnotUpdated(annot);
//  
//  /// This method is called, whenever an annot was deleted.
//  void onAnnotDeleted(annot) => handleAnnotDeleted(annot);
//  
//  /// This method is called, whenever the intend to import an entry from pdf.
//  void onImportFromPdf(entry) => handleImportFromPdf(entry);
//  
//  /// This method is called, whenever the pdf was loaded.
//  void onPdfLoaded(base64, annots) => handlePdfLoaded(base64, annots);
//  
//  // ___________________________________________________________________________
//  // Actions.
//
//  /// Handles a message from pdf.
//  void handlePdfMessage(message) {
//    if (message.length > 0) {
//      switch (message[0]) {
//        case "annots":
//          handleAnnotsMessage(message);
//          break;
//        case "import":
//          handleImportMessage(message);
//          break;
//        case "error": 
//          handleErrorMessage(message);
//          break;
//      }
//    }
//  }
//  
//  /// Handles an annots message.
//  void handleAnnotsMessage(message) {
//    Map newAnnotsCache = {};
//    Iterable<PdfAnnotation> annots = dartifyAnnots(message);     
//    if (annots != null) {
//      // Decide, which annoations were added, updated and removed.
//      annots.forEach((annot) {
//        if (annot != null) {
//          PdfAnnotation cachedAnnot = annotsCache.remove(annot.id);
//          if (cachedAnnot == null) {
//            onAnnotAdded(annot);
//          } else {
//            annot.rev = cachedAnnot.rev;
//            if (cachedAnnot.modified != annot.modified) {
//              // The annotation is available in cache but modDate has changed.
//              onAnnotUpdated(annot);
//            }
//          }
//          newAnnotsCache[annot.id] = annot;
//        }
//      });
//  
//      // All annotation, which are in cache yet, were removed.
//      annotsCache.forEach((id, annot) {
//        if (annot != null) onAnnotDeleted(annot); 
//      });
//      annotsCache = newAnnotsCache;
//    }
//  }
//  
//  /// Handles an import message.
//  void handleImportMessage(message) {
//    if (message.length < 1) return;
//    onImportFromPdf(new LibraryEntry.fromMap(JSON.decode(message[1])));
//  }
//  
//  /// Handles an error message.
//  void handleErrorMessage(message) {
//    errorHandler(message, entry: selectedEntry);
//  }
//  
//  /// Handles the load of pdf file.
//  void handlePdfLoaded(String base64, Iterable annots) {
//    pdfContainer.children.clear();
//    pdfContainer.children.add(createPdfContainer(base64));
//    addMessageHandler("pdf");
//    addAnnotations(annots);
//  }
//  
//  /// Handles an added annot.
//  void handleAnnotAdded(PdfAnnotation annot) {
//    fireAnnotAddedEvent(annot);
//  }
//    
//  /// Handles an updated annot.
//  void handleAnnotUpdated(PdfAnnotation annot) {
//    fireAnnotUpdatedEvent(annot);
//  }
//  
//  /// Handles a deleted annot.
//  void handleAnnotDeleted(PdfAnnotation annot) {
//    fireAnnotDeletedEvent(annot);
//  }
//  
//  /// Handles an import from pdf.
//  void handleImportFromPdf(LibraryEntry entry) {
//    fireImportFromPdfEvent(entry);
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Displays the given blob of given entry.
//  void display(LibraryEntry entry, Blob blob, {Iterable annots}) {
//    this.selectedEntry = entry;
//    /// Read the pdf from database.
//    FileReader reader = new FileReader();
//    reader.readAsDataUrl(blob);
//    reader.onLoadEnd.listen((_) => onPdfLoaded(reader.result, annots));
//  }
//  
//  /// Imports the given list of annotations into pdf.
//  void addAnnotations(Iterable<PdfAnnotation> annots) {
//    if (annots == null) return;
//    
//    sendToPdf(jsify('0', annots));
//    fillAnnotsCache(annots);
//  }
//  
//  /// Adds the given annotation to list.
//  void addAnnotation(PdfAnnotation annot) {  
//    if (annot == null) return;
//    var cached = annotsCache[annot.id];
//    // Add the annot only, if the annot wasn't cached already or if the annot
//    // to add is newer to the cached one.
//    if (cached == null || cached.rev == null || cached.rev != annot.rev) {
//      sendToPdf(jsify('0', [annot]));
//      annotsCache[annot.id] = annot;
//    }
//  }
//    
//  /// Removes the given annot from pdf.
//  void removeAnnotation(PdfAnnotation annot) {
//    sendToPdf(jsify('1', [annot]));
//    annotsCache.remove(annot.id);
//  } 
//  
//  /// Clears the pdf container.
//  void clear() => pdfContainer.children.clear();
//          
//  // ___________________________________________________________________________
//  
//  /// Creates a new pdf container.
//  HtmlElement createPdfContainer(String src) {
////  var url = Url.createObjectUrl(blob);
////  var embedElement = new EmbedElement()
////    ..id   = "pdf"
////    ..src  = url
////    ..type = "application/pdf";
////    pdfContainer.children.clear();
////    pdfContainer.children.add(embedElement);
////    // Add a messageHandler to the object.
////    context.callMethod("addMessageHandler", ["pdf", onPdfMessage, onPdfEr]);
////    if (annots != null) importAnnotations(annots);
//    return new EmbedElement()
//        ..id = "pdf"
//        ..classes.add("pdf")
//        ..src  = src
//        ..type = "application/pdf";
//  }
//  
//  /// Fills the annotation cache with the given annotations.
//  void fillAnnotsCache(Iterable<PdfAnnotation> annots) {
//    annotsCache.clear();
//    if (annots != null) {
//      annots.forEach((annot) {
//        annotsCache[annot.id] = annot; 
//      });
//    }
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Transforms the given JsObject into a dart iterable.
//  Iterable dartifyAnnots(JsArray message) {
//    List<PdfAnnotation> annots = [];
//    if (selectedEntry != null && message != null) {
//      for (int i = 1; i < message.length; i++) { // Annots start at index 1.
//        String element = message[i];
//        PdfAnnotation annot = new PdfAnnotation();
//        List<String> properties = element.split("\t");
//        properties.forEach((property) {
//          int index = property.indexOf(":");
//          if (index > 0) {
//            String key = property.substring(0, index);
//            String value = property.substring(index + 1);
//            annot[key] = value;
//          }
//        });
//        annot.entryId = selectedEntry.id;
//        annots.add(annot);
//      }
//    }
//    return annots;
//  }
//    
//  /// Transforms the given dart iterable into a JsObject.
//  JsObject jsify(String action, Iterable<PdfAnnotation> annots) {
//    var strAnnots = [action];
//    if (annots != null) {
//      annots.forEach((annot) {
//        strAnnots.add(annot.toString());
//      });
//    }
//    return new JsObject.jsify(strAnnots);
//  }
//    
//  // ___________________________________________________________________________
//  
//  /// Adds a message handler to the element with given id.
//  void addMessageHandler(String id) {
//    context.callMethod("addMessageHandler", [id, onPdfMessage, onErrorMessage]);
//  }
//  
//  /// Sends the given jsObject to pdf container.
//  void sendToPdf(JsObject jsObject) {
//    context.callMethod("sendToPdf", [jsObject]);
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Fires an annot-added event
//  void fireAnnotAddedEvent(PdfAnnotation annot) {
//    fire(EVENT_ANNOT_ADDED, detail: annot);
//  }
//  
//  /// Fires an annot-updated event
//  void fireAnnotUpdatedEvent(PdfAnnotation annot) {
//    fire(EVENT_ANNOT_UPDATED, detail: annot);
//  }
//  
//  /// Fires a annot-deleted event
//  void fireAnnotDeletedEvent(PdfAnnotation annot) {
//    fire(EVENT_ANNOT_DELETED, detail: annot);
//  }
//  
//  /// Fires a import-from-pdf event
//  void fireImportFromPdfEvent(LibraryEntry entry) {
//    fire(EVENT_IMPORT_FROM_PDF, detail: entry);
//  }
//}
