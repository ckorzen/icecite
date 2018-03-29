@MirrorsUsed(targets: 'Notification,NotificationType')
library icecite_element;

import 'dart:async';
import 'dart:html' hide Notification, Location;
import 'dart:mirrors';
import 'package:polymer/polymer.dart' hide ObservableMap;
import '../auth/auth.dart';
import '../actions/actions.dart';
import '../models/models.dart';
import '../utils/observable_map.dart';
import '../utils/html/location_util.dart';
import '../utils/html/notification_util.dart';

// The base class for all elements and views of Icecite.
abstract class IceciteElement extends PolymerElement {    
  /// The logged-in user.
  @observable User user;
  /// Boolean, which indicates whether the view/element is revealed.   
  @observable bool revealed = false;
  /// The selected entry (as a workaround it is a list, because the single 
  /// library entry isn't updated in view on change - don't know exactly why.)
  @observable LibraryEntry selectedEntry;
  /// The search query.
  @observable String searchQuery;
  /// The id of the selected entry.
  @observable String selectedEntryId;
  
  /// The notification util.
  NotificationUtil notificationUtil;
  /// The actions layer, which includes all caches.
  Actions actions;
  /// The auth manager.
  Auth auth;
   
  // ___________________________________________________________________________
  
  /// The default constructor.
  IceciteElement.created() : super.created();
  
  /// There is a strange bug, where the constructor is called twice. To avoid, 
  /// that the constructor is called twice, initialize all the variables in
  /// enteredView();
  @override
  void attached() {
    super.attached();
        
    // Initialize the cache.
    this.actions = new Actions();    
    // Initialize the auth manager.
    this.auth = new Auth();
    if (auth.isLoggedIn) onLogin(auth.user); 
    this.auth.onLogin.listen((_) => onLogin(auth.user));
    this.auth.onLogout.listen((_) => onLogout());
    this.auth.onAutomaticLoginFailed.listen((_) => onAutomaticLoginFailed());
    
    this.notificationUtil = new NotificationUtil();
    this.notificationUtil.onNotification.listen((n) => onNotification(n));

    // Check the parameters in request.
    Map params = LocationUtil.getUrlParams(window.location.hash);
    this.selectedEntryId = params['id'];
    this.searchQuery = params['q'];

    if (selectedEntryId != null) _fetchSelectedEntry();
  }
   
  /// Abstract method to reset the view.
  void resetOnLogout() {
    this.user = null;
    this.selectedEntry = null;
    this.searchQuery = null;
    if (this.actions != null) this.actions.resetOnLogout();
    if (this.auth != null) this.auth.resetOnLogout();
  }
  
  // ___________________________________________________________________________
  // Display methods.
   
  /// Abstract method to reveal the view.
  void reveal() {
    this.revealed = true;
    // Reveal does some asynchronous work. So wait for it.
    Timer.run(() => onRevealed());
  }
   
  /// Abstract method to unreveal the view.
  void unreveal() {
    this.revealed = false;
  }
     
  // ___________________________________________________________________________
  // Handlers.
    
  /// This method is called, whenever the element is revealed.
  void onRevealed() { }
  
  /// The internal login handler
  void onLogin(User user) {
    this.user = user;
  }
  
  /// The logout handler
  void onLogout() {
    this.user = null;
    resetOnLogout();
  }
    
  /// The automatic login failed event handler.
  void onAutomaticLoginFailed() {}
  
  /// The notification handler.
  void onNotification(NotificationEvent event) {}
  
  /// Handles the given error.
  void errorHandler(e, {LibraryEntry entry}) {
    if (entry != null) {
      Notification n = new Notification(NotificationType.ERROR, e.toString());
      entry.notification = n; 
    }
    print("Error: $e");
  }
  
  // ___________________________________________________________________________
  // Notification methods.
  
  /// Shows success notification. If entry is null, the notification is global.
  void success(String msg, {Pouchable pouchable, Function onClick}) {
    notificationUtil.success(msg, pouchable: pouchable, onClick: onClick);
  }
  
  /// Shows error notification. If entry is null, the notification is global.
  void error(String msg, {Pouchable pouchable, Function onClick}) {
    notificationUtil.error(msg, pouchable: pouchable, onClick: onClick);
  }
  
  /// Shows warn notification. If entry is null, the notification is global.
  void warn(String msg, {Pouchable pouchable, Function onClick}) {
    notificationUtil.warn(msg, pouchable: pouchable, onClick: onClick);
  }
  
  /// Shows info notification. If entry is null, the notification is global.
  void info(String msg, {Pouchable pouchable, Function onClick}) {
    notificationUtil.info(msg, pouchable: pouchable, onClick: onClick);
  }
  
  /// Shows loading notification. If entry is null, the notification is global.
  void loading(String msg, {Pouchable pouchable, Function onClick}) {
    notificationUtil.loading(msg, pouchable: pouchable, onClick: onClick);
  }
      
  // ___________________________________________________________________________
  // Comparators.
      
  /// Returns the comparator for given field.
  static Function getComparator(String field) {
    return (var a, var b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      var x = a[field];
      var y = b[field];
      if (x is Iterable) x = x.isNotEmpty ? x.elementAt(0) : null;
      if (y is Iterable) y = y.isNotEmpty ? y.elementAt(0) : null;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      if (x is String) x = x.toLowerCase();
      if (y is String) y = y.toLowerCase();
      return x.compareTo(y);
    };
  }
  
  // ___________________________________________________________________________
  // Helper methods.
  
  /// Fetches the selected entry. This methods waits until the cache is filled.
  void _fetchSelectedEntry() {
    if (actions.areLibraryEntriesFilled()) {
      selectedEntry = actions.getLibraryEntry(selectedEntryId); 
    } else {
      actions.onLibraryEntriesFilled.listen((_) {
        selectedEntry = actions.getLibraryEntry(selectedEntryId); 
      });
    }
  }
  
  /// Sets the correct css classes of sort fields in (library, feed, references)
  void setSortCssLabel(target, label) {
    if (target != null) {
      target.classes.remove("asc");
      target.classes.remove("desc");
      target.parent.children.forEach((e) => e.classes.remove("asc"));
      target.parent.children.forEach((e) => e.classes.remove("desc"));
      target.classes.add(label); 
    }
  }
  
  /// Prints a log message with date and time to console.
  void log(String s) {
    print("${new DateTime.now()}: $s");
  }
  
  /// Returns the dom element with the given id.
  get(String id) {
    if (shadowRoot != null) {
      Node node = shadowRoot.querySelector(id);
      if (node != null) return node;
      node = shadowRoot.querySelector(".$id");
      if (node != null) return node;
    } else {
      Node node = querySelector(id);
      if (node != null) return node;
      node = querySelector(".$id");
      if (node != null) return node;
    }
    return $[id];
  }
    
  /// Makes value observable.
  static toObservable(value) {
    if (value is Observable) return value;
    if (value is Map) {
      var result = new ObservableMap.createFromType(value);
      value.forEach((k, v) {
        result[toObservable(k)] = toObservable(v);
      });
      return result;
    }
    if (value is Iterable) {
      return new ObservableList.from(value.map(toObservable));
    }
    return value;
  }
  
  /// Stops the propagation of the given event.
  void retardEvent(Event event) {
    if (event == null) return;
    
    // Stop the event propagation, such that no other handlers are affected.
    event.stopPropagation();
    event.preventDefault();
  }
}