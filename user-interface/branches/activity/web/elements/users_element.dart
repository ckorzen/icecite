library users_element;

import 'dart:html';
import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../models/models.dart';
import '../utils/observable_map.dart';
import '../utils/search/search_util.dart';

/// The users element of Icecite.
@CustomTag('users-element')
class UsersElement extends IceciteElement {
  /// The users to show.
  @observable Map<String, User> users = new ObservableMap();
  /// The filter query.
  @observable String filterQuery;
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  UsersElement.created() : super.created();
    
  @override
  void attached() {
    super.attached();
        
    // Wait until the library entries are cached.
    if (actions.areUsersFilled()) fill();
    actions.onLibraryEntriesFilled.listen((_) => fill());
 
    // Listen for changes on users.
    actions.onUserChanged.listen(onUserChangedInDb);
    actions.onUserDeleted.listen(onUserDeletedInDb);
  }
  
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.users != null) this.users.clear();
    this.filterQuery = null;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever a user was changed in db.
  void onUserChangedInDb(user) => handleUserChangedInDb(user); 
  
  /// This method is called, whenever a user was deleted in db.
  void onUserDeletedInDb(user) => handleUserDeletedInDb(user);  
  
  /// This method is called, whenever a user was invited to entry.
  void onUserInvited(event, detail) => handleUserInvited(event, detail);
  
  // ___________________________________________________________________________
  // Actions.
   
  /// Handles a change of user in db.
  void handleUserChangedInDb(User user) {
    // Reveal the user.
    revealUser(user);
  }

  /// Handles a deletion of user in db.
  void handleUserDeletedInDb(User user) {
    // Unreveal the user.
    unrevealUser(user);
  }

  /// Handles a change of user in db.
  void handleUserInvited(Event event, Map detail) {
    retardEvent(event);
    // Invite the user to entry.
    inviteUserToEntry(detail['entryId'], detail['userId']);
  }
  
  // ___________________________________________________________________________
  
  /// Fills the topics list.
  void fill() { 
    users.addAll(actions.getUsers());
  }
  
  /// Reveals the user
  void revealUser(User user) {
    if (user == null) return; 
    users[user.id] = user;
  }
    
  /// Unreveals the user.
  void unrevealUser(User user) {
    if (user == null) return;
    users.remove(user.id);
  }
  
  /// Invites the given user to given entry.
  void inviteUserToEntry(String entryId, String userId) {
    actions.inviteUserToEntry(entryId, userId);
  }
  
  // ___________________________________________________________________________
  
  /// Filters the users by given filter.  
  Function filterBy(String filter) { 
    return (Iterable<User> users) { 
      if (users == null) return [];
      return users.where((user) => filterUserByQuery(user, filter));
    };
  }
  
  /// Sorts the users by their lastnames.  
  Function sortByLastName() { 
    return (Iterable<User> users) { 
      return users.toList()..sort(IceciteElement.getComparator("lastName"));  
    };
  }
}