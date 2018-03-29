library pdf_enricher;

import 'dart:html';
import 'dart:async';
import '../html/blob_util.dart';

// TODO: Check, if the injection process can be done without encoding into / 
// decoding from base64.
class PdfEnricher {
  /// The regular expression to find the Catalog entry in pdf.
  RegExp objRegExp = new RegExp("(/Catalog)");
  RegExp injectJsRegExp = new RegExp("(<<|>>)");
  
  /// Injects a javascript-snippet into pdf to be able to communicate with it.
  Future<Blob> enrich(Blob blob) {
    if (blob == null) return new Future.value();
    Completer<Blob> completer = new Completer<Blob>();
    toBase64(blob)
      .then((content) => completer.complete(toBlob(inject(content))))
      .catchError((e) => completer.completeError(e));
    return completer.future;
  }
  
  /// Injects the javascript snippet into the pdf.
  String inject(String base64) { 
    String content = window.atob(base64);
    
    // Search for the Catalog entry in pdf.
    Match match = objRegExp.firstMatch(content);
    if (match != null) {
      int indexCatalog = match.start;
      int indexInjection = -1;
      if (content != null && indexCatalog >= 0) {
        int dictCounter = 0;
        // Search the pdf only from catalog (and not from beginning)
        String searchBlock = content.substring(indexCatalog);
        Iterable<Match> matches = injectJsRegExp.allMatches(searchBlock);
        for (var match in matches) {
          String trigger = match.group(0);
          // We search the closing ">>" of catalog. Since catalog can contain
          // nested dictionaries, we count the number of opening "<<" in catalog
          // to decide, if an ">>" belongs to the actual catalog.
          if (trigger == "<<") {
            dictCounter++;
          } else if (trigger == ">>") {
            if (dictCounter == 0) {
              // We have found the closing ">>" of catalog. We have to add the
              // offset btw. start of document and start of catalog to current
              // position (since we have searched the pdf only from catalog).
              indexInjection = match.start + indexCatalog;
              break;
            } else {
              dictCounter--;
            }
          }
        }
        if (indexInjection >= 0) {
          var result = content.substring(0, indexInjection) + jsDict 
              + content.substring(indexInjection);  
          return window.btoa(result);
        }
      }
    }
    return base64;
  }
  
  /// The javascript-wrapper in pdf.
  static final String jsDict = "/OpenAction << /Type /Action /S /JavaScript /JS ($js) >>";
  
  /// The javascript snippet to inject.
  static final String js = 
    "if (app.viewerType == 'Reader') {"
    "  app.alert"
    "  ({"
    "    cMsg: 'Please note: in order to import and export annotations, use Acrobat Standard or Acrobat Professional.'," 
    "    cTitle: 'Adobe Reader is not supported by Synchro',"  
    "    nIcon: 1" 
    "  });"
    "} else {"
    "  Collab.showAnnotToolsWhenNoCollab = true;"
    "  this.disclosed = true;"
    "  var curDoc = this;"
    "  if (this.external && this.hostContainer) {"
   /* Serializes the given annotation to string */       
    "  function stringify(annot) {"
    "    return '"
            "_id:' + annot.name +'\t"
            "type:' + annot.type +'\t"
            "page:' + annot.page +'\t"
            "creationDate:' + annot.creationDate +'\t"
            "modDate:' + annot.modDate +'\t"
            "author:' + annot.author +'\t"
            "subject:' + annot.subject +'\t"
            "contents:' + annot.contents.replace(/\t/g, ' ') +'\t"
            "strokeColor:' + annot.strokeColor +'\t"
            "opacity:' + annot.opacity +'\t"
            "inReplyTo:' + annot.inReplyTo +'\t"
            "refType:' + annot.refType +'\t"
            "rect:' + annot.rect +'\t"
            "popupRect:' + annot.popupRect +'\t"
            "popupOpen:' + annot.popupOpen +'\t"
            "point:' + (annot.point ? annot.point : '') +'\t"
            "quads:' + (annot.quads ? annot.quads : '') +'\t"
            "noteIcon:' + (annot.noteIcon ? annot.noteIcon : '');"
  "    } "
  
  /* Extracts the annotations of pdf. */
  "    function extractAnnots() {"
  "      var result = new Array();"
  "      result[0] = 'annots';" 
  "      curDoc.syncAnnotScan();"
  "      var annots = curDoc.getAnnots({ nSortBy: ANSB_ModDate, bReverse: true });"
  "      if (annots) {"   
  "        for (var i = 0; i < annots.length; i++) {"
  "          var annot = annots[i];"
  "          result[i+1] = stringify(annot);"
  "        }"
  "      }"
  "      return result;" 
  "    }"
  
  "    var prevAnnots = extractAnnots();"
  
  /* Deletes the given annots in pdf */
  "    function deleteAnnots(annots) {"
  "      if (annots !== null) {"
  "        for (var i = 1; i < annots.length; i++) {"
  "          if (annots[i] !== null) { "
  "            var annotElements = annots[i].split('\t');"
  "            var annot = curDoc.getAnnot(annotElements[2], annotElements[0]);"
  "            if (annot !== null) {"
  "              annot.destroy();"
  "            }"
  "          }"
  "        }"
  "      }"
  "    }"
  
  /* Imports given annots into pdf */
  "    function importAnnots(annots) {"    
  "      if (annots !== null) {"
  "        for (var i = 1; i < annots.length; i++) {"
  "          if (annots[i]) {"
  "            var annotElements = annots[i].split('\t');"
  "            if (annotElements.length >= 14) {"
  /*             First, delete the annotation, if it is already present */
  "              var annot = curDoc.getAnnot(annotElements[2], annotElements[0]);"
  "              if (annot !== null) {"
  "                annot.destroy();"
  "              }"
  "              var colorElements = annotElements[8].split(',');"
  "              var colorArray = new Array();"
  "              colorArray[0] = colorElements[0];"
  "              for (var j = 1; j < colorElements.length; j++) {"
  "                colorArray[j] = parseFloat(colorElements[j]);"
  "              }"
  "              if (annotElements[1] == 'Text') {"
  "                curDoc.addAnnot({"
  "                  name: annotElements[0],"
  "                  type: annotElements[1],"
  "                  page: annotElements[2],"
  "                  creationDate: new Date(annotElements[3]),"
  "                  modDate: new Date(annotElements[4]),"
  "                  author: annotElements[5],"
  "                  subject: annotElements[6],"
  "                  contents: annotElements[7],"
  "                  strokeColor: colorArray,"
  "                  opacity: parseFloat(annotElements[9]),"
  "                  inReplyTo: annotElements[10]," 
  "                  refType: annotElements[11]," 
  "                  rect: toFloatArray(annotElements[12])," 
  "                  popupRect: toFloatArray(annotElements[13])," 
  "                  popupOpen: annotElements[14],"
  "                  point: toFloatArray(annotElements[15]),"
  "                  noteIcon: annotElements[16]" 
  "                });"
  "              } else {"
  "                var quadElements = annotElements[15].split(',');"
  "                var quadArray = new Array();"
  "                for (var j = 0; j < quadElements.length / 8; j++) {"
  "                  var quadrilateral = new Array();"
  "                  for (var k = 0; k < 8; k++) {"
  "                    quadrilateral[k] = parseFloat(quadElements[(j*8)+k]);"
  "                  }" 
  "                  quadArray[j] = quadrilateral;"
  "                }" 
  "                curDoc.addAnnot({"
  "                  name: annotElements[0],"
  "                  type: annotElements[1],"
  "                  page: annotElements[2],"
  "                  creationDate: new Date(annotElements[3]),"
  "                  modDate: new Date(annotElements[4]),"
  "                  author: annotElements[5],"
  "                  subject: annotElements[6],"
  "                  contents: annotElements[7],"
  "                  strokeColor: colorArray,"
  "                  opacity: parseFloat(annotElements[9]),"
  "                  inReplyTo: annotElements[10]," 
  "                  refType: annotElements[11]," 
  "                  rect: toFloatArray(annotElements[12])," 
  "                  popupRect: toFloatArray(annotElements[13])," 
  "                  popupOpen: annotElements[14],"
  "                  quads: quadArray,"  
  "                });"
  "              }" 
  "            }" 
  "          }" 
  "        }" 
  "      }"
  "    }"
  
  /* Transforms the given string into a float-array */
  "    function toFloatArray( string ) {"
  "      var elements = string.split(',');"
  "      var array = new Array();"
  "      for (var i = 0; i < elements.length; i++) {"
  "        array[i] = parseFloat(elements[i]);"
  "      }"
  "      return array;"
  "    }"
  
  /* Defines behavior on errors */
  "    function onErrorFunc( e ) {" 
  "      console.show();"
  "      console.println(e.toString());"
  "      if (curDoc.hostContainer.messageHandler) { "
  "        curDoc.hostContainer.postMessage(['error', e.toString]);"
  "      }"
  "    }"
  
  /* Compares two arrays and returns true if arrays are different.*/
  "    function arraysUnequals(arr1, arr2) {"
  "      if (arr1 == null && arr2 !== null)"
  "        return true;"
  "      if (arr1 !== null && arr2 == null)"
  "        return true;"
  "      if (arr1 == null && arr2 == null)"
  "        return false;"
  "      if (arr1.length !== arr2.length)"
  "        return true;"
  "      for (var i = arr1.length; i--;) {"
  "        if (arr1[i] !== arr2[i])"
  "          return true;"
  "      }"
  "      return false;"
  "    }"
  
  /* Checks, whether the annotations were changed since the last check */
  "    function checkForAnnotsChanges() {"
  "      var annots = extractAnnots();"
  "      if (arraysUnequals(prevAnnots, annots)) {"
  "        prevAnnots = annots;"
  "        curDoc.hostContainer.postMessage(annots);"
  "      }"
  "    }"
  
  /* Defines the behavior on message received */
  "    function onMessageFunc( stringArray, origin ) {"
  "      var action = stringArray[0];"    
  "      if (action == '0') {"  
  "        importAnnots(stringArray);"
  "      } else if (action == '1') {"
  "        deleteAnnots(stringArray);"
  "      }"
  "    }"
  
  /* Defines the timer for checking the annotations */
  "    timeout = app.setInterval('checkForAnnotsChanges();', 1000);"
  
  /* Setups the message-handler */
  "    try {"
  "      if (!this.hostContainer.messageHandler);"
  "        this.hostContainer.messageHandler = new Object();"
  "        this.hostContainer.messageHandler.myDoc = this;"
  "        this.hostContainer.messageHandler.onMessage = onMessageFunc; "
  "        this.hostContainer.messageHandler.onError = onErrorFunc; "
  "        this.hostContainer.messageHandler.onDisclose = function() {"
  "          return true;" 
  "        };"
  /* Inform the hostContainer, that pdf was loaded */
//  "        this.hostContainer.postMessage(['loaded']);"
  "    } catch(e) {"
  "      onErrorFunc(e);" 
  "    }"
  "  }"
  "}";
}