library user_cache;

import 'dart:async';
import 'dart:mirrors';
import 'cache_impl.dart';
import '../models/models.dart';
import '../properties.dart';
import 'database/pouch_db.dart';

part 'user_pouch_db.dart';

/// The feed entry cache.
class UserCache extends Cache<String, User> {    
  /// The internal instance.
  static UserCache _instance;
  /// The instance of UserPouchDb.
  UserPouchDb db;
  bool isFilled; 
      
  /// The various stream controllers.
  StreamController _fillStream;
  StreamController<User> _userChangedStream;
  StreamController<User> _userDeletedStream;
  
  /// The factory constructor, returning the current instance.
  factory UserCache() {
    if (_instance == null) {
      _instance = new UserCache._internal();
    } else {
      // Fill the instance, if it isn't filled yet (cache is cleared on logout).
      if (!_instance.isFilled) _instance.fill();
    }
    return _instance;
  }

  /// The internal constructor.
  UserCache._internal() : super() {
    this.isFilled = false;
    
    // Declare the stream controllers.
    _fillStream = new StreamController.broadcast();
    _userChangedStream = new StreamController<User>.broadcast();
    _userDeletedStream = new StreamController<User>.broadcast();
    
    // Declare the database.
    db = new UserPouchDb(DB_USERS_NAME());
    db.onUserChanged.listen((user) => userChangedHandler(user));
    db.onUserDeleted.listen((user) => userDeletedHandler(user));
    db.sync(DB_USERS_URL());
    
    fill();
  }
  
  /// Resets the cache.
  void resetOnLogout() {
    if (this.db != null) this.db.resetOnLogout();
    this.isFilled = false; 
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// Define the behavior when a user in storage was added or updated.
  void userChangedHandler(User user) {
    if (user != null) _cacheUser(user);
  }

  /// Define the behavior when a user in storage was deleted.
  void userDeletedHandler(String userId) {
    if (userId != null) _uncacheUser(getUser(userId));
  }
  
  // ___________________________________________________________________________
  // Database actions.
    
  /// Fills the cache.
  void fill() {
    db.getUsers().then((users) {
      if (users != null) users.forEach((user) => _cacheUser(user));
      _fillStream.add(null);
      isFilled = true;
    });
  }
  
  /// Sets the given user.
  Future setUser(User user) {
    return db.setUser(user); 
  }
  
  /// Deletes the given user.
  Future deleteUser(var user) {
    if (user != null) {
      String userId = (user is User) ? user.id : user;
      return db.deleteUser(user);
    }
    return new Future.value();
  }
  
  // ___________________________________________________________________________
  // Getters.
        
  /// Returns an iterable with all users inside. 
  Map<String, User> getUsers([userIds]) {
    if (userIds != null) {
      Map<String, User> res = {};
      userIds.forEach((userId) {
        if (userId != null && this[userId] != null) res[userId] = this[userId];
      });
      return res;
    } 
    return this;
  }
  
  /// Returns the user with given id.
  User getUser(String userId) => this[userId];
  
  // ___________________________________________________________________________
  // Helpers.
   
  /// Caches the given user.
  void _cacheUser(User user, {bool avoidFire: false}) {
    if (user != null) {
      User cachedUser = this[user.id];
//      if (cachedUser == null || cachedUser.rev < user.rev) {
        // change user, if there is no cached user or if the cached
        // user is older than the user to insert.
        this[user.id] = user;
        if (!avoidFire) _userChangedStream.add(user);
//      }
    }
  }
  
  /// Uncaches the given user.
  void _uncacheUser(User user, {bool avoidFire: false}) {
    if (user != null) {
     User removedUser = this.remove(user.id);
     if (removedUser != null && !avoidFire) 
       _userDeletedStream.add(user);
     }
  }
  
  /// Checks, if cache contains the given user.
  bool contains(User user) => (user != null && this.containsKey(user.id));
  
  // Override the clear method.
  void clear() {
    super.clear();
    db.close();
    _fillStream.close();
    _userChangedStream.close();
    _userDeletedStream.close();
    isFilled = false;
  }
  
  // ___________________________________________________________________________
  // The streams.
  
  /// Returns a stream for filled events.
  Stream get onFilled => _fillStream.stream;
  
  /// Returns a stream for user changed events.  
  Stream get onUserChanged => _userChangedStream.stream; 
  
  /// Returns a stream for user deleted events.  
  Stream get onUserDeleted => _userDeletedStream.stream;
}