part of supplements_cache;

/// The conflict resolver for feed entries.
class SupplementsConflictResolver {
  /// Resolves the conflicts for given revs.
  Future<List> resolve(List<Pouchable> revs) {
    Completer completer = new Completer();      
    if (revs == null || revs.length < 2) {
      // Nothing to do if there are no conflicts.
      completer.complete([null, revs]);
    } else {
      List<Pouchable> toChange = [];
      // Sort the revs by modified date.
      revs.sort((a, b) => a.modified.compareTo(b.modified));
      // Determine the master entry (that is the last modified rev). 
      Pouchable master = new Pouchable.fromMap(revs.last.toMap());      
      // Enrich the master with all properties, which are not included yet.
      bool enriched = false;
      for (int i = 0; i < revs.length - 1; i++) {
        Pouchable rev = revs[i];
        enriched = enriched || master.enrich(rev);
        toChange.add(rev..["_deleted"] = true);
      }
      if (enriched) toChange.add(master);
      return new Future.value([master, toChange]);
    }
    return completer.future;
  }
}