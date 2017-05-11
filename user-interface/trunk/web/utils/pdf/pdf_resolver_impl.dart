part of pdf_resolver;

class PdfResolverImpl implements PdfResolverInterface {  
  NotificationUtil notificationUtil = new NotificationUtil();
  
  /// Resolves the given entry to an according pdf.
  Future<Map> meta2Pdf(LibraryEntry entry, {bool globalNotifications: false}) {
    var completer = new Completer();    
    if (entry != null) {
      LibraryEntry notificationsEntry = globalNotifications ? null : entry;
      HttpRequest request = new HttpRequest();
      request.open('POST', URL_META2PDF, async: true);
      request.timeout = TIMEOUT_META2PDF;
      request.onLoad.listen((e) {
        // Note: file:// URIs have status of 0.
        if ((request.status >= 200 && request.status < 300) ||
            request.status == 0 || request.status == 304) {
          try {
            _processResponse(entry, request.responseText, completer,
                globalNotifications: globalNotifications);
          } catch (e) {
            completer.completeError(e);
          }
        } else {
          completer.completeError(e);
        }
      });
      request.onTimeout.listen((e) => completer.completeError("timeout"));
      request.onError.listen((e) => completer.completeError);
      
//      loading("Waiting for server response.", pouchable: notificationsEntry);
      request.send(entry.toJson());
    } else {
      completer.completeError("No entry is given");
    }
    return completer.future;
  }
  
  /// Resolves the given pdf to metadata.
  Future<Map> pdf2Meta(LibraryEntry entry, Blob blob, {bool globalNotifications: false}) {
    return toBase64(blob).then((base64) => 
        _base64ToMeta(entry, base64));
  }
    
  // ___________________________________________________________________________
  // Private methods.
  
  /// Resolves the given base64 to metadata.
  Future<Map> _base64ToMeta(LibraryEntry entry, String pdfBase64, 
     {bool globalNotifications: false}) {
    Completer completer = new Completer();
    if (pdfBase64 != null) {      
      HttpRequest request = new HttpRequest();
      request.open('POST', URL_PDF2META, async: true);
      request.timeout = TIMEOUT_PDF2META;
      request.onLoad.listen((e) {
        // Note: file:// URIs have status of 0.
        if ((request.status >= 200 && request.status < 300) ||
            request.status == 0 || request.status == 304) {
          try {
            _processResponse(entry, request.responseText, completer, 
                globalNotifications: globalNotifications);
          } catch (e) {
            completer.completeError(e);
          }
        } else {
          completer.completeError(e);
        }
      });
      request.onTimeout.listen((e) => completer.completeError("Timeout."));
      request.onError.listen((e) => completer.completeError);
      request.send(pdfBase64);
    } else {
      completer.complete(entry);
    }
    return completer.future;
  }
  
  /// Processes the response.
  void _processResponse(LibraryEntry entry, String res, Completer completer, 
                        {bool globalNotifications: false}) {
    LibraryEntry notificationsEntry = globalNotifications ? null : entry;
    
//    loading("Decode JSON.", pouchable: notificationsEntry);
    Map map = JSON.decode(res);
    if (map == null || map.isEmpty) {
      completer.completeError("no match");
      return;
    }
    
    // Remove the pdf field to don't affect apply (see below).
//    loading("Preparing blob.", pouchable: notificationsEntry);
    Blob blob = toBlob(map.remove('pdf'));
    // Transform the references to library entries.
//    loading("Preparing references.", pouchable: notificationsEntry);
    List refs = map.remove('references');
    if (refs != null) {
      for (int i = 0; i < refs.length; i++) {
        LibraryEntry reference = new LibraryEntry.fromMap(refs[i]);
        reference.brand = "reference";
        reference.citingEntryId = entry.id;
        reference.positionInBibliography = i + 1;
        refs[i] = reference;
      }
    }    
    // Apply the changes to entry.
//    loading("Preparing references.", pouchable: notificationsEntry);
    entry.apply(map, overwrite: true);
    
    if (entry.externalKey != null) {
      completer.complete({'entry': entry, 'refs': refs, 'blob': blob}); 
    } else {
      completer.completeError("Couldn't find content to download."); 
    }
  }
  
//  /// Shows loading notification. If entry is null, the notification is global.
//  void loading(String msg, {Pouchable pouchable, Function onClick}) {
//    notificationUtil.loading(msg, pouchable: pouchable, onClick: onClick);
//  }
}