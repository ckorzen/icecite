part of supplements_pouch_db;

/// The conflict resolver for library entries.
class SupplementsConflictResolver {
  Logger LOG = logging.get("supplements-conflict-resolver");
  
  /// Resolves the conflicts for given revs.
  Future<ConflictResolverResult> resolve(Map master, List<Map> revisions) {     
    if (revisions == null || revisions.isEmpty) {
      return new Future.value(new ConflictResolverResult(false, master));
    }
    return new Future.value(_merge(master, revisions));
  }
  
  ConflictResolverResult _merge(Map master, List<Map> revisions) {                
    // Sort the revs by modified date.
    revisions.sort((a, b) {
      var first = a['modified'] != null ? a['modified'] : a['created'];
      var second = b['modified'] != null ? b['modified'] : b['created'];
      
      return first.compareTo(second);
    });
         
    bool updated = false;
    
    revisions.forEach((revision) {
      revision.keys.forEach((key) {
        if (master[key] == null) {
          master[key] = revision[key];
          updated = true;
        }
      });
    });
    return new ConflictResolverResult(updated, master);
  }
}

class ConflictResolverResult {
  bool wasUpdated = false;
  var master;
  ConflictResolverResult(this.wasUpdated, this.master);
}