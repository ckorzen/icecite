library login_element;

import 'dart:html';
import 'package:polymer/polymer.dart';
import '../models/models.dart';
import 'icecite_element.dart';

/// The login of Icecite.
@CustomTag('login-element')
class LoginElement extends IceciteElement {
  /// The default constructor.
  LoginElement.created() : super.created();
      
  // ___________________________________________________________________________
  // Handlers.
    
  /// This method is called, whnever the toggle box was clicked.
  void onUserBoxToggleClick(event) => handleUserBoxToggleClick(event);
  
  /// This method is called, whenever the google-login button was clicked.
  void onGoogleLoginButtonClicked() => handleGoogleLoginButtonClicked(); 
    
  /// This method is called, whenever the logout button was clicked.
  void onLogoutButtonClicked(event) => handleLogoutButtonClicked(event); 
  
  /// This method is called, whenever a mousedown event occurs in logout button.
  void onLogoutButtonMousedown(event) => handleLogoutButtonMousedown(event);
  
  void onUserBoxBlur(event) => handleUserBoxBlur(); 
  
  // ___________________________________________________________________________
  // Actions.
    
  /// Handles a click on the login button. 
  void handleUserBoxToggleClick(event) {
    displayUserBox();
    get("user-box").focus();
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
  
  void handleLogoutButtonMousedown(event) {
    retardEvent(event);
  }
  
  void handleUserBoxBlur() {
    hideUserBox();
  }
  
  // ___________________________________________________________________________
  
  /// Unhides the user box.
  void displayUserBox() {
    DivElement userBox = get("user-box");
    DivElement userBoxToggle = get("user-box-toggle");
        
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
  
  /// Performs an explicit login (where the user types username and password).
  void explicitLogin() => auth.initiateLogin();
  
  /// Performs a logout.
  void logout() => auth.initiateLogout();
}