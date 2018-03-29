@MirrorsUsed(targets: 'Notification, NotificationType')
library notification_element;

import 'dart:html' hide Notification;
import "dart:mirrors";
import 'package:polymer/polymer.dart';
import 'package:animation/animation.dart' as animate;
import 'icecite_element.dart';
import '../models/models.dart';

/// The notification of Icecite.
@CustomTag('notification-element')
class NotificationElement extends IceciteElement {  
  @observable Notification notification;
  
  NotificationElement.created() : super.created();
    
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/notification_element.css"));
  }
  
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// This method is called, whenever the close button was clicked.
  void onHidePurpose(event, details, target) => hide();
  
  // ___________________________________________________________________________
  // Display methods.
  
  /// Displays the given notification.
  void display(Notification notification) {
    this.notification = notification;
    
    // Reset the top-property to the default value.
    DivElement container = get("notification");
    container.style.top = "";
    // Add the click handler if there is any.
    if (notification.onClick != null) {
      get("short").classes.add("clickable");
      container.onClick.listen(notification.onClick);
    }
    
    /// Animate the notification on displaying.
    var properties = { 'top': '0px' };
    animate.animate(container, properties: properties, duration: 600);
  }
  
  /// Hides the current notification.
  void hide() {    
    DivElement container = get("notification"); 
    var properties = { 'top': '-50px' };
    animate.animate(container, properties: properties, duration: 600);
  }
}