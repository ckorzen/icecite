@MirrorsUsed(targets: 'JsObject')
library pouch;

import 'dart:js';
import 'dart:html';
import "dart:async";
import "dart:mirrors";
import 'dart:convert';
import 'package:polymer/polymer.dart';
import '../../models/models.dart';

typedef dynamic DbUpdateHandler(Pouchable pouchable);
typedef dynamic DbDeleteHandler(String id);

/// A wrapper class for the js-library PouchDb.
abstract class PouchDb {
  String name;
  JsObject db;
     
  /// The constructor.
  PouchDb(this.name) {
    this.db = new JsObject(context['PouchDB'], [this.name]);
  }
      
  /// Puts a document into db.
  Future<Pouchable> put(Pouchable pouchable, [options]) {        
    // Create jsObjects.
    JsObject pouchableJs = new JsObject.jsify(pouchable.toMap());
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
        
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        // Fetch the revision number and add it to pouchable.
        pouchable.rev = response['rev'];
        completer.complete(pouchable);
      }
    }
            
    // Work hard.
    db.callMethod('put', [pouchableJs, optionsJs, callback]);
    
    return completer.future;
  }
  
  /// Create a new document and let PouchDB generate an _id for it.
  Future<Pouchable> post(Pouchable pouchable, [options]) {        
    // Create jsObjects.
    JsObject pouchableJs = new JsObject.jsify(pouchable.toMap());
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
           
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        Map map = _dartify(response);
        // Fetch the generated id and the revision number.
        pouchable.id = map['id'];
        pouchable.rev = map['rev'];
        completer.complete(pouchable);
      }
    }
            
    // Work hard.
    this.db.callMethod('post', [pouchableJs, optionsJs, callback]);
    
    return completer.future;
  }
    
  /// Retrieves a document, specified by docid.
  Future<Pouchable> get(String docId, [options]) {           
    // Create jsObjects.
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
    
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        completer.complete(toPouchable(_dartify(response)));
      }
    }
        
    // Work hard.
    this.db.callMethod('get', [docId, optionsJs, callback]);
    
    return completer.future;
  }
  
  /// Retrieves a document, specified by docid.
  Future<List<Pouchable>> getConflictedRevs(String docId, [options]) {           
    if (options == null) options = {};
    // Fetch all open revs.
    options['open_revs'] = 'all';
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
        
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        List<Pouchable> pouchables = [];
        // Result: [{ok: {...}}, {ok: {...}}]  
        _dartify(response).forEach((pouchable) {
          // open revs will also return deleted documents. Filter them out.
          var entry = pouchable['ok'];
          if (entry['_deleted'] == null) {
            pouchables.add(toPouchable(entry));
          }
        });
        completer.complete(pouchables);
      }
    }
        
    // Work hard.
    this.db.callMethod('get', [docId, optionsJs, callback]);
    
    return completer.future;
  }
  
  /// Delete a document, doc is required to be a document with at least an _id 
  /// and a _rev property, sending the full document will work.
  Future<String> remove(Pouchable pouchable, [options]) {
    // Create jsObjects.
    JsObject pouchableJs = new JsObject.jsify(pouchable.toMap());
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
           
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(error); 
      } else {
        Map map = _dartify(response);
        // Pouchable was deleted, return the revision number.
        completer.complete(map['rev']);
      }
    }
        
    // Work hard. 
    this.db.callMethod('remove', [pouchableJs, optionsJs, callback]);
    
    return completer.future;
  }
    
  /// Modify, create or delete multiple documents. The docs argument is an 
  /// object with property docs which is an array of documents. You can also
  /// specify a new_edits property on the docs object that when set to false
  /// allows you to post existing documents.
  Future<List<Pouchable>> bulkDocs(Iterable<Pouchable> docs, [options]) {
    var completer = new Completer();
    if (docs != null) {
      // Create jsObject.
      List list = [];
      docs.forEach((doc) => list.add(doc.toMap()));
      JsObject docsJs = new JsObject.jsify(list);
      JsObject inputJs = new JsObject.jsify({"docs": docsJs});
      JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
                  
      // Define the callback.
      callback(JsObject error, [JsObject response]) {
        if (error != null) {
          completer.completeError(_dartify(error)); 
        } else {
          // The response is a map containing the ids and the rev numbers in the 
          // same order as the supplied "docs" array. Extract the ids and revs.
          List resultList = _dartify(response);
          for (int i = 0; i < resultList.length; i++) {
            Map resultElement = resultList[i];
            Pouchable pouchable = docs.elementAt(i);
            pouchable.id = resultElement['id'];
            pouchable.rev = resultElement['rev']; 
          } 
          completer.complete(docs);
        }
      }
      
      this.db.callMethod('bulkDocs', [inputJs, optionsJs, callback]);
    } else {
      completer.complete(null);
    }
    
    return completer.future;
  }
  
  /// Fetch multiple documents, deleted document are only included if 
  /// options.keys is specified.
  Future<List<Pouchable>> allDocs([options]) {
    // Create jsObject.
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
    
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        Map map = _dartify(response);
        // Create a list of pouchables from response.
        // MAYBE: roll out into external method.
        List<Pouchable> result = toObservable([]);
        // The docs are stored in "rows".
        List rows = map['rows'];
        if (rows != null && rows.isNotEmpty) {
          for (Map row in rows) {
            if (row != null) {
              Map doc = row['doc'];
              if (doc != null) {
                result.add(toPouchable(doc));  
              }
            }            
          }
        } 
        completer.complete(result);
      }
    }
    // Work hard.
    this.db.callMethod('allDocs', [optionsJs, callback]);
    
    return completer.future;
  }
  
  /// A list of changes made to documents in the database, in the order they
  /// were made.
  JsObject changes(options) {
    if (options != null) {
      var onChange = options['onChange'];
      var onComplete = options['complete'];
      
      if (onChange != null) {
        // Define a new, js-compatible function.
        onChangeJs(JsObject ops, JsObject changes) {
          // Call the original function.
          onChange(_dartify(changes));
        }
        options['onChange'] = new JsFunction.withThis(onChangeJs);
      }
      
      if (onComplete != null) {
        // Define a new, js-compatible function.
        onCompleteJs(JsObject ops, JsObject changes) {
          // Call the original function.
          onComplete(_dartify(changes));
        }
        options['complete'] = new JsFunction.withThis(onCompleteJs);
      }
    }
    // Create jsObject.
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
    return db.callMethod('changes', [optionsJs]);
  }
    
  /// Attaches a binary object to a document, most of PouchDB's API deals with 
  /// JSON however we often need to store binary data, these are called 
  /// attachments and you can attach any binary data to a document.
  Future<String> putAttachment(String docId, String attachmentId, String rev,
      Blob doc) {
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        // Return the rev id.
        completer.complete(response['rev']);
      }
    }
    // Work hard.
    this.db.callMethod('putAttachment', [docId, attachmentId, rev, doc, 
                                         doc.type, callback]);
    return completer.future;
  }
  
  /// Get attachment data.
  Future<Blob> getAttachment(String docId, String attachmentId, [options]) {
    // Create jsObject.
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
    
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [Blob blob]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        completer.complete(blob);
      }
    }
    
    // Work hard.
    this.db.callMethod('getAttachment', [docId, attachmentId, optionsJs, 
                                         callback]);
    return completer.future;
  }
  
  /// Delete an attachment from a doc.
  Future<String> removeAttachment(String docId, String attachmentId) {
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        // Return the rev number.
        completer.complete(response['rev']);
      }
    }
    // Work hard.
    this.db.callMethod('removeAttachment', [docId, attachmentId, callback]);
    
    return completer.future;
  }
  
  /// Retrieve a view, this allows you to perform more complex queries on 
  /// PouchDB, the CouchDB documentation for map reduce applies to PouchDB.
  Future<List<Pouchable>> query(JsObject fun, [options]) {
    // Create js objects.
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
    
    var completer = new Completer();
    // Define the callback.
    callback(error, [response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {   
        Map map = _dartify(response);
        // Create a list of pouchables from response.
        // MAYBE: roll out into external method.
        List<Pouchable> result = toObservable([]);
        // The docs are stored in "rows".
        List rows = map['rows'];
        if (rows != null && rows.isNotEmpty) {
          for (Map row in rows) {
            if (row != null) {
              Map doc = row['value'];
              if (doc != null) {
                result.add(toPouchable(doc));  
              }
            }            
          }
        } 
        completer.complete(result);
      }
    }
    
    // Work hard.
    this.db.callMethod('query', [fun, optionsJs, callback]);
    
    return completer.future;
  }
  
  /// Get information about a database.
  Future<Map> info() {
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        completer.complete(_dartify(response));
      }
    }
    // Work hard.
    this.db.callMethod('info', [callback]);
    
    return completer.future;
  }
  
  /// Runs compaction of the database.
  Future compact([options]) {
    // Create js objects.
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
    
    var completer = new Completer();
    // Define the callback.
    callback([JsObject error, JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        // Nothing to return.
        completer.complete();
      }
    }
    // Work hard.
    this.db.callMethod('compact', [optionsJs, callback]);
    
    return completer.future;
  }
  
  revsDiff(diff) {
    // TODO: Implement this, find suitable structure for diff.
    // this.db.callMethod('compact', [diff, callback]);
  }
  
  /// Syncs the database to given url.
  void sync(String url, {toOpts: null, fromOpts: null}) {
    if (url == null) return;
    if (toOpts == null) {
      toOpts = {
        'continuous': 'true',
        'conflicts': 'true',
        'include_docs': 'true'
      };
    }
    if (fromOpts == null) fromOpts = toOpts;
    replicateTo(url, toOpts);
    replicateFrom(url, fromOpts);
  }
  
  /// Replicate to a remote couch.
  void replicateTo(String remote, [options]) {
    replicate(name, remote, options);
  }
  
  /// Replicate from a remote couch.
  void replicateFrom(String remote, [options]) {
    replicate(remote, name, options);
  }
  
  /// Replicate data from source to target, both the source and target can be 
  /// strings used to represent a database of a PouchDB object.
  static void replicate(String source, String target, [options]) {
    if (options != null) {
      var onChange = options['onChange'];
      var onComplete = options['complete'];
       
      if (onChange != null) {
        // Define a new, js-compatible function.
        onChangeJs(changes) {
          // TODO: changes can be "JsObject" or "Map". Why is this the case?
          if (!(changes is Map)) { changes = _dartify(changes); }
          onChange(changes);
        }
        options['onChange'] = onChangeJs;
      }
      
      if (onComplete != null) {
        // Define a new, js-compatible function.
        onCompleteJs(JsObject result) {
          // Call the original function.
          onComplete(_dartify(result));
        }
        options['complete'] = onCompleteJs;
      }
    }
    
    // Create js objects.
    JsObject optionsJs = new JsObject.jsify((options != null) ? options : {});
       
    print("replicate from $source to $target");
    context['PouchDB'].callMethod('replicate', [source, target, optionsJs]);
  }
   
  ///Retrieves all databases from PouchDB
  static Future destroy(String name) {
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        // Nothing to return.
        completer.complete();
      }
    }
    // Work hard.    
    context['PouchDB'].callMethod('destroy', [name, callback]);
    
    return completer.future;
  }
  
  /// Retrieves all databases from PouchDB
  static Future<List<String>> allDbs() {
    // By default, this feature is turned off and this function will return an 
    // empty list. To enable this feature and obtain a list of all the 
    // databases, set PouchDB.enableAllDbs to true before creating any databases
    context['PouchDB']['enableAllDbs'] = 'true';
    
    var completer = new Completer();
    // Define the callback.
    callback(JsObject error, [JsObject response]) {
      if (error != null) {
        completer.completeError(_dartify(error)); 
      } else {
        // Result contains the names of all dbs. Create a list from result.  
        Map map = _dartify(response);
        completer.complete(new List.from(map.values));
      }
    }
    // Work hard.    
    context['PouchDB'].callMethod('allDbs', [callback]);
    
    return completer.future;
  }
  
  /// Transforms the given js object into a dart object.
  static _dartify(JsObject object) {
    // Workaround to put the jsObject into map: Encode the jsObject into JSON 
    // (within JS) and decode it again (within dart).
    return JSON.decode(context['JSON'].callMethod('stringify', [object]));
  }
  
  /// Abstract method to transform the given map to pouchable.
  Pouchable toPouchable(Map map);
  
  // ___________________________________________________________________________
  // Helper methods. TODO: Outsource.
  
  /// Extracts the entryId, rev and deleted-flag from given storage-change.
  /// MAYBE: Outsource the method in any *Util.
  Map prepareDbChange(change) {
    // Here’s what a changes item looks like:
    // {"seq":12,"id":"foo","changes":[{"rev":"1-23202479633c2b380f795043d5"}]}
    String entryId = (change != null) ? change['id'] : null;
    List changes = (change != null) ? change['changes'] : null;
    bool deleted = (change['deleted'] != null) ? change['deleted'] : false;
    Map fields = (changes != null && changes.isNotEmpty) ? changes.first : null;
    String rev = (fields != null) ? fields['rev'] : null;
    return {'entryId': entryId, 'rev': rev, 'deleted': deleted}; 
  }
}