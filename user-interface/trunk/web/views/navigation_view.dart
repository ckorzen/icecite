library navigation_view;

import 'dart:html';
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
  /// The revision of project.
  @observable String revision = "?";
  
  /// The topics element.
  TopicsElement topicsElement;
  /// The upload element.
  UploadElement uploadElement;
  /// The users element.
  UsersElement usersElement;
  /// The history element.
  HistoryElement historyElement;
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  NavigationView.created() : super.created();
      
  // ___________________________________________________________________________
  // Handlers.
    
  @override
  void onRevealed() => handleRevealed();
        
  @override
  void onLogin(User user) => handleLogin(user);
      
  @override
  void onLogout() => handleLogout();
          
  /// This method is called, whenever a library entry was selected.
  void onLibraryEntrySelected(entry) => handleLibraryEntrySelected(entry);
  
  // ___________________________________________________________________________
  // Private actions.
 
  /// Reveals the elements of this view.
  void handleRevealed() {
    this.topicsElement = get("topics-element");
    this.uploadElement = get("upload-element");
    this.usersElement = get("users-element");
    this.historyElement = get("history-element");
    // Read the revision number.
    readRevisionFromFile();
  }
  
  /// Handles a login event.
  void handleLogin(User user) {
    // Elements are already defined, because revealedHandler was already called
    // (because navigation is revealed by default).
    this.user = user;
    topicsElement.reveal();
    uploadElement.reveal();
    usersElement.reveal();
    historyElement.reveal();
  }
  
  /// Handles a logut event.
  void handleLogout() {
    this.user = null;
    topicsElement.unreveal();
    uploadElement.unreveal();
    usersElement.unreveal();
    historyElement.unreveal();
    resetOnLogout();
  }
  
  /// Handles the selection of library entry.
  void handleLibraryEntrySelected(LibraryEntry entry) {
    // Propagate the event to historyElement.
    historyElement.onLibraryEntrySelected(entry);
  }
  
  // ___________________________________________________________________________
  
  /// Reads the revision number from file.
  void readRevisionFromFile() {
    HttpRequest req = new HttpRequest()
        ..open('GET', 'revision', async: true)
        ..send();
    req.onLoad.listen((e) => revision = req.responseText); 
  }
}