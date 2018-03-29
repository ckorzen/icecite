@MirrorsUsed(targets: 'Notification,NotificationType')
library header_view;

import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../elements/login_element.dart';
import '../elements/notification_element.dart';

/// The header of Icecite.
@CustomTag('header-view')
class HeaderView extends IceciteElement { 
  /// Boolean, indicating, whether the logo is displayed.
  @observable bool showLogo = false;

  /// The login element.
  LoginElement loginElement;
  /// The notification element.
  NotificationElement notificationElement;
    
  // ___________________________________________________________________________
  
  /// The default constructor.
  HeaderView.created() : super.created();
  
  @override
  void reset() {
    super.reset();
    this.showLogo = false;
  }
  
  // ___________________________________________________________________________
  // Listener methods.
    
  @override
  void onLogin(User user) => handleLogin(user);
  
  @override
  void onLogout() => handleLogout();
  
  @override
  void onRevealed() => handleRevealed();
          
  // ___________________________________________________________________________
  // Handler methods.
   
  /// Handles a login event.
  void handleLogin(User user) {
    super.onLogin(user);
    showLogo = true;
  }
  
  /// Handles a logout event.
  void handleLogout() {
    super.onLogout();
    showLogo = false;
  }
  
  /// Handles the revealed event.
  void handleRevealed() {
    this.notificationElement = get("notification-element");
    this.loginElement = get("login-element");
    if (notificationElement != null) notificationElement.reveal();
    if (loginElement != null) loginElement.reveal();
  }
  
  // ___________________________________________________________________________
  
  /// Handles a notification.
  void showNotification(Notification notification) {
    if (notification != null) { 
      revealNotification(notification);
    } else {
      unrevealNotification();
    }
  }
  
  /// Reveals the given notification.
  void revealNotification(Notification notification) {
    notificationElement.displayNotification(notification);
  }
  
  /// Unreveals the notification.
  void unrevealNotification() {
    notificationElement.hideNotification();
  }
  
  /// Handles a click on google login button.
  void googleLogin() {
    loginElement.onGoogleLoginButtonClicked();
  }
}