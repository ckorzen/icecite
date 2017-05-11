library app_view;

import 'dart:async';
import 'dart:html' hide Notification;
import 'dart:collection';
import 'package:polymer/polymer.dart';
import 'header_view.dart';
import 'main_view.dart';
import 'welcome_view.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';

/// The Icecite application.
@CustomTag('app-view')
class AppView extends IceciteElement {     
  /// The welcome view.
  WelcomeView welcomeView;
  /// The header view.
  HeaderView headerView;
  /// The main view.
  MainView mainView;
  /// The navigation view.
  /// NavigationView navigationView;
  Element historyWindow;  
  
  int historyIndex = 0;
  Queue<LibraryEntry> history;
  Timer historyTimer;
  static const int historyMaxSize = 5; // TODO: Properties.
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  AppView.created() : super.created() {
    this.history = new Queue<LibraryEntry>();
  }
      
  @override
  void attached() {
    super.attached();
    // Reveal the view, when the user cache was filled.
    if (actions.areUsersFilled()) reveal();
    this.actions.onUsersFilled.listen((_) => reveal());
     
    // Listen for key-down events.
    window.onKeyDown.listen((evt) {      
      var cmd = (evt.ctrlKey ? 1 : 0) |
        (evt.altKey ? 2 : 0) |
        (evt.shiftKey ? 4 : 0) |
        (evt.metaKey ? 8 : 0);
                       
      if (cmd == 4) { // shift
        switch (evt.keyCode) {
          case 9: // tab
            onScrollHistoryStartRequest(evt);
            break;
          case 37: // left arrow.
            onPreviousViewRequest(evt);
            break;
          case 38: // up arrow
            onPreviousEntryRequest(evt);
            break;
          case 39: // right arrow.
            onNextViewRequest(evt);
            break;
          case 40: // down arrow
            onNextEntryRequest(evt);
            break;
          case 122: // F11.
            onFullscreenToggleRequest(evt);
            break;
          default:
            break;
          }
       }
    });

    // Listen for key-up events.
    window.onKeyUp.listen((evt) {      
      switch (evt.keyCode) {
        case 16: // shift
          onScrollHistoryEndRequest(evt);
          break;
        default:
          break;
      }
    });
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  @override
  void onRevealed() => handleRevealed();
               
  @override
  void onLogin(User user) => handleLogin(user);
      
  @override 
  void onAutomaticLoginFailed() => handleAutomaticLoginFailed();
  
//  void onLogoutRequest() => auth.logout();
  
  @override
  void onLogout() => handleLogout();
       
  /// This method is called, whenever at least one topic was selected.
  void onTopicsSelected(event, topicIds) => handleTopicsSelected(event, topicIds); 
  
  /// This method is called, whenever file(s) were selected for upload.
  void onFilesUpload(event, files) => handleFilesUpload(event, files);
  
  /// This method is called, whenever an url to file to upload was entered.
  void onUrlUpload(event, url) => handleUrlUpload(event, url); 
      
  /// This method is called, whenever there is a notification to show.
  void onNotificationEvent(event, n) => handleNotification(event, n);
   
  /// This method is called, whenever a library entry was selected.
  void onLibraryEntrySelected(event, detail) => 
      handleLibraryEntrySelected(event, detail);
  
  /// Will select the given entry.
  void onHistoryEntrySelected(event, entry) => 
      handleHistoryEntrySelected(event, entry);
        
  /// This method is called, whenever the google login button was clicked.
  void onGoogleLoginButtonClicked(evt) => handleGoogleLoginButtonClicked(evt);
  
  /// This method is called, whenever a prev-entry request occurs.
  void onPreviousEntryRequest(evt) => handlePreviousEntryRequest(evt);
  
  /// This method is called, whenever a next-entry request occurs.
  void onNextEntryRequest(evt) => handleNextEntryRequest(evt);
  
  /// This method is called, whenever a scroll-history-start request occurs.
  void onScrollHistoryStartRequest(evt) => handleScrollHistoryStartRequest(evt);
  
  /// This method is called, whenever a scroll-history-end request occurs.
  void onScrollHistoryEndRequest(evt) => handleScrollHistoryEndRequest(evt);
   
  void onPreviousViewRequest(evt) => handlePreviousViewRequest(evt);
  
  void onNextViewRequest(evt) => handleNextViewRequest(evt);
  
  void onFullscreenToggleRequest(evt) => handleFullscreenToggleRequest(evt);
  
  void onClikk(e, d, t) => print(t);
  
  // ___________________________________________________________________________
  // Actions.
    
  /// Handles revealed event.
  void handleRevealed() {
    headerView = get("header-view");
//    navigationView = get("navigation-view");
    mainView = get("main-view");
    welcomeView = get("welcome-view");
    headerView.reveal();
    historyWindow = get("history-window");
//    navigationView.reveal();
  }
  
  /// Handles a login event.
  void handleLogin(User user) {
    this.user = user;
    // Reveal the main view.
    revealMainView();
    // Cache the user, if it is absent in cache.
    cacheUserIfAbsent(user);
  }
  
  /// Handles a automatic login failed event.
  void handleAutomaticLoginFailed() {
    /// Reveal the welcome view.
    revealWelcomeView();
  }
    
  /// Handles a logout event.
  void handleLogout() {
    this.user = null;
    resetOnLogout(); 
    // Reveal the welcome view.
    revealWelcomeView(); 
    notificationUtil.info("You have been successfully logged out.");
  }
  
  /// Handles the selection of topics.
  void handleTopicsSelected(Event event, Iterable topicIds) {
    retardEvent(event);
    // Propagate the event to mainView.
    mainView.onTopicsSelected(topicIds);
  }

  /// Handles the upload of files.
  void handleFilesUpload(Event event, Iterable files) {
    retardEvent(event);
    // Propagate the event to mainView.
    mainView.onFilesUpload(files);
  }
  
  /// Handles the upload via url.
  void handleUrlUpload(Event event, String url) {
    retardEvent(event);
    // Propagate the event to mainView.
    mainView.onUrlUpload(url);
  }  
  
  /// Handles a notification.
  void handleNotification(Event event, Notification notification) {
    retardEvent(event);
    // Propagate the event to headerView.
    headerView.onNotificationEvent(notification);
  }   
  
  /// Handles a selection of library entry.
  void handleLibraryEntrySelected(Event event, Map detail) {
    retardEvent(event);
    LibraryEntry entry = detail['entry'];
    historyPush(entry);    
    mainView.onLibraryEntrySelected(entry);
  }   
 
  /// Handles a selection of a history entry.
  void handleHistoryEntrySelected(Event event, Map detail) {
    retardEvent(event);
    // Propagate the event to mainView.
    mainView.onLibraryEntrySelected(detail['entry']);
  }   
    
  /// Handles a click on google login button.
  void handleGoogleLoginButtonClicked(Event event) {
    retardEvent(event);
    headerView.onGoogleLoginButtonClicked();
  }
  
  /// Handles a previous-entry request.
  void handlePreviousEntryRequest(Event event) {
    retardEvent(event);
    mainView.onPreviousEntryRequest();
  }
  
  /// Handles a next-entry request.
  void handleNextEntryRequest(Event event) {
    retardEvent(event);
    mainView.onNextEntryRequest();
  }
  
  /// Handles a scroll-history-start request.
  void handleScrollHistoryStartRequest(Event event) {
    retardEvent(event);   
    scrollInHistory();
  }
  
  /// Handles a scroll-history-end request.
  void handleScrollHistoryEndRequest(Event event) {
    retardEvent(event);   
    selectCurrentHistoryElement();
  }
      
  void handlePreviousViewRequest(Event event) {
    retardEvent(event);   
    mainView.onPreviousViewRequest();
  }
  
  void handleNextViewRequest(Event event) {
    retardEvent(event);   
    mainView.onNextViewRequest();
  }
  
  void handleFullscreenToggleRequest(Event event) {
    retardEvent(event);   
    mainView.onFullscreenToggleRequest();
  }
  
  // ___________________________________________________________________________
  
  /// Reveals the welcome view and unreveals the main view.
  void revealWelcomeView() {
    welcomeView.reveal();
    mainView.unreveal();
  }
  
  /// Reveals the main view and unreveals the welcome view.
  void revealMainView() {
    welcomeView.unreveal();
    mainView.reveal();
  }
  
  /// Scrolls the history.
  void scrollInHistory() {
    // Display the history window, if it is hidden.
    if (isHistoryWindowHidden()) {
      displayHistoryWindow();
    }
  
    // The history window can still be hidden, (e.g. if the history is empty).
    if (!isHistoryWindowHidden()) {
      // Scroll.
      blurHistoryElement(historyIndex);
      historyIndex = (historyIndex + 1) % history.length;
      focusHistoryElement(historyIndex);
    }
  }
  
  /// Displays and fills the history window.
  void displayHistoryWindow() {
    historyWindow.children.clear();
    if (history.length > 1) {
      for (int i = 0; i < history.length; i++) {
        var libraryEntry = history.elementAt(i);
        var historyElement = document.createElement('div');
        historyElement.className = "history-entry";
        
        var entryTitle = document.createElement('div');
        entryTitle.className = "title";
        entryTitle.text = libraryEntry.title;
        historyElement.append(entryTitle);
        
        var entryAuthors = document.createElement('div');
        entryAuthors.className = "authors";
        entryAuthors.text = libraryEntry.authorsStr;
        historyElement.append(entryAuthors);
        
        var entryVenue = document.createElement('div');
        entryVenue.className = "venue";
        entryVenue.text = "${libraryEntry.journal} ${libraryEntry.year}";
        historyElement.append(entryVenue);
        
        historyWindow.append(historyElement);
      }
        
      historyWindow.style.display = "block";
      
      /// Adjust the margin-top, such that the window is centered vertically. 
      var computedStyle = historyWindow.getComputedStyle();
      String computedHeight = computedStyle.height.replaceAll('px', '');
      String top = "${-1 * int.parse(computedHeight) / 2}px";
      historyWindow.style.marginTop = top;
    }
  }
  
  /// Hides the history window.
  void hideHistoryWindow() {      
    historyWindow.style.display = "none";
    historyIndex = 0;
  }
  
  /// Returns true, if the history window is hidden. False otherwise.
  bool isHistoryWindowHidden() {
    return historyWindow.style.display == "none";
  }
  
//  /// Creates a new history timer, if none is available or extend the timer, if
//  /// one is available.
//  void pingHistoryTimer(seconds, callback) {
//    // Start (or extend) the timer, which closes the historyWindow. 
//    if (historyTimer != null) historyTimer.cancel();
//    historyTimer = new Timer(new Duration(seconds: seconds), callback);
//  }
  
  /// Selects the history element at given index.
  void selectCurrentHistoryElement() {
    if (historyIndex > -1 && historyIndex < history.length) {
      onLibraryEntrySelected(null, {'entry': history.elementAt(historyIndex)});
    }
    hideHistoryWindow();
  }
  
  /// Blurs the history entry at given index.
  void blurHistoryElement(int index) {
    Element historyElement = getHistoryElement(index);
    if (historyElement != null) {
      historyElement.classes.remove("focused");
    }
  }
  
  /// Blurs the history entry at given index.
  void focusHistoryElement(int index) {
    Element historyElement = getHistoryElement(index);
    if (historyElement != null) {
      historyElement.classes.add("focused");
    }
  }
  
  /// Returns the history element at given index.
  Element getHistoryElement(int index) {
    if (index > -1) {
      var historyEntries = historyWindow.children;
      if (index < historyEntries.length) {
        return historyEntries[index];
      }
    }
    return null;
  }
  
  void historyPush(LibraryEntry entry) {
    // Delete the entry from history, if it contains the entry (so that the 
    // entry isn't contained twice).
    if (history.contains(entry)) {
      history.remove(entry);
    }
      
    history.addFirst(entry);
      
    // Ensure, that the size of history doesn't exceed the max size.
    while (history.length > historyMaxSize) {
      history.removeLast();
    }
  }
  
  // ___________________________________________________________________________
  
  /// Initializes the logged in user, i.e. makes sure, that the user is cached. 
  void cacheUserIfAbsent(User user) => actions.cacheUserIfAbsent(user);
}