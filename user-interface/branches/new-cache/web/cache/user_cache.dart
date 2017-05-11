library user_cache;

import 'dart:async';
import '../models/models.dart';
import '../properties.dart';
import '../database/pouch_db.dart';
import '../database/user_pouch_db.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

/// The user cache.
class UserCache extends ObservableMap<String, User> {    
  /// The logger.
  Logger LOG = logging.get("user-cache");
  
  /// The instance of UserPouchDb.
  UserPouchDb userDb;
  
  /// The internal constructor.
  UserCache._internal() : super() {
    LOG.fine("Create user cache.");
    // Declare the database.
    this.userDb = new UserPouchDb(DB_USERS_NAME());
    this.userDb.onDbChange.listen(handleUserDbChange);
    this.userDb.sync(DB_USERS_URL());
  }
  
  // ___________________________________________________________________________
  
  /// Initializes this user cache.
  Future initialize() {
    LOG.fine("Initialize user cache.");       
    return fill();
  }
  
  /// Resets this user cache.
  void reset() {
    LOG.fine("Reset user cache.");
    // Nothing to do so far. Don't clear the user cache on logout.
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// Define the behavior when a library entry in storage was added or updated.
  void handleUserDbChange(Map change) {
    LOG.finer("Handle user db change: $change");
    if (change == null) return;
    
    DbChangeAction action = change['action'];    
    switch (action) {
      case DbChangeAction.UPDATED:
        applyUserDbUpdateAction(change);
        break;
      case DbChangeAction.DELETED:
        applyUserDbDeleteAction(change);
        break;
      default:
        break;
    }  
  }
  
  /// Applies the given db update action.
  void applyUserDbUpdateAction(Map change) {
    LOG.finer("Handle user db update action.");
    if (change == null) return;
    
    String entryId = change['id'];
    Map data = change['data'];
    if (containsKey(entryId)) {
      _recacheUser(entryId, data);
    } else {
      _cacheUser(new User.fromData(data));
    }
  }
  
  /// Applies the given db delete action.
  void applyUserDbDeleteAction(Map change) {
    LOG.finer("Handle user db delete action.");
    if (change == null) return;
    _uncacheUser(change['id']);
  }
  
  // ___________________________________________________________________________
  // Internal methods.
  
  /// Caches the given user after db change.
  void _cacheUser(User user) {
    LOG.finest("Caching user $user.");
    if (user == null) return;
    if (this.containsKey(user.id)) return;
    this[user.id] = user;
  }
  
  /// Updates an already cached user with given data.
  void _recacheUser(String userId, Map data) {
    LOG.finest("Recache user with id $userId. Data: $data");
    User user = this[userId];
    if (user != null) {
      bool applied = user.applyData(data);
    }
  }
  
  /// Uncaches the given user after db change.
  void _uncacheUser(String userId) {
    LOG.finest("Uncache user with id $userId");
    remove(userId);
  }
      
  // ___________________________________________________________________________
  // Database actions.
    
  /// Fills the cache.
  Future fill() {
    LOG.finest("Filling user cache.");
    return userDb.getUsers().then((users) {
      if (users == null) return; 
      users.forEach((user) => _cacheUser(user));
      LOG.finest("Filling user cache finished.");
    });
  }
  
  /// Sets the given user.
  Future addUser(User user) {
    LOG.finest("Add user $user.");
    return userDb.setUser(user); 
  }
  
  /// Deletes the given user.
  Future deleteUser(User user) {
    LOG.finest("Delete user $user.");
    return userDb.deleteUser(user);
  }
  
  // ___________________________________________________________________________
  // Getters.
        
  /// Returns an iterable with all users inside. 
  List<User> getUsers([Iterable<String> filters]) {
    if (filters != null) {
      List<User> filteredUsers = [];
      filters.forEach((id) => filteredUsers.add(this[id]));
      return filteredUsers;
    } else {
      return new List.from(this.values);
    }
  }
  
  /// Returns the user with given id.
  User getUser(String userId) => this[userId];
  
  // ___________________________________________________________________________
  // Helpers.
       
  /// Checks, if cache contains the given user.
  bool contains(User user) => (user != null && this.containsKey(user.id));
    
  // ___________________________________________________________________________
      
  /// The factory constructor, returning the current instance.
  factory UserCache() {
    if (_instance == null) {
      _instance = new UserCache._internal();
    }
    return _instance;
  }

  /// The internal instance.
  static UserCache _instance;
}