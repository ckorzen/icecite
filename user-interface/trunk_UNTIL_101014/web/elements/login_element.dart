library login_element;

import 'package:polymer/polymer.dart';
import 'icecite_element.dart';

/// The login of Icecite.
@CustomTag('login-element')
class LoginElement extends IceciteElement {
  
  /// The default constructor.
  LoginElement.created() : super.created();

  /// Override.
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/login_element.css"));
    
    // Try to perform an automatic login.
    auth.automaticLogin();
  }
      
  // ___________________________________________________________________________
  // On purpose methods.
  
  /// Will login the user.
  void onLoginPurpose(event, detail, target) => auth.explicitLogin(); 
    
  /// Will cancel the user login.
  void onLogoutPurpose(event, detail, target) => auth.logout();       
}