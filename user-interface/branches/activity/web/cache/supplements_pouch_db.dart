part of supplements_cache;

@MirrorsUsed(targets: 'FeedEntry')
/// The pouch db for supplements (references, feeds, annots).
class SupplementsPouchDb extends PouchDb {
  /// The internal instance.
  static SupplementsPouchDb _instance;
  /// The conflict resolver.
  SupplementsConflictResolver conflictResolver;  
  
  /// The various stream controllers.
  StreamController<Pouchable> pouchableUpdatedStream;
  StreamController<String> pouchableDeletedStream;
  
  /// The factory constructor, returning the current instance.
  factory SupplementsPouchDb(String name) {
    if (_instance == null || _instance.name != name) 
      _instance = new SupplementsPouchDb._internal(name);
    return _instance;
  }

  int since;
  
  /// The internal constructor.
  SupplementsPouchDb._internal(String name) : super(name) {
    conflictResolver = new SupplementsConflictResolver();
    pouchableUpdatedStream = new StreamController<Pouchable>.broadcast();
    pouchableDeletedStream = new StreamController<String>.broadcast();
    
    // Register an onChange handler.
    info().then((info) { 
      since = info['update_seq'];
      changes({
      'since': since,
      'continuous': 'true',
      'conflicts': 'true',
      'onChange': onDbChange,
      'include_docs': 'true'});
    });
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
        Pouchable pouchable = toPouchable(doc);
        if (pouchable != null) {
          if (pouchable.id == null || pouchable.rev == null) return;
          if (dbChange['deleted'] == true) {
            pouchableDeletedStream.add(pouchable.id);      
          } else if (dbChange['_conflicts'] != null) {
            resolveConflicts(pouchable).then((entry) {
              pouchableUpdatedStream.add(entry);  
            });
          } else {
            pouchableUpdatedStream.add(pouchable);
          }
        }
      }
    }
  }
  
  /// Transforms the given map to FeedEntry.
  Pouchable toPouchable(Map map) {
    switch (map['brand']) {
      case 'reference':
        return new LibraryEntry.fromMap(map);
      case 'annot':
        return new PdfAnnotation.fromMap(map);
      case 'feed':
        return new FeedEntry.fromMap(map);
      default:
        return new Pouchable.fromMap(map);
    }
  }
    
  /// Cancels the replication and closes the streams.
  void close() {
    // TODO: Cancel replication.
    pouchableUpdatedStream.close();
    pouchableDeletedStream.close();
  }
        
  // ___________________________________________________________________________
  // Actions.
  
  /// Returns all supplements in this database.
  Future<Iterable<Pouchable>> getSupplements() {
    return this.allDocs({'conflicts': 'true', 'include_docs': 'true'});
  }
  
  /// Sets the given references.
  Future setReferences(Iterable<LibraryEntry> references) {
    return bulkDocs(references);
  }
  
  /// Sets the given references.
  Future setReference(LibraryEntry reference) {
    return post(reference);
  }
  
  /// Deletes the given references.
  Future deleteReferences(Iterable<LibraryEntry> references) {
    if (references != null) references.forEach((ref) => ref["_deleted"] = true);
    return bulkDocs(references);
  }
  
  /// Deletes the given references.
  Future deleteReference(LibraryEntry reference) {
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
  
  /// Sets the given feed entries.
  Future setFeedEntries(Iterable<FeedEntry> feeds) {
    return bulkDocs(feeds);
  }
  
  /// Sets the given feed entry.
  Future setFeedEntry(FeedEntry feed) {
    return post(feed);
  }
  
  /// Deletes the given feed entries.
  Future deleteFeedEntries(Iterable<FeedEntry> feeds) {
    if (feeds != null) feeds.forEach((feed) => feed["_deleted"] = true);
    return bulkDocs(feeds);
  }
  
  /// Deletes the given feed entry.
  Future deleteFeedEntry(FeedEntry feed) {
    return remove(feed);
  }
  
  // ___________________________________________________________________________
  // The streams.
  
  /// Returns a stream for update events.
  Stream get onSupplementChanged => pouchableUpdatedStream.stream;
  
  /// Returns a stream for delete events.  
  Stream get onSupplementDeleted => pouchableDeletedStream.stream; 
  
  // ___________________________________________________________________________
  // Helper methods. 
  
  /// Resolves the conflicts of the given entry.
  Future<Pouchable> resolveConflicts(Pouchable pouchable) {
    Completer completer = new Completer();
    getConflictedRevs(pouchable.id)
      .then((revs) => conflictResolver.resolve(revs))
      .then((res) => bulkDocs(res[1])
      .then((_) => completer.complete(res[0]))) 
      .catchError((e) => completer.completeError);
    return completer.future;
  }
}