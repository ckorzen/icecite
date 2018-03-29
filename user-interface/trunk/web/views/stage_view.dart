@MirrorsUsed(targets: 'LibraryEntry,Notification,NotificationType')
library stage_view;

import 'dart:async';
import 'dart:html' hide Notification, Location;
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import 'library_view.dart';
import 'references_view.dart';
import 'feed_view.dart';
import '../actions/actions.dart';
import '../models/models.dart';
import '../elements/menu_item_element.dart';
import '../elements/icecite_element.dart';
import '../elements/upload_element.dart';
import '../utils/html/location_util.dart';

/**
 * This is the area, where all the main functionality of Icecite is placed. 
 * The stage includes the library, the references and the feed.
 */
@CustomTag('stage-view')
class StageView extends IceciteElement {
  /// The current location.
  @observable Location location;
  /// The classes of library tab.
  @observable String libraryTabClasses;
  /// The activity counter of library.
  @observable int libraryActivityCounter;
  /// The classes of references tab.
  @observable String referencesTabClasses;
  /// The classes of feeds tab.
  @observable String feedsTabClasses;
  /// The search query.
  @observable String searchQuery;
   
  /// The library view.
  LibraryView libraryView;
  /// The library tab.
  HtmlElement libraryTab;
//  /// The references view.
//  ReferencesView referencesView;
//  /// The references tab.
//  HtmlElement referencesTab;
//  /// The library view.
//  FeedView feedView;
//  /// The feed tab.
//  HtmlElement feedTab;
  /// The uploader.
  UploadElement uploadElement;
  
  // The name of "entry-selected" event 
  static const String EVENT_ENTRY_SELECTED = "entry-selected";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  StageView.created() : super.created() {
  }
    
  @override
  void attached() {
    super.attached();
    actions.onActivity.listen(onActivity);
  }
  
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    this.location = null;
    this.libraryTabClasses = null;
    this.referencesTabClasses = null;
    this.feedsTabClasses = null;
    this.libraryActivityCounter = 0;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  @override
  void onRevealed() => handleRevealed();
  
  /// This method is called, whenever the location has changed.
  void locationChanged(prevLocation) => handleLocationChange(prevLocation);
                 
  /// This method is called, whenever an entry was deleted.
  void onLibraryEntryDeleted(evt, entr) => handleLibraryEntryDeleted(evt, entr);
    
  /// This method is called, whenever there is an activity.
  void onActivity(activity) => handleActivity(activity);
      
//  /// This method is called, whenever the library tab was clicked.
//  void onLibraryTabClicked(event) => handleLibraryTabClicked(event);
//     
//  /// This method is called, whenever the entry tab was clicked.
//  void onReferencesTabClicked(event) => handleReferencesTabClicked(event);
//  
//  /// This method is called, whenever the feed tab was clicked.
//  void onFeedTabClicked(event) => handleFeedTabClicked(event);
  
  /// This method is called, whenever a search was started.
  void onSearchQueryTyped(event) => handleSearchQueryTyped(event);
  
  /// This method is called, whenever a search was cancelled.
  void onSearchCancelled(event) => handleSearchCancelled(event);
  
  /// Will import the given entry.
  void onImportedFromPdf(entry) => handleImportedFromPdf(entry);
  
  /// This method is called, whenever an entry was selected.
  void onLibraryEntrySelected(LibraryEntry entry) => 
      handleLibraryEntrySelected(entry);
  
//  /// This method is called, whenever an entry was selected.
//  void onFeedViewSelected(evt, detail) => handleFeedViewSelected(evt, detail);
  
  /// This method is called, whenever the selection of topics has changed.
  void onTopicsSelected(topicIds) => handleTopicsSelected(topicIds);
  
  /// This method is called, whenever files were uploaded.
  void onFilesUpload(event, files) => handleFilesUpload(files); 
  
  /// This method is called, whenever there is an url for upload.
  void onUrlUpload(event, url) => handleUrlUpload(url); 

  /// This method is called, whenever a download was requested for an entry.
  void onDownloadRequest(event, detail) => handleDownloadRequest(event, detail);
       
  /// This method is called, whenever a previous-entry-request occurs.
  void onPreviousEntryRequest() => handlePreviousEntryRequest();
  
  /// This method is called, whenever a next-entry-request occurs.
  void onNextEntryRequest() => handleNextEntryRequest();
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Reveals the elements of this view.
  void handleRevealed() {
    this.libraryTab = get("library-tab");
//    this.referencesTab = get("references-tab");
//    this.feedTab = get("feed-tab");
    this.libraryView = get("library-view");    
//    this.referencesView = get("references-view");
//    this.feedView = get("feed-view");
    this.libraryActivityCounter = 0;
    this.location = LocationUtil.getLocation(window.location.hash);
    if (searchQuery != null) handleSearchQueryTyped(null);
    
    this.uploadElement = get("upload-element");
    this.uploadElement.reveal();
  }
   
  /// Handles the change of location.
  void handleLocationChange(Location prevLocation) {
    // Change the location.
    applyLocationChange(prevLocation);
  }

  /// Displays the library view, when the deleted entry is equal to the selected
  void handleLibraryEntryDeleted(Event event, LibraryEntry entry) {
    retardEvent(event);
    
    if (selectedEntryId != entry.id) return;
    // Clear the selectedEntryId, if its equal to the id of deleted entry.
    selectedEntryId = null;
//    setLocation(Location.LIBRARY, resetSearchQuery: true);
    // Update the tabs.
//    updateTabs();
    notificationUtil.info("The selected entry was deleted.");
  }
    
  /// Handles an activity. 
  void handleActivity(Activity activity) {
//    if (location == Location.LIBRARY) return;
//    if (location == Location.UNKNOWN) return;
    libraryActivityCounter++;
  }
    
//  /// Handles a click on library tab.
//  void handleLibraryTabClicked(Event event) {
//    retardEvent(event);
//    setLocation(Location.LIBRARY, resetSearchQuery: true);
//    libraryActivityCounter = 0;
//  }
  
//  /// Handles a click on references tab.
//  void handleReferencesTabClicked(Event event) {
//    retardEvent(event);
//    if (selectedEntryId == null) return;
//    setLocation(Location.REFERENCES, resetSearchQuery: true);
//  }
  
//  /// Handles a click on feed tab.
//  void handleFeedTabClicked(Event event) {
//    retardEvent(event);
//    if (selectedEntryId == null) return;
//    setLocation(Location.FEED, resetSearchQuery: true);
//  }
//  
  /// Handles the selection of a library entry.
  void handleLibraryEntrySelected(LibraryEntry entry) {
    if (entry.brand != 'entry') return;
    this.selectedEntryId = entry.id;
    // Propagate the event to libraryView, referencesView and feedView.
    libraryView.onLibraryEntrySelected(entry);
    // TODO: For now, don't do anything in references and feed view. 
//    referencesView.onLibraryEntrySelected(entry);
//    feedView.onLibraryEntrySelected(entry);
//    setLocation(Location.REFERENCES, resetSearchQuery: true);#
    pushState(LocationUtil.getLibraryUrl(query: searchQuery, entryId: selectedEntryId));
  }
  
//  /// Handles the selection of feed view.
//  void handleFeedViewSelected(Event event, LibraryEntry entry) {
//    retardEvent(event);
//    this.selectedEntryId = entry.id;
//    libraryActivityCounter = 0;
//    libraryView.resetActivityCounter(entry);
//    // Propagate the event to libraryView, referencesView and feedView.
//    libraryView.onLibraryEntrySelected(entry);
//    referencesView.onLibraryEntrySelected(entry);
//    feedView.onLibraryEntrySelected(entry);
//    setLocation(Location.FEED, resetSearchQuery: true);
//  }
    
  /// Handles a search query.
  void handleSearchQueryTyped(Event event) { 
    retardEvent(event);
    // Propagate the event to underlying views.
    libraryView.onSearchQueryTyped(searchQuery);
//    switch (location) {
//      case Location.REFERENCES:
//        referencesView.onSearchQueryTyped(searchQuery);
//        break;
//      case Location.FEED:
//        feedView.onSearchQueryTyped(searchQuery);
//        break;
//      case Location.LIBRARY:
//      default:
//        libraryView.onSearchQueryTyped(searchQuery);
//        break;
//    }
    print("search query typed");
    pushState(LocationUtil.addQueryParameter(searchQuery));
  }
  
  /// Handles a cancellation of search.
  void handleSearchCancelled(Event event) {
    retardEvent(event);
    searchQuery = null;
    // Propagate the event to underlying views.
    libraryView.onSearchCancelled();
//    referencesView.onSearchCancelled();
//    feedView.onSearchCancelled();
    pushState(LocationUtil.removeQueryParameter());
  }
  
  /// Handles an import from pdf.
  void handleImportedFromPdf(LibraryEntry entry) {
    onSearchCancelled(null);
    
    LibraryEntry newEntry = new LibraryEntry("entry", entry.title, user)
      ..authors = entry.authors
      ..journal = entry.journal
      ..year = entry.year
      ..url = entry.url
      ..ee = entry.ee;
        
    libraryView.installLibraryEntry(newEntry);
    
//    loading("Importing entry \"${entry.title}\"...");
//    downloadFromWeb(entry, globalNotifications: true).then((entry) {
//      
//      var msg = "Entry \"${entry.title}\" successfully imported.";
////      var onClick = (e) => fireEntrySelectedEvent(entry);
//      notificationUtil.success(msg);
//      
//    }).catchError((e) => notificationUtil.error(
//        "Error on importing document: ${e}"));
  }
  
  /// Handles the selection of topics.
  void handleTopicsSelected(Iterable topicIds) {
    // Propagate the event to libraryView.
    libraryView.onTopicsSelected(topicIds);
  }
  
  /// Handles the upload of files.
  void handleFilesUpload(Iterable files) {
    // Propagate the event to libraryView.
    libraryView.onFilesUpload(files);
  }
  
  /// Handles the upload via url.
  void handleUrlUpload(String url) {
   // Propagate the event to libraryView.
   libraryView.onUrlUpload(url);
  }
  
  /// Handles the upload via url.
  void handleDownloadRequest(Event event, Map detail) {
    retardEvent(event);
    LibraryEntry entry = detail['entry'];
    loading("Downloading.", pouchable: entry);
    Notification n = new Notification(NotificationType.LOADING, "Downloading.");
    downloadFromWeb(entry).then((_) {
      success("Entry successfully downloaded", pouchable: entry);
    }).catchError((e) {
      error(e, pouchable: entry);
    });
  }
  
  /// Handles a previous-entry request.
  void handlePreviousEntryRequest() {
    libraryView.onPreviousEntryRequest();
  }
   
  /// Handles a next-entry request.
  void handleNextEntryRequest() {
    libraryView.onNextEntryRequest();
  }
  
//  /// Sets the location.
//  void setLocation(Location location, {bool resetSearchQuery: false}) {
//    if (resetSearchQuery) searchQuery = null;
////    this.location = location;
//  }
  
  // ___________________________________________________________________________
             
  /// Selects the given entry.
  void fireEntrySelectedEvent(LibraryEntry entry) {
    Map detail = {'entry': entry, 'location': Location.REFERENCES};
    fire(EVENT_ENTRY_SELECTED, detail: detail);
  }
   
  // ___________________________________________________________________________
  
  /// Installs the entry from web, i.e. searches for a pdf in web.
  Future downloadFromWeb(LibraryEntry entry, {bool globalNotifications: false}) {
    return actions.installFromWeb(entry, globalNotifications: globalNotifications);
  }
  
  // ___________________________________________________________________________
    
  /// Applies the current location.
  // TODO: Refactor this method.
  void applyLocationChange(Location prevLocation) {    
//    switch (prevLocation) {
//      case Location.LIBRARY:
//        libraryView.unreveal();
//        // TODO: Avoid the addition of revealed.
//        libraryView.classes.remove("revealed"); 
//        break;
//      case Location.REFERENCES:
//        referencesView.unreveal();
//        referencesView.classes.remove("revealed");
//        break;
//      case Location.FEED:
//        feedView.unreveal();
//        feedView.classes.remove("revealed");
//        break;
//      default:
//        libraryView.unreveal();
//        // TODO: Avoid the addition of revealed.
//        libraryView.classes.remove("revealed"); 
//        break;
//    }
    
    updateTabs();
  }
  
  /// Updates the css class names of tabs  according to the current location.
  void updateTabs() {
    switch (location) {
//      case Location.LIBRARY:
//        libraryView.reveal();
//        libraryView.classes.add("revealed");
//        libraryTabClasses = "active";
//        referencesTabClasses = selectedEntryId == null ? "disabled" : "";
//        feedsTabClasses = selectedEntryId == null ? "disabled" : "";
//        pushState(LocationUtil.getLibraryUrl(query: searchQuery));
//        break;
//      case Location.REFERENCES:
//        libraryView.reveal();
//        libraryView.classes.add("revealed");
//        libraryTabClasses = "active";
//        referencesTabClasses = selectedEntryId == null ? "disabled" : "";
//        feedsTabClasses = selectedEntryId == null ? "disabled" : "";
//        
//        
////        referencesView.reveal();
////        referencesView.classes.add("revealed");
////        libraryTabClasses = "";
////        referencesTabClasses = "active";
////        feedsTabClasses = selectedEntryId == null ? "disabled" : "";
//        var url = LocationUtil.getEntryUrl(selectedEntryId, query: searchQuery);
//        pushState(url);
//        break;
//      case Location.FEED:
//        feedView.reveal();
//        feedView.classes.add("revealed");
//        libraryTabClasses = "";
//        referencesTabClasses = selectedEntryId == null ? "disabled" : "";
//        feedsTabClasses = "active";
//        var url = LocationUtil.getFeedUrl(selectedEntryId, query: searchQuery);
//        pushState(url);
//        break;
      default:
        libraryView.reveal();
        libraryView.classes.add("revealed");
        libraryTabClasses = "active";
//        referencesTabClasses = selectedEntryId == null ? "disabled" : "";
//        feedsTabClasses = selectedEntryId == null ? "disabled" : "";
        pushState(LocationUtil.getLibraryUrl(query: searchQuery, entryId: selectedEntryId));
        break;
     }
  }
  
  /// Pushes the current state.
  void pushState(String url) {
    window.history.pushState(null, "", url);
  }
}