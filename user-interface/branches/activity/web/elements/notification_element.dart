@MirrorsUsed(targets: 'Notification, NotificationType')
library notification_element;

import 'dart:async';
import 'dart:html' hide Notification;
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import 'package:animation/animation.dart' as animate;
import 'icecite_element.dart';
import '../models/models.dart';

/// The notification of Icecite.
@CustomTag('notification-element')
class NotificationElement extends IceciteElement {  
  /// The notification to show.
  @observable Notification notification;
  
  /// The element wrapping the notification.
  HtmlElement notificationElement;
  /// The element wrapping the message of notification.
  HtmlElement messageElement;
  /// The event listener for on-click event.
  StreamSubscription<MouseEvent> clickListener;
  
  // ___________________________________________________________________________
  
  /// The constructor.
  NotificationElement.created() : super.created();
    
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever the element was revealed.
  void onRevealed() => handleRevealed();
  
  /// This method is called, whenever the hide button was clicked.
  void onHideButtonClicked(event) => handleHideButtonClicked(event);
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Handles the "revealed" event.
  void handleRevealed() {
    this.notificationElement = get("notification");
    this.messageElement = get("message");
  }
  
  /// Handles a click on hide button.
  void handleHideButtonClicked(Event event) {
    retardEvent(event);
    // Hide the notification.
    hideNotification();
  }
      
  // ___________________________________________________________________________
      
  /// Displays the notification.
  void displayNotification(Notification notification) {
    this.notification = notification;
    // Add the click handler if there is any.
    if (notification.onClick != null) {
      messageElement.classes.add("clickable");
      clickListener = notificationElement.onClick.listen(notification.onClick);
    }
    // Animate the notification on displaying.
    var properties = { 'top': '0px' };
    animate.animate(notificationElement, properties: properties, duration: 600);
  }
  
  /// Hides the current notification.
  void hideNotification() {    
    this.notification = null;
    this.messageElement.classes.remove("clickable");
    // Cancel listening to click events.
    if (clickListener != null) clickListener.cancel();
    var properties = { 'top': '-50px' };
    animate.animate(notificationElement, properties: properties, duration: 600);
  }
}