library welcome_view;

import 'package:polymer/polymer.dart';
import '../elements/icecite_element.dart';

/// The navigation of Icecite.
@CustomTag('welcome-view')
class WelcomeView extends IceciteElement {
  static const String GOOGLE_LOGIN_REQUEST = "google-login-request";
  
  /// The default constructor.
  WelcomeView.created() : super.created();
  
  // ___________________________________________________________________________
  
  /// This method is called, whenever the login button was clicked.
  void onGoogleLoginButtonClicked(evt) => handleGoogleLoginButtonClicked(evt); 
  
  // ___________________________________________________________________________
  
  /// Handles a click on google login button.
  void handleGoogleLoginButtonClicked(event) {
    retardEvent(event);
    print("google login button clicked");
    fireGoogleLoginRequest();
  }
  
  // ___________________________________________________________________________
  
  /// Fire a google-login-button-clicked event.
  void fireGoogleLoginRequest() {
    fire(GOOGLE_LOGIN_REQUEST);
  }
}