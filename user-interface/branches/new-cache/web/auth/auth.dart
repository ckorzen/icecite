library auth;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'google_oauth2_browser.dart';
import '../models/models.dart';
import '../cache/user_cache.dart';
import '../properties.dart' as prop;
import '../utils/html/cookies_util.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';

/// The authentication manager of Icecite.
class Auth {
  /// The logger.
  Logger LOG = logging.get("auth");
    
  /// The stream controller for login event.
  StreamController<User> loginStream;
  /// The stream controller for logout event.
  StreamController<User> logoutStream;
  
  /// The oAuth2 implementation to login with google account.
  GoogleOAuth2 oAuth2;
  /// The userCache.
  UserCache userCache;
  /// The logged in user.
  User user;
                
  /// The internal constructor.
  Auth._internal() {
    this.loginStream = new StreamController<User>.broadcast();
    this.logoutStream = new StreamController.broadcast();
    this.userCache = new UserCache();
    this.oAuth2 = new GoogleOAuth2(prop.AUTH_OAUTH2_CLIENTID, 
      ["email", prop.AUTH_OAUTH2_USERINFO_SCOPE],
      tokenLoaded: handleTokenLoaded);
  }
      
  // ___________________________________________________________________________
  
  /// Inititalizes this instance of auth.
  Future initialize() {
    return this.userCache.initialize().then((_) {
      initiateLoginFromCookie();
    });
  }
  
  /// Resets this instance of auth.
  void reset() {
    this.userCache.reset();
    this.user = null;
  }
    
  // ___________________________________________________________________________
  // Actions.
  
  /// Performs a oAuth2-login.
  void initiateLogin() {
    LOG.fine("Initiate login.");
    print("initiate login");
    oAuth2.login();
  }
    
  /// Checks, if there is a user in cookies.
  void initiateLoginFromCookie() {
    String cookie = readCookie("user");
    User user = cookie != null ? new User.fromJson(cookie) : null;
    LOG.fine("Initiate Login from cookie. User: $user.");
    if (user != null) handleLogin(user);
  }
  
  /// Performs a logout action.
  void initiateLogout() {
    LOG.fine("Initiate logout of user $user.");
    oAuth2.logout();
    deleteCookie("user");
    logoutStream.add(user);
    reset();
  }
    
  /// Returns true, if there is a logged in user.
  get isLoggedIn => user != null;
  
  /// Returns all known users of the application.
  get users => userCache.values;
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// Handles a loaded token.
  void handleTokenLoaded(Token token) {
    Uri googleUserInfo = Uri.parse(prop.OAUTH2_USERINFO_URL(token.data));
    var request = HttpRequest.getString(googleUserInfo.toString()).then((res) {
      Map<String, dynamic> data = JSON.decode(res);
      
      handleLogin(new User.fromData({
        '_id': token.userId,
        'firstName': data["given_name"],
        'lastName': data["family_name"],
        'email': token.email
      }));
    });
  }
    
  /// Handles a login of given user.
  void handleLogin(User user) {
    LOG.fine("Login of user $user.");
    if (user == null) return;
    
    this.user = user;
    createCookie("user", user.toJson(), 1);
    loginStream.add(user);
    
    // Cache the user, if absent.
    if (!userCache.contains(user)) {
      userCache.addUser(user);
    }
  }
        
  // ___________________________________________________________________________
  // Getters.
   
  /// Returns a stream for login.
  Stream get onLogin => loginStream.stream;

  /// Returns a stream for logout.  
  Stream get onLogout => logoutStream.stream; 
  
  // ___________________________________________________________________________
  
  /// The single instance.
  static Auth _instance;
  
  /// The factory constructor, returning the current instance.
  factory Auth() {
    if (_instance == null) _instance = new Auth._internal();
    return _instance;
  }
}