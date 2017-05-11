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
  /// Observable variables.
  @published Notification notification;
  
  /// Internal variables.
  LoginElement loginElement;
  NotificationElement notificationElement;
  
  /// The default constructor.
  HeaderView.created() : super.created();
  
  // ___________________________________________________________________________
  // Handlers.
     
  /// This method is called, whenever the view was revealed.
  void revealedHandler() {
    super.revealedHandler();
    this.notificationElement = get("notification-element");
    this.loginElement = get("login-element");
    this.loginElement.reveal(); // Show login element per default.
  }
  
  // ___________________________________________________________________________
  // Display actions.
  
  /// Displays the given Notification.
  void showNotification(Notification notification) {
    // Propagate the notification to the notification widget. 
    notificationElement.display(notification);
  }
}