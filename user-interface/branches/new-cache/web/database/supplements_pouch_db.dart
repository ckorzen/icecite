library supplements_pouch_db;

import 'dart:async';
import 'dart:mirrors';
import '../models/models.dart';
import '../database/pouch_db.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';

part 'supplements_conflict_resolver.dart';

@MirrorsUsed(targets: 'FeedEntry')
/// The pouch db for supplements (references, feeds, annots).
class SupplementsPouchDb extends PouchDb {
  /// The internal instance.
  static SupplementsPouchDb _instance;
  /// The conflict resolver.
  SupplementsConflictResolver supplementsConflictResolver;  
  /// The stream controller.
  StreamController dbChangeStream;
    
  /// The factory constructor, returning the current instance.
  factory SupplementsPouchDb(String name) {
    if (_instance == null || _instance.name != name) 
      _instance = new SupplementsPouchDb._internal(name);
    return _instance;
  }
  
  /// The internal constructor.
  SupplementsPouchDb._internal(String name) : super(name) {
    this.supplementsConflictResolver = new SupplementsConflictResolver();
    this.dbChangeStream = new StreamController.broadcast();
        
    // Register an onChange handler.
    info().then((info) => changes({
      'since': info['update_seq'],
      'continuous': 'true',
      'conflicts': 'true',
      'onChange': onChange,
      'include_docs': 'true'
    }));
  }
  
  /// Resets this database connection.
  void close() {
    // TODO: Cancel replication.
    dbChangeStream.close();
  }
  
  // ___________________________________________________________________________
  
  /// This method is called whenever the db has changed.
  void onChange(Map dbChange) {
    dbChange = prepareDbChange(dbChange); // TODO: Prepare the change in pouch_db.dart?
    if (dbChange != null) {
      if (dbChange['hasConflicts']) {
        resolveConflicts(dbChange['data']).then((master) {
          dbChangeStream.add(dbChange..['data'] = master); 
        });    
      } else {
        dbChangeStream.add(dbChange);
      }
    }
  }
   
  /// Transforms the given map to FeedEntry.
  Pouchable toPouchable(Map map) {
    switch (map['type']) {
      case 'reference-entry':
        return new ReferenceEntry.fromData(map);
      case 'pdf-annotation':
        return new PdfAnnotation.fromData(map);
//      case 'feed':
//        return new FeedEntry.fromMap(map);
      default:
        return null;
    }
  }
            
  // ___________________________________________________________________________
  // Actions.
  
  /// Returns all supplements in this database.
  Future<Iterable<Pouchable>> getSupplements() {
    return this.allDocs({'conflicts': 'true', 'include_docs': 'true'});
  }
  
  /// Sets the given references.
  Future setReferences(Iterable<ReferenceEntry> references) {
    return bulkDocs(references);
  }
  
  /// Sets the given references.
  Future setReference(ReferenceEntry reference) {
    return post(reference);
  }
  
  /// Deletes the given references.
  Future deleteReferences(Iterable<ReferenceEntry> references) {
    if (references != null) references.forEach((ref) => ref["_deleted"] = true);
    return bulkDocs(references);
  }
  
  /// Deletes the given references.
  Future deleteReference(ReferenceEntry reference) {
    return remove(reference);
  }
  
  /// Sets the given annotations.
  Future setPdfAnnotations(Iterable<PdfAnnotation> annots) {
    return bulkDocs(annots);
  }
  
  /// Sets the given annotation.
  Future setPdfAnnotation(PdfAnnotation annot) {
    return post(annot);
  }
  
  /// Deletes the given annotations.
  Future deletePdfAnnotations(Iterable<PdfAnnotation> annots) {
    if (annots != null) annots.forEach((annot) => annot["_deleted"] = true);
    return bulkDocs(annots);
  }
  
  /// Deletes the given references.
  Future deletePdfAnnotation(PdfAnnotation annot) {
    return remove(annot);
  }
  
//  /// Sets the given feed entries.
//  Future setFeedEntries(Iterable<FeedEntry> feeds) {
//    return bulkDocs(feeds);
//  }
//  
//  /// Sets the given feed entry.
//  Future setFeedEntry(FeedEntry feed) {
//    return post(feed);
//  }
  
//  /// Deletes the given feed entries.
//  Future deleteFeedEntries(Iterable<FeedEntry> feeds) {
//    if (feeds != null) feeds.forEach((feed) => feed["_deleted"] = true);
//    return bulkDocs(feeds);
//  }
//  
//  /// Deletes the given feed entry.
//  Future deleteFeedEntry(FeedEntry feed) {
//    return remove(feed);
//  }
    
  // ___________________________________________________________________________
  // Helper methods. 
  
  /// Resolves the conflicts of the given entry.
  Future<Map> resolveConflicts(Map master) {
    Completer completer = new Completer();
    getConflictedRevs(master['_id'], master['_conflicts']).then((revs) {
      if (revs == null || revs.isEmpty) {
        completer.complete(master);
        return;
      }
        
      // Resolve the conflict.
      supplementsConflictResolver.resolve(master, revs).then((res) {
        if (res == null) {
          completer.complete(master);
          return;
        }        
        
        // Delete all the revisions.
        Future.forEach(revs, (rev) => remove(rev)).then((_) {
          if (res.wasUpdated) {
            put(res.master).then((master) {
              completer.complete(master);
              return;
            });
          } else {
            completer.complete(master);
            return;
          }
        });
      });
    });
    
    return completer.future;
  }
  
  List<Pouchable> toPouchableList(List<Map> dataList) {
    if (dataList == null) return null;
    List list = [];
    dataList.forEach((data) {
      switch (data['type']) {
        case "pdf-annotation":
          list.add(new PdfAnnotation.fromData(data));
          break;
        case "reference-entry":
          list.add(new ReferenceEntry.fromData(data));
          break;
        default:
          break;
      }
    });
    return list;
  }
  
  // ___________________________________________________________________________
  // The streams.
   
  /// Returns a stream for db changes.
  Stream get onDbChange => dbChangeStream.stream;
}