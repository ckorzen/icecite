library user_pouch_db;

import 'dart:async';
import 'dart:mirrors';
import '../models/models.dart';
import '../database/pouch_db.dart';

@MirrorsUsed(targets: 'User')
/// The pouch db for users. 
/// TODO: Do we need a conflict resolver here?
class UserPouchDb extends PouchDb {
  /// The internal instance.  
  static UserPouchDb _instance;
  /// The stream controllers.
  StreamController dbChangeStream;
    
  /// The factory constructor, returning the current instance.
  factory UserPouchDb(String name) {
    if (_instance == null || _instance.name != name) 
      _instance = new UserPouchDb._internal(name);
    return _instance;
  }

  /// The internal constructor.
  UserPouchDb._internal(String name) : super(name) {
    this.dbChangeStream = new StreamController.broadcast();
        
    // Register an onChange handler.
    info().then((info) { changes({
      'since': info['update_seq'],
      'continuous': 'true',
      'conflicts': 'true',
      'onChange': onChange,
      'include_docs': 'true'});
    });
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
      dbChangeStream.add(dbChange);  
    }
  }
      
  @override
  User toPouchable(Map map) => new User.fromData(map);
        
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
  Stream get onDbChange => dbChangeStream.stream;
}