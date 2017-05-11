library users_element;

import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../models/models.dart';
import '../utils/observable_map.dart';
import '../utils/search/search_util.dart';

/// The users element of Icecite.
@CustomTag('users-element')
class UsersElement extends IceciteElement {
  @observable Map<String, User> users = new ObservableMap();
  @observable String filter;
  
  /// The default constructor.
  UsersElement.created() : super.created();
    
  // Overrides.
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/users_element.css"));
        
    // Wait until the library entries are cached.
    if (actions.areUsersFilled()) fill();
    actions.onLibraryEntriesFilled.listen((_) => fill());
 
    // Listen for changes on users.
    actions.onUserChanged.listen(userChangedHandler);
    actions.onUserDeleted.listen(userDeletedHandler);
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.users != null) this.users.clear();
    this.filter = null;
  }
  
  // ___________________________________________________________________________
  // On purpose methods.
  
  /// Will assign topic to entry.
  void onAssignPurpose(e, d, t) => assign(d['entryId'], d['userId']);
  
  // ___________________________________________________________________________
  // Handlers.
      
  /// Define the behavior when a user in storage was added or updated.
  void userChangedHandler(User user) => revealUser(user); 
  
  /// Define the behavior when a user in storage was added or updated.
  void userDeletedHandler(User user) => unrevealUser(user);  
      
  // ___________________________________________________________________________
  // Actions.
   
  /// Fills the topics list.
  void fill() => users.addAll(actions.getUsers());
         
  /// Assigns the given entry to given user.
  void assign(String entryId, String userId) {
    actions.assignEntryToUser(entryId, userId);
  }
  
  // ___________________________________________________________________________
  // Display methods.
  
  /// Reveals a topic, i.e. adds the topic, if it isn't present in
  /// library and updates it otherwise.
  void revealUser(User user) {
    if (user != null) users[user.id] = user;
  }
    
  /// Reveals a topic, i.e. adds the topic, if it isn't present in
  /// library and updates it otherwise.
  void unrevealUser(User user) {
    if (user != null) users.remove(user.id);
  }
  
  /// Filters the entries by searchQuery.  
  Function filterBy(String filter) { 
    return (Iterable<User> users) { 
      if (users == null) return [];
      return users.where((user) => filterUserByQuery(user, filter));
    };
  }
}