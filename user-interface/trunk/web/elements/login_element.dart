library login_element;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';

/// The login of Icecite.
@CustomTag('login-element')
class LoginElement extends IceciteElement {
  /// The default constructor.
  LoginElement.created() : super.created();
    
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever this view is revealed.
  void onRevealed() => handleRevealed();
  
  /// This method is called, whnever the toggle box was clicked.
  void onUserBoxToggleClick(event) => handleUserBoxToggleClick(event);
  
  /// This method is called, whenever the google-login button was clicked.
  void onGoogleLoginButtonClicked() => handleGoogleLoginButtonClicked(); 
    
  /// This method is called, whenever the logout button was clicked.
  void onLogoutButtonClicked(event) => handleLogoutButtonClicked(event);  
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Handles the "revealed" event.
  void handleRevealed() {
    // Try to login automatically.
    automaticLogin();
  }
  
  /// Handles a click on the login button. 
  void handleUserBoxToggleClick(event) {
    // Try to login automatically.
    if (isUserBoxHidden()) {
      displayUserBox();
    } else {
      hideUserBox();
    }
  }
  
  /// Handles a click on the login button.
  void handleGoogleLoginButtonClicked() {
    // Perform an explicit login.
    explicitLogin();
  }
  
  /// Handles a click on logout button.
  void handleLogoutButtonClicked(event) {
    retardEvent(event);
    // Perform an explicit login.
    logout();
  }
  
  // ___________________________________________________________________________
  
  /// Unhides the user box.
  void displayUserBox() {
    DivElement userBox = get("user-box");
    DivElement userBoxToggle = get("user-box-toggle");
    
    shadowRoot.ownerDocument.onClick.listen((e) => print("${e.target.id} ${e.target.className}"));
    
    // Positionize the menu body.
    var userBoxToggleBottom = userBoxToggle.getBoundingClientRect().bottom;
    var userBoxToggleLeft = userBoxToggle.getBoundingClientRect().left;
     
    userBox.style.display = "block";
    userBox.style.top = "${userBoxToggleBottom + 2}px";
    userBox.style.left = "${userBoxToggleLeft - 7}px";
  }
  
  /// Unhides the user box.
  void hideUserBox() {
    get("user-box").style.display = "none";
  }
  
  /// Returns true, if the user boy is hidden.
  bool isUserBoxHidden() {
    return get("user-box").style.display == "none";
  }
  
  /// Tries to perform an automatic login (aka check for user in session).
  void automaticLogin() => auth.automaticLogin();
  
  /// Performs an explicit login (where the user types username and password).
  void explicitLogin() => auth.explicitLogin();
  
  /// Performs a logout.
  void logout() => auth.logout();
  
  /// Returns true, if the first argument is a child of second argument.
  bool isChild(child, parent) {    
    if (child != null) {
      if (child == parent) return true;
      var node = child.parentNode;
      while (node != null) {
        if (node == parent) {
          return true;
        }
        node = node.parentNode;
      }
    }
    return false;
  }
}