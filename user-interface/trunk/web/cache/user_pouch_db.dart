part of user_cache;

@MirrorsUsed(targets: 'User')
/// The pouch db for users. 
/// TODO: Do we need a conflict resolver here?
class UserPouchDb extends PouchDb {
  /// The internal instance.  
  static UserPouchDb _instance;
  
  /// The various stream controllers.
  StreamController<User> userUpdatedStream;
  StreamController<String> userDeletedStream;
  
  /// The factory constructor, returning the current instance.
  factory UserPouchDb(String name) {
    if (_instance == null || _instance.name != name) 
      _instance = new UserPouchDb._internal(name);
    return _instance;
  }

  /// The internal constructor.
  UserPouchDb._internal(String name) : super(name) {
    userUpdatedStream = new StreamController<User>.broadcast();
    userDeletedStream = new StreamController<String>.broadcast();
    
    // Register an onChange handler.
    info().then((info) { changes({
      'since': info['update_seq'],
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
         User user = toPouchable(doc);
         if (user != null) {
           if (user.id == null || user.rev == null) return;
           if (dbChange['deleted'] == true) {
             userDeletedStream.add(user.id);      
           } else if (dbChange['_conflicts'] != null) {
             // TODO: Are there any conflicts to resolve?
//            resolveConflicts(user).then((entry) {
               userUpdatedStream.add(user);  
//            });
           } else {
             userUpdatedStream.add(user);
           }
         }
       }
     }
   }
  
  /// Transforms the given map to FeedEntry.
  User toPouchable(Map map) => new User.fromMap(map);
  
  /// Cancels the replication and closes the streams.
  void close() {
    // TODO: Cancel replication.
    userUpdatedStream.close();
    userDeletedStream.close();
  }
      
  // ___________________________________________________________________________
  // Actions.
  
  /// Returns all users.
  Future<List<User>> getUsers() {
    return allDocs({'conflicts': 'true', 'include_docs': 'true'});
  }
  
  /// Returns the user given by the id.
  Future<User> getUser(String userId, [Map opts]) {
    return get(userId, opts);
  }
  
  /// Sets the given user.
  Future setUser(User user) {
    return post(user);
  }
         
  /// Deletes the feed entry, given by id.
  Future deleteUser(User user) {
    return remove(user);
  }
  
  // ___________________________________________________________________________
  // The streams.
  
  /// Returns a stream for update events.
  Stream get onUserChanged => userUpdatedStream.stream;
  
  /// Returns a stream for delete events.  
  Stream get onUserDeleted => userDeletedStream.stream; 
}