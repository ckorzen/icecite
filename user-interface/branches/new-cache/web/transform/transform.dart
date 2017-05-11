import 'dart:async';
import 'dart:convert';
import 'dart:html' hide Entry;
import 'dart:js';
import '../properties.dart';
import '../utils/html/blob_util.dart';
import '../utils/html/js_util.dart';
import '../utils/http/http_util.dart';
import '../utils/async/async_queue.dart';
import '../models/models.dart';

AsyncQueue<StripTask> stripTasks = new AsyncQueue();

/// Strips the given entry and the given blob. If pdf is given, the pdf will
/// be sent to the server, where the references and metadata are extracted.
/// If pdf is not given, the entry is sent to the server, where a pdf is
/// automatically retrieved and the references are extracted.
/// Be aware, that this task is enqueued. 
StripTask strip({LibraryEntry entry: null, Blob pdf: null}) {  
  if (entry == null) return null;
  
  StripTask stripTask = new StripTask(entry: entry, pdf: pdf);
  stripTasks.queue(stripTask);
  
  return stripTask;
}

// =============================================================================

class StripTask extends AsyncQueueElement {
  AsyncQueueElementState _state;
  LibraryEntry entry;
  Blob pdf;
  
  HttpRequest req;
    
  StripTask({LibraryEntry this.entry, Blob this.pdf}) {
    if (entry == null) return;
    setState(AsyncQueueElementState.IDLE); 
  }
  
  /// The action to perform for each stripTask in the queue.
  Future process() {      
    /// Dispatch the entry to server to get the metadata, pdf and references.
    return _strip().then((StripResult res) {          
      if (res.metadata != null) entry.enqueue(res.metadata);
      if (res.pdf != null) entry.setPdf(res.pdf);
      if (res.references != null) entry.setReferences(res.references);
      if (res.annotations != null) entry.setPdfAnnotations(res.annotations);
    });
  }
  
  /// Strips either the pdf or the entry.
  Future<StripResult> _strip() {
    if (pdf != null) {
      return _stripPdf();
    } else {
      return _stripEntry();
    }
  }
     
  /// Strips the pdf.
  Future<StripResult> _stripPdf() {
    Completer<StripResult> completer = new Completer();
    
    setState(AsyncQueueElementState.PROCESSING); 
    
    toBase64(pdf).then((base64) {        
      Future.wait([
        _extractAnnotations(base64),
        _dispatchWithBase64(base64)
      ]).then((res) {
        StripResult stripResult = res[1]..annotations = res[0];
        completer.complete(stripResult);  
        setState(AsyncQueueElementState.COMPLETED); 
      }).catchError((e) {
        setState(AsyncQueueElementState.ERROR, msg: e); 
        completer.completeError(e);
      });
    }).catchError((e) {
      setState(AsyncQueueElementState.ERROR, msg: e); 
      completer.completeError(e);
    });
    
    return completer.future;
  }
  
  /// Strips the entry.
  Future<StripResult> _stripEntry() {
    Completer<StripResult> completer = new Completer();
    
    setState(AsyncQueueElementState.PROCESSING); 
    
    _dispatchWithEntry().then((res) {
      setState(AsyncQueueElementState.COMPLETED); 
      completer.complete(res);
    }).catchError((e) {
      setState(AsyncQueueElementState.ERROR, msg: e); 
      completer.completeError(e);
    });
   
    return completer.future;
  }
   
  // ___________________________________________________________________________
  // Dispatch methods.
  
  Future<StripResult> _dispatchWithBase64(String base64) {
    return _httpRequest(URL_PDF2META, method: 'POST', 
      data: base64, timeout: TIMEOUT_PDF2META)
      .then((res) => _handleDispatchResult(res)); 
  }
    
  Future<StripResult> _dispatchWithEntry() {
    return _httpRequest(URL_META2PDF, method: 'POST', 
      data: entry.toJson(), timeout: TIMEOUT_META2PDF)
      .then((res) => _handleDispatchResult(res)); 
  } 
  
  void abort() {
    if (req != null) {
      req.abort();
    }
    setState(AsyncQueueElementState.ABORTED);
  }
  
  // ___________________________________________________________________________
  
  /// Extracts the annotations from pdf (given by blob).
  Future<List<PdfAnnotation>> _extractAnnotations(String base64) {    
    Completer completer = new Completer();
        
    // Define the callback.
    handleAnnotations(JsObject error, [JsObject result]) {
      if (result == null) {
        completer.completeError("No result"); 
      } else {
        List annots = [];
        List annotsData = dartify(result);
        for (Map annotData in annotsData) {
          annots.add(new PdfAnnotation.fromData(annotData));
        }
        completer.complete(annots);
      }
    }
    context.callMethod("extractNativeAnnotations", [base64, handleAnnotations]);   
    return completer.future;
  }
    
  Future _httpRequest(String url, {var data: null, String method: 'GET', 
      int timeout: null}) {
    Completer completer = new Completer();
    
    print("init req $hashCode");
    req = new HttpRequest();
    req.open(method, url, async: true);
    if (timeout != null) req.timeout = timeout;
     
    req.onAbort.listen((e) {
      completer.completeError("Aborted.");
    });
    req.onTimeout.listen((e) {
      completer.completeError("Timeout.");
    });
    req.onError.listen((e) {
      completer.completeError(e);
    });
        
    req.onLoad.listen((e) {
      print("req.onload $hashCode");
      // Note: file:// URIs have status of 0.
      if ((req.status >= 200 && req.status < 300) ||
           req.status == 0 || req.status == 304) {
        completer.complete({'status': req.status, 'response': req.responseText});
      } else {
        completer.completeError(e);
      }
    });
    req.send(data);
    
    return completer.future;
  }
  
  /// Handles a dispatch result.
  StripResult _handleDispatchResult(Map httpResult) {
    if (httpResult == null) return null;
    
    Map data = JSON.decode(httpResult['response']);
    if (data == null || data.isEmpty) return null;
  
    Blob pdf = toBlob(data.remove('pdf'));
    List references = toReferences(entry, data.remove('references'));
         
    return new StripResult(metadata: data, references: references, pdf: pdf);
  }
  
  // TODO: Outsource.
  List<ReferenceEntry> toReferences(LibraryEntry entry, List referencesData) {
    if (entry == null) return null;
    if (referencesData == null) return null;
    
    List<ReferenceEntry> references = [];
    for (var i = 0; i < referencesData.length; i++) {
      Map referenceData = referencesData[i];
      referenceData['positionInBibliography'] = i + 1;
      referenceData['parentId'] = entry.id;
      references.add(new ReferenceEntry.fromData(referenceData));
    }
    return references;
  }
  
  @override
  void setState(AsyncQueueElementState state, {String msg}) {
    this._state = state;
    
    switch (state) {
      case AsyncQueueElementState.IDLE:
        entry.loading("Idle", onAbort: (e) => abort());
        break;
      case AsyncQueueElementState.PROCESSING:
        entry.loading("Retrieving data", onAbort: (e) => abort());
        break;
      case AsyncQueueElementState.ABORTED:
        entry.info("Retrieving data aborted.");
        break;
      case AsyncQueueElementState.COMPLETED:
        entry.success("Data successfully retrieved.");
        break;
      case AsyncQueueElementState.ERROR:
        if (msg == null) {
          entry.error("Error.");
        } else {
          entry.error(msg);
        }
        break;        
      default:
        break;
    }
  }
  
  @override
  AsyncQueueElementState getState() {
    return _state;
  }
}

// _____________________________________________________________________________

class StripResult {
  Map metadata;
  Blob pdf;
  List<PdfAnnotation> annotations;
  List<ReferenceEntry> references;
  
  StripResult({this.metadata, this.pdf, this.annotations, this.references});
}