library app_view;

import 'header_view.dart';
import 'main_view.dart';
import 'welcome_view.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

/// The Icecite application.
@CustomTag('app-view')
class AppView extends IceciteElement {           
  /// The logger.
  Logger LOG = logging.get("app-view");
  
  /// The welcome view.
  WelcomeView welcomeView;
  /// The header view.
  HeaderView headerView;
  /// The main view.
  MainView mainView;
         
  /// The default constructor.
  AppView.created() : super.created();
      
  @override
  void attached() {
    super.attached();
        
    this.headerView = get("header-view");
    this.mainView = get("main-view");
    this.welcomeView = get("welcome-view");    
    this.headerView.reveal(); // TODO
    
    auth.initialize().then((_) {
      if (auth.isLoggedIn) {
        revealMainView();
      } else {
        revealWelcomeView();
      }
    });
  }
     
  // ___________________________________________________________________________
  // Listener methods.
  
  @override
  void onLogin(User user) => handleLogin(user);
          
  @override
  void onLogout() => handleLogout();
      
  /// This method is called, whenever there is a notification to show.
  void onNotificationRequest(evt, data) => handleNotificationRequest(data);
             
  /// This method is called, whenever the google login button was clicked.
  void onGoogleLoginRequest(evt) => handleGoogleLoginRequest();
      
  // ___________________________________________________________________________
  // Handler methods.
       
  /// Handles a login event.
  void handleLogin(User user) {
    super.onLogin(user);
    revealMainView();
  }
  
  /// Handles a logout event.
  void handleLogout() {
    super.onLogout();
    revealWelcomeView(); 
    info("You have been successfully logged out.");
  }
  
  /// Handles a notification.
  void handleNotificationRequest(Notification notification) {
    // Propagate the event to headerView.
    headerView.showNotification(notification);
  } 
  
  /// Handles a click on google login button.
  void handleGoogleLoginRequest() {
    headerView.googleLogin();
  }
  
  // ___________________________________________________________________________
  
  /// Reveals the welcome view and unreveals the main view.
  void revealWelcomeView() {
    welcomeView.reveal();
    welcomeView.style.display = "block"; // TODO 
    mainView.unreveal();
    mainView.style.display = "none"; // TODO 
  }
  
  /// Reveals the main view and unreveals the welcome view.
  void revealMainView() {
    welcomeView.unreveal();
    welcomeView.style.display = "none"; // TODO 
    mainView.reveal();
    mainView.style.display = "block"; // TODO
  }
}