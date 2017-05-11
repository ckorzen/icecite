library notification_util;

import 'dart:html' hide Notification;
import 'dart:async';
import '../../models/models.dart';
import '../../views/app_view.dart';
import '../../cache/library_entry_cache.dart';

class NotificationUtil {
  /// The notifications.
  Map<String, Notification> notifications = {};
  /// The internal instance.
  static NotificationUtil _instance;
  
  LibraryEntryCache cache;
  
  /// The stream controller.
  StreamController<NotificationEvent> notificationStream;
  
  /// The factory constructor, returning the current instance.
  factory NotificationUtil() {
    if (_instance == null) _instance = new NotificationUtil._internal();
    return _instance;
  }
  
  /// The internal constructor.
  NotificationUtil._internal() {
    this.notificationStream = new StreamController<NotificationEvent>.broadcast();
  }
  
  void clearNotification() {
    fire(null);
  }
  
  /// Shows success notification. If entry is null, the notification is global.
  void success(String msg, {Pouchable pouchable, Function onClick}) {
    notify(NotificationType.SUCCESS, msg, pouch: pouchable, onClick: onClick);
  }
  
  /// Shows error notification. If entry is null, the notification is global.
  void error(String msg, {Pouchable pouchable, Function onClick}) {
    notify(NotificationType.ERROR, msg, pouch: pouchable, onClick: onClick);
  }
  
  /// Shows warn notification. If entry is null, the notification is global.
  void warn(String msg, {Pouchable pouchable, Function onClick}) {
    notify(NotificationType.WARN, msg, pouch: pouchable, onClick: onClick);
  }
  
  /// Shows info notification. If entry is null, the notification is global.
  void info(String msg, {Pouchable pouchable, Function onClick}) {
    notify(NotificationType.INFO, msg, pouch: pouchable, onClick: onClick);
  }
  
  /// Shows loading notification. If entry is null, the notification is global.
  void loading(String msg, {Pouchable pouchable, Function onClick}) {
    notify(NotificationType.LOADING, msg, pouch: pouchable, onClick: onClick);
  }
  
  /// Shows a notification. If entry is null, the notification will be global.
  void notify(NotificationType type, String msg, {Pouchable pouch,
    Function onClick}) {
    Notification notification = new Notification(type, msg, onClick: onClick);
    if (pouch != null) {
      notifications[pouch.id] = notification;
      pouch.notification = notification;
      notificationStream.add(new NotificationEvent(notification, pouch.id));
    } else {
      fire(notification);
      notificationStream.add(new NotificationEvent(notification));
    }    
  }
  
  /// Hides the notification.
  void unnotify({LibraryEntry pouchable, Node node}) {
    if (pouchable != null) {
      notifications.remove(pouchable.id);
      pouchable.notification = null;
    } else if (node != null) {
      fire(null);
    }
  }
   
  /// Returns the current notification of given entry.
  Notification getNotification(LibraryEntry entry) {
    if (entry == null) return null;
    return notifications[entry.id];
  }
  
  /// Shows the notification globally.
  void fire(Notification notification) {
    Element body = document.querySelector("body");
    AppView appView = null;
    if (body != null) appView = body.querySelector("app-view");
    if (appView == null) appView = document.body.children.first;
    if (appView != null) appView.onNotificationRequest(null, notification);
  }
  
  // ___________________________________________________________________________
  
  /// Returns a stream for notification events.  
  Stream get onNotification => notificationStream.stream;
}

class NotificationEvent {
  Notification notification;
  String pouchId;
  
  NotificationEvent(this.notification, [this.pouchId]);
}