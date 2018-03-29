import 'dart:async';
import 'dart:html';

Future httpRequest(String url, {var data: null, String method: 'GET', 
    int timeout: null}) {
  Completer completer = new Completer();
  
  HttpRequest req = new HttpRequest();
  req.open(method, url, async: true);
  if (timeout != null) req.timeout = timeout;
      
  req.onTimeout.listen(completer.completeError);
  req.onError.listen(completer.completeError);
  req.onLoad.listen((e) {
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
      