library auth;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'google_oauth2_browser.dart';
import '../models/models.dart';
import '../properties.dart' as prop;
import '../utils/html/cookies_util.dart';

/// The authentication manager of Icecite.
class Auth {
  /// The oAuth2 authentication.
  static GoogleOAuth2 oAuth2;
  /// The internal instance.
  static Auth _instance;
  
  /// The stream controller for login event.
  StreamController<User> loginStream;
  /// The stream controller for logout event.
  StreamController<User> logoutStream;
  /// The stream controller for "automatic-login-failed" event.
  StreamController<User> automaticLoginFailedStream;
  
  /// Flag to identify, if there is a logged in user.
  bool isLoggedIn;
    
  /// The factory constructor, returning the current instance.
  factory Auth() {
    if (_instance == null) _instance = new Auth._internal();
    return _instance;
  }
  
  /// The internal constructor.
  Auth._internal() {
    this.isLoggedIn = false;
    this.loginStream = new StreamController<User>.broadcast();
    this.logoutStream = new StreamController.broadcast();
    this.automaticLoginFailedStream = new StreamController.broadcast();
    oAuth2 = new GoogleOAuth2(
      prop.AUTH_OAUTH2_CLIENTID, 
      ["email", prop.AUTH_OAUTH2_USERINFO_SCOPE],
      tokenLoaded: tokenLoadedHandler);
  }
    
  /// Resets the auth.
  void resetOnLogout() {}
  
  // ___________________________________________________________________________
  // Handlers.
  
  // Handles a loaded token.
  void tokenLoadedHandler(Token token) {
    Uri googleUserInfo = Uri.parse(prop.OAUTH2_USERINFO_URL(token.data));
    var request = HttpRequest.getString(googleUserInfo.toString()).then((res) {
      Map<String, dynamic> data = JSON.decode(res);
      
      User user = new User(token.userId)
        ..firstName = data["given_name"]
        ..lastName = data["family_name"]
        ..email = token.email;
      createCookie("user", user.toJson(), 1);
      fireLoginEvent(user);
    });
  }
  
  // ___________________________________________________________________________
  // Getters.
  
  /// Returns true, if there is an authenticated user.
  User get user {
    // Check, if there is a user stored in cookies.
    String cookie = readCookie("user");
    return cookie != null ? new User.fromJson(cookie) : null;
  }

  /// Returns a stream for login.
  Stream get onLogin => loginStream.stream;

  /// Returns a stream for logout.  
  Stream get onLogout => logoutStream.stream; 
  
  /// Returns a stream to listen for event "automatic-login-failed".  
  Stream get onAutomaticLoginFailed => automaticLoginFailedStream.stream; 
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Checks, if there is an user in browser cache and fires login event if so.
  void automaticLogin() {
    User user = this.user;
    if (user == null) {
      fireAutomaticLoginFailedEvent();
      return;
    }
    new Timer(new Duration(milliseconds: 50), () {
      fireLoginEvent(user); 
    });      
  }
  
  /// Fires a login event.
  void fireLoginEvent(User user) {
    Timer.run(() {
      loginStream.add(user);
      isLoggedIn = true;
    });
  }
  
  /// Fires an automatic login failed event.
  void fireAutomaticLoginFailedEvent() {
    automaticLoginFailedStream.add(null);
  }
  
  /// Performs a oAuth2-login.
  void explicitLogin() {
    oAuth2.login();
  }
    
  /// Performs a logout action.
  void logout() {
    oAuth2.logout();
    deleteCookie("user");
    logoutStream.add(null);
    isLoggedIn = false;
  }
  
  // ___________________________________________________________________________
}