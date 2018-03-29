library object_element;

import 'dart:js';
import 'dart:html';
import 'dart:convert';
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';
import '../models/models.dart';

@CustomTag('object-element')
/// Our implementation of an object-element.
class ObjectElement extends IceciteElement {   
  /// Internal variables.
  Map<String, PdfAnnotation> annotsCache = {};
  HtmlElement pdfContainer;
  LibraryEntry entry;
    
  /// The constructor.
  ObjectElement.created() : super.created();
  
  /// This method is called, whenever the view was entered.
  void enteredView() {
    super.enteredView();    
    this.pdfContainer = get("object");
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.annotsCache != null) this.annotsCache.clear();
    this.entry = null;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever a message from pdf was sent.
  void pdfMessageHandler(message) {
    if (message.length > 0) {
      switch (message[0]) {
        case "annots":
          annotsMessageHandler(message);
          break;
        case "import":
          importMessageHandler(message);
          break;
        case "error": 
          errorMessageHandler(null, message);
          break;
      }
    }
  }
  
  /// This method is called, whenever the annotations in pdf have changed.
  void annotsMessageHandler(message) {
    Map newAnnotsCache = {};
    Iterable<PdfAnnotation> annots = _dartifyAnnots(message);     
    if (annots != null) {
      // Decide, which annoations were added, updated and removed.
      annots.forEach((annot) {
        if (annot != null) {
          PdfAnnotation cachedAnnot = annotsCache.remove(annot.id);
          if (cachedAnnot == null) {
            // The annotation isn't available in cache.
            fire('annot-added', detail: annot);
          } else {
            annot.rev = cachedAnnot.rev;
            if (cachedAnnot.modified != annot.modified) {
              // The annotation is available in cache but modDate has changed.
              fire('annot-updated', detail: annot);
            }
          }
          newAnnotsCache[annot.id] = annot;
        }
      });
  
      // All annotation, which are in cache yet, were removed.
      annotsCache.forEach((id, annot) {
        if (annot != null) fire('annot-deleted', detail: annot); 
      });
      annotsCache = newAnnotsCache;
    }
  }
    
  /// This method is called, whenever an import request occurs.
  void importMessageHandler(message) {
    if (message.length > 1) {
      LibraryEntry entry = new LibraryEntry.fromMap(JSON.decode(message[1]));
      fire("import-from-pdf", detail: entry);
    }
  }
      
  /// This method is called, whenever an error in pdf occurs.
  void errorMessageHandler(error, msg) => errorHandler(msg, entry: entry);
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Displays the given blob of given entry.
  void display(LibraryEntry entry, Blob blob, {Iterable annots}) {
    this.entry = entry;
      
//    var url = Url.createObjectUrl(blob);
//    var embedElement = new EmbedElement()
//      ..id   = "pdf"
//      ..src  = url
//      ..type = "application/pdf";
//      pdfContainer.children.clear();
//      pdfContainer.children.add(embedElement);
//      // Add a messageHandler to the object.
//      context.callMethod("addMessageHandler", ["pdf", onPdfMessage, onPdfEr]);
//      if (annots != null) importAnnotations(annots);
        
    FileReader reader = new FileReader();
    reader.onLoadEnd.listen((content) {
      var embedElement = new EmbedElement()
        ..id = "pdf"
        ..classes.add("pdf")
        ..src  = reader.result
        ..type = "application/pdf";
      pdfContainer.children.clear();
      pdfContainer.children.add(embedElement);
      // Add a messageHandler to the object.
      context.callMethod("addMessageHandler", 
          ["pdf", pdfMessageHandler, errorMessageHandler]);
      if (annots != null) importAnnotations(annots);
    });
    reader.readAsDataUrl(blob);
  }
  
  /// Imports the given list of annotations into pdf.
  void importAnnotations(Iterable<PdfAnnotation> annots) {    
    context.callMethod("sendToPdf", [_jsify('0', annots)]);
    _fillAnnotsCache(annots);
  }
  
  /// Adds the given annotation to list.
  void addAnnotation(PdfAnnotation annot) {  
    var cached = annotsCache[annot.id];
    if (cached == null || cached.rev == null || cached.rev != annot.rev) {
      context.callMethod("sendToPdf", [_jsify('0', [annot])]);
      annotsCache[annot.id] = annot;
    }
  }
  
  /// Removes the given annot from pdf.
  void removeAnnotation(PdfAnnotation annot) {
    context.callMethod("sendToPdf", [_jsify('1', [annot])]);
    annotsCache.remove(annot.id);
  }
        
  // ___________________________________________________________________________
  // Helper methods.
  
  /// Transforms the given JsObject into a list.
  Iterable _dartifyAnnots(JsArray message) {
    List<PdfAnnotation> annots = [];
    if (entry != null && message != null) {
      for (int i = 1; i < message.length; i++) { // Annots start at index 1.
        String element = message[i];
        PdfAnnotation annot = new PdfAnnotation();
        List<String> properties = element.split("\t");
        properties.forEach((property) {
          int index = property.indexOf(":");
          if (index > 0) {
            String key = property.substring(0, index);
            String value = property.substring(index + 1);
            annot[key] = value;
          }
        });
        annot.entryId = entry.id;
        annots.add(annot);
      }
    }
    return annots;
  }
    
  /// Transforms the given list into a JsObject.
  JsObject _jsify(String action, Iterable<PdfAnnotation> annots) {
    var strAnnots = [action];
    if (annots != null) {
      annots.forEach((annot) {
        strAnnots.add(annot.toString());
      });
    }
    return new JsObject.jsify(strAnnots);
  }
  
  /// Fills the annotation cache with the given annotations.
  void _fillAnnotsCache(Iterable<PdfAnnotation> annots) {
    annotsCache.clear();
    if (annots != null) {
      annots.forEach((annot) {
        annotsCache[annot.id] = annot; 
      });
    }
  }
  
  // ___________________________________________________________________________
    
  /// Clears the pdf container.
  void clear() => pdfContainer.children.clear();
}
