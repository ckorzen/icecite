library app_view;

import 'package:polymer/polymer.dart';
import 'header_view.dart';
import 'main_view.dart';
import 'navigation_view.dart';
import 'welcome_view.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';

/// The Icecite application.
@CustomTag('app-view')
class AppView extends IceciteElement {   
  /// The secondary views.
  WelcomeView welcomeView;
  HeaderView headerView;
  NavigationView navigationView;
  MainView mainView;
    
  /// The default constructor.
  AppView.created() : super.created();
      
  // Overrides.
  void enteredView() {    
    super.enteredView();  
    // Reveal the view, when the user cache was filled.
    if (actions.areUsersFilled()) reveal();
    this.actions.onUsersFilled.listen((_) => reveal());
  }
  
  /// This method is called, whenever the view was revealed.
  void revealedHandler() {
    super.revealedHandler();
    this.headerView = get("header-view");
    this.navigationView = get("navigation-view");
    this.mainView = get("main-view");
    this.welcomeView = get("welcome-view");
    this.headerView.reveal();
    this.navigationView.reveal();
    this.welcomeView.reveal();
  }
    
  // ___________________________________________________________________________
  // Handlers.
           
  /// This method is called, whenever a login event occurs.
  void loginHandler(User user) {
    super.loginHandler(user);
    welcomeView.unreveal();
    mainView.reveal();
    cacheUser(user);
  }
        
  /// This method is called, whenever a login event occurs.
  void logoutHandler() {
    info("You have been successfully logged out.");
    welcomeView.reveal();
    mainView.unreveal();
    super.logoutHandler();    
  }
   
  /// This method is called, whenever the selection of topics has changed.
  void topicsSelectedHandler(event, detail, target) {
    mainView.topicsSelectedHandler(event, detail, target);
  }
     
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// This method is called, whenever file(s) were uploaded.
  void onUploadFilesPurpose(event, files, target) {
    mainView.onUploadFilesPurpose(event, files, target);
  }
  
  /// This method is called, whenever file(s) were uploaded.
  void onUrlUploadPurpose(event, url, target) {
    mainView.onUrlUploadPurpose(event, url, target);
  }
      
  /// Define behavior on notification.
  void onNotificationPurpose(event, notification, target) {
    headerView.showNotification(notification);
  }
   
  /// Will select the given entry.
  void onSelectLibraryEntryPurpose(event, entry, target) {
    navigationView.onSelectLibraryEntryPurpose(event, entry, target);
    mainView.onSelectLibraryEntryPurpose(event, entry, target);
  }  
  
  /// Will select the given entry.
  void onSelectHistoryEntryPurpose(event, entry, target) {
    mainView.onSelectLibraryEntryPurpose(event, entry, target);
  }
    
  // ___________________________________________________________________________
  // Actions.
        
  /// Initializes the logged in user, i.e. makes sure, that user is cached. 
  void cacheUser(User user) {
    actions.cacheUserIfAbsent(user);
  }
}