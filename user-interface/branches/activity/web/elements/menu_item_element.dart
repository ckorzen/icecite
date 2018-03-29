library menu_item_element;

import 'dart:html' hide Notification;
import '../models/models.dart';
import 'icecite_element.dart';
import 'package:polymer/polymer.dart';

@CustomTag('menu-item-element')
class MenuItemElement extends IceciteElement {         
  @published String type;
  
  /// The default constructor.
  MenuItemElement.created() : super.created();
  
  Map<NotificationType, String> notificationClasses = {
    NotificationType.ERROR: "error", 
    NotificationType.INFO: "info", 
    NotificationType.LOADING: "loading", 
    NotificationType.SUCCESS: "success",
    NotificationType.WARN: "warn"
  };
  
  Map<NotificationType, String> notificationIconSources = {
    NotificationType.ERROR: "images/error.png", 
    NotificationType.INFO: "images/info.png", 
    NotificationType.LOADING: "images/loading.gif", 
    NotificationType.SUCCESS: "images/success.png",
    NotificationType.WARN: "images/warn.png"
  };
  
  @override
  ready() {
    DivElement menuItem = get("menu-item");
    // Add classname "active" on mousedown.
    this.onMouseDown.listen((e) => menuItem.classes.add("active"));
    // Remove classname "active" on mouseup. 
    this.onMouseUp.listen((e) => menuItem.classes.remove("active"));
  }
  
  setNotification(Notification notification) {
    DivElement menuItem = get("menu-item");
    menuItem.classes.removeAll(notificationClasses.values);
    menuItem.classes.add(notificationClasses[notification.type]);
        
    menuItem.children.clear();
    ImageElement img = document.createElement("img");
    img.src = notificationIconSources[notification.type];
    menuItem.append(img);
        
    SpanElement span = document.createElement("span");
    span.text = notification.short;
    menuItem.append(span);
  }
  
  void disable() {
    get("menu-item").classes.add("disabled");
  }
}