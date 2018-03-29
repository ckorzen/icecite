part of library_entry_cache;

@MirrorsUsed(targets: 'LibraryEntry')
/// The pouch db for library entries.
class LibraryEntryPouchDb extends PouchDb {  
  /// The internal instance.
  static LibraryEntryPouchDb _instance;
  /// The conflict resolver.
  LibraryEntryConflictResolver conflictResolver;  
  
  /// The various stream controllers.
  StreamController<LibraryEntry> libraryEntryUpdatedStream;
  StreamController<String> libraryEntryDeletedStream;
  
  /// The factory constructor, returning the current instance.
  factory LibraryEntryPouchDb(String name) {   
    if (_instance == null || _instance.name != name) {
      _instance = new LibraryEntryPouchDb._internal(name);
    }
    return _instance;
  }

  /// The internal constructor.
  LibraryEntryPouchDb._internal(String name) : super(name) {
    conflictResolver = new LibraryEntryConflictResolver();
    libraryEntryUpdatedStream = new StreamController<LibraryEntry>.broadcast();
    libraryEntryDeletedStream = new StreamController<String>.broadcast();    
    
    // Register an onChange handler.
    info().then((info) => changes({
      'since': info['update_seq'],
      'continuous': 'true',
      'conflicts': 'true',
      'onChange': onDbChange,
      'include_docs': 'true'}));
  }
   
  /// Resets the db.
  void resetOnLogout() {
    super.resetOnLogout();
  }
  
  /// This method is called whenever the db has changed.
  void onDbChange(dbChange) {
    if (dbChange != null) {
      Map doc = dbChange['doc'];
      if (doc != null) {
        // Create a library entry from the map.
        LibraryEntry entry = toPouchable(doc);
        if (entry != null) {
          if (entry.id == null || entry.rev == null) return;
          if (dbChange['deleted'] == true) {
            libraryEntryDeletedStream.add(entry.id);      
          } else if (dbChange['_conflicts'] != null) {
            resolveConflicts(entry).then((entry) {
              libraryEntryUpdatedStream.add(entry);  
            });
          } else {
            libraryEntryUpdatedStream.add(entry);
          }
        }
      }
    }
  }
  
  /// Overrides.
  LibraryEntry toPouchable(Map map) => new LibraryEntry.fromMap(map);
    
  /// Cancels the replication and closes the streams.
  void close() {
    // TODO: Cancel replication.
    libraryEntryUpdatedStream.close();
    libraryEntryDeletedStream.close();
  }  
    
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
  Future setLibraryEntry(LibraryEntry entry) {
    return post(entry);
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
  // The streams.
  
  /// Returns a stream for update events.
  Stream get onLibraryEntryChanged => libraryEntryUpdatedStream.stream;
  
  /// Returns a stream for delete events.  
  Stream get onLibraryEntryDeleted => libraryEntryDeletedStream.stream; 
  
  // ___________________________________________________________________________
  // Helper methods.
  
  /// Resolves the conflicts of the given entry.
  Future<LibraryEntry> resolveConflicts(LibraryEntry entry) {
    Completer completer = new Completer();
    getConflictedRevs(entry.id)
      .then((revs) => conflictResolver.resolve(revs))
      .then((res) => bulkDocs(res[1])
      .then((_) => completer.complete(res[0]))) 
      .catchError((e) => completer.completeError);
    return completer.future;
  }
}