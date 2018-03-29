library navigation_view;

import 'package:polymer/polymer.dart' hide ObservableMap;
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../elements/topics_element.dart';
import '../elements/users_element.dart';
import '../elements/upload_element.dart';
import '../elements/history_element.dart';

/// The navigation of Icecite.
@CustomTag('navigation-view')
class NavigationView extends IceciteElement {  
  /// The individual elements of navigation view.
  TopicsElement topicsElement;
  UploadElement uploadElement;
  UsersElement usersElement;
  HistoryElement historyElement;
  
  /// The default constructor.
  NavigationView.created() : super.created();
    
  // ___________________________________________________________________________
  // Handlers.
    
  // Override.
  void revealedHandler() {
    super.revealedHandler();
    this.topicsElement = get("topics-element");
    this.uploadElement = get("upload-element");
    this.usersElement = get("users-element");
    this.historyElement = get("history-element");
  }
    
  /// This method is called, whenever a user has logged out.
  void loginHandler(User user) {
    // Elements are already defined, because revealedHandler was already called
    // (because navigation is revelaed by default).
    super.loginHandler(user);
    topicsElement.reveal();
    uploadElement.reveal();
    usersElement.reveal();
    historyElement.reveal();
  }
  
  /// This method is called, whenever a user has logged out.
  void logoutHandler() {
    topicsElement.unreveal();
    uploadElement.unreveal();
    usersElement.unreveal();
    historyElement.unreveal();
    super.logoutHandler();
  }
    
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// This method is called, whenever an library entry was selected.
  void onSelectLibraryEntryPurpose(event, entry, target) {
    historyElement.onSelectLibraryEntryPurpose(event, entry, target);
  }
}