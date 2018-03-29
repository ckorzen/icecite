library blob_util.dart;

import 'dart:html';
import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Converts the given blob to base64 string.
Future<String> toBase64(Blob blob) {
  Completer<String> completer = new Completer<String>();  
  if (blob != null) {
    FileReader reader = new FileReader();
    reader.onError.listen((e) => completer.completeError(e));
    reader.onLoadEnd.listen((_) {
      String content = reader.result;
      String base64 = content.split(",")[1];
      completer.complete(base64); 
    });
    reader.readAsDataUrl(blob);
  } else {
    completer.complete(blob);
  }
  return completer.future;
}

/// Converts the given base64 encoded string to blob.
/// TODO: Merge with dblp_matcher.toBlob().
Blob toBlob(String base64) {
  if (base64 != null) {
    List<int> intList = CryptoUtils.base64StringToBytes(base64);
    Uint8List uInt8List = new Uint8List.fromList(intList); 
    return new Blob([uInt8List], "application/pdf");
  }
  return null;
}