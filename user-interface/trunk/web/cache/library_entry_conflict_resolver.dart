part of library_entry_cache;

/// The conflict resolver for library entries.
class LibraryEntryConflictResolver {
  /// Resolves the conflicts for given revs.
  Future<List> resolve(List<LibraryEntry> revs) {     
    if (revs == null || revs.isEmpty) {
      return new Future.value([null, revs]);
    }
    if (revs.length < 2) {
      LibraryEntry entry = new LibraryEntry.fromMap(revs.last.toMap());
      return new Future.value([entry, null]);
    } else {
      List<LibraryEntry> toChange = [];
      // Sort the revs by modified date.
      revs.sort((a, b) => a.modified.compareTo(b.modified));
      // Determine the master entry (that is the last modified rev). 
      LibraryEntry master = new LibraryEntry.fromMap(revs.last.toMap());
            
      // Enrich the master with all properties, which are not included yet.
      bool enriched = false;
      for (int i = 0; i < revs.length - 1; i++) {
        LibraryEntry rev = revs[i];
        enriched = enriched || master.enrich(rev);
        toChange.add(rev..["_deleted"] = true);
      }
      if (enriched) toChange.add(master);
      
      return new Future.value([master, toChange]);
    }
  }
}