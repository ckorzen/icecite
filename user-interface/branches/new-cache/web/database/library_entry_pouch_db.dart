library library_entry_pouch_db;

import 'dart:html';
import 'dart:async';
import 'dart:mirrors';
import '../models/models.dart';
import '../database/pouch_db.dart';
import '../properties.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';

part 'library_entry_conflict_resolver.dart'; 

@MirrorsUsed(targets: 'LibraryEntry')
/// The pouch db for library entries.
class LibraryEntryPouchDb extends PouchDb {  
  /// The internal instance.
  static LibraryEntryPouchDb _instance;
  /// The conflict resolver.
  LibraryEntryConflictResolver libraryEntryConflictResolver;
  /// The stream controller.
  StreamController dbChangeStream;
  /// The user.
  User user;  
  
  /// The factory constructor, returning the current instance.
  factory LibraryEntryPouchDb(User user) {   
    if (_instance == null || _instance.user != user) {
      _instance = new LibraryEntryPouchDb._internal(user);
    }
    return _instance;
  }

  /// The internal constructor.
  LibraryEntryPouchDb._internal(User user) : super(DB_ENTRIES_NAME(user.id)) {
    this.user = user;
    this.libraryEntryConflictResolver = new LibraryEntryConflictResolver();
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
  void reset() {
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
     
  @override
  LibraryEntry toPouchable(Map map) => new LibraryEntry.fromData(map);
        
  // ___________________________________________________________________________
  // Actions.
  
  /// Returns all library entries.
  Future<List<LibraryEntry>> getLibraryEntries() {
    return this.allDocs({'conflicts': 'true', 'include_docs': 'true'});
  }
  
  /// Returns the library entry given by the id.
  Future<LibraryEntry> getLibraryEntry(String id, [Map opts]) {
    return get(id, opts);
  }
  
  /// Sets the given library entries.
  Future setLibraryEntries(List<LibraryEntry> entries) {
    return bulkDocs(entries);
  }
  
  /// Sets the given library entry.
  Future setLibraryEntry(LibraryEntry entry, {Blob pdf}) {
    Completer completer = new Completer();
    
    post(entry).then((entry) {
      if (pdf != null) {
        setPdf(entry, pdf)
          .then((_) => completer.complete(entry))
          .catchError(completer.completeError);
      } else {
        completer.complete(entry);
      }
    }).catchError(completer.completeError);
    
    return completer.future;
  }
          
  /// Deletes the library entries (the references of entry if entry != null).
  Future deleteLibraryEntries(Iterable<LibraryEntry> entries) {
    if (entries != null) {
      entries.forEach((entry) {
        if (entry != null) entry["_deleted"] = true;
      });
    }
    return bulkDocs(entries);
  }
  
  /// Deletes the library entry, given by id.
  Future deleteLibraryEntry(LibraryEntry entry) {
    return remove(entry);
  }
    
  /// Returns the pdf for given key (entry or id of entry).
  Future<Blob> getPdf(var key) {
    String id = (key is LibraryEntry) ? key.id : key;
    return getAttachment(id, "$id-pdf");
  }
  
  /// Sets the given pdf for given key (entry or id of entry).
  Future setPdf(LibraryEntry entry, Blob pdf) {
    if (pdf == null) return new Future.value();
    return putAttachment(entry.id, "${entry.id}-pdf", entry.rev, pdf);
  }
    
  /// Returns the pdf for given key (entry or id of entry).
  Future deletePdf(var key) {
    String id = (key is LibraryEntry) ? key.id : key;
    return removeAttachment(id, "$id-pdf");
  }
  
  // ___________________________________________________________________________
  
  /// Resolves the conflicts of the given entry.
  Future<Map> resolveConflicts(Map master) {
    Completer completer = new Completer();
    getConflictedRevs(master['_id'], master['_conflicts']).then((revs) {
      if (revs == null || revs.isEmpty) {
        completer.complete(master);
       return;
      }
      
      // Resolve the conflict.
      libraryEntryConflictResolver.resolve(master, revs).then((res) {
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
  
  // ___________________________________________________________________________
  // The streams.
  
  /// Returns a stream for db changes.
  Stream get onDbChange => dbChangeStream.stream;
}