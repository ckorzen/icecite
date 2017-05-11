@MirrorsUsed(targets: 'LibraryEntry,Notification,NotificationType')
library stage_view;

import 'dart:html' hide Notification, Location;
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import 'library_view.dart';
import 'references_view.dart';
import 'feed_view.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../utils/html/location_util.dart';
import '../utils/pdf/pdf_resolver.dart';

/**
 * This is the area, where all the main functionality of Icecite is placed. 
 * The stage includes the library, the references and the feed.
 */
@CustomTag('stage-view')
class StageView extends IceciteElement {
  @observable Location location;
  @observable String libraryTabClasses;
  @observable int libraryActivityCount;
  @observable String referencesTabClasses;
  @observable int referencesActivityCount;
  @observable String feedsTabClasses;
  @observable int feedsActivityCount;
  
  // The library view.
  LibraryView libraryView;
  // The library tab.
  HtmlElement libraryTab;
  // The references view.
  ReferencesView referencesView;
  // The references tab.
  HtmlElement referencesTab;
  // The library view.
  FeedView feedView;
  // The feed tab.
  HtmlElement feedTab;
  // The pdfResolver.
  PdfResolverInterface pdfResolver;
  
  /// The default constructor.
  StageView.created() : super.created();
    
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("views/stage_view.css"));
  }
  
  /// Overrides.
  void resetOnLogout() {
    super.resetOnLogout();
    this.location = null;
    this.libraryTabClasses = null;
    this.referencesTabClasses = null;
    this.feedsTabClasses = null;
    this.libraryActivityCount = 0;
    this.referencesActivityCount = 0;
    this.feedsActivityCount = 0;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  void revealedHandler() { // Revealed on login.
    super.revealedHandler();
    this.pdfResolver = new PdfResolverImpl();
    this.libraryTab = get("library-tab");
    this.referencesTab = get("references-tab");
    this.feedTab = get("feed-tab");
    this.libraryView = get("library-view");    
    this.referencesView = get("references-view");
    this.feedView = get("feed-view");
    this.libraryActivityCount = 0;
    this.referencesActivityCount = 0;
    this.feedsActivityCount = 0;
    this.location = LocationUtil.getLocation(window.location.hash);
    if (searchQuery != null) search(searchQuery);
  }
   
  /// This method is called, whenever the location has changed.
  void locationChanged(Location prevLocation) => changeLocation(prevLocation);
      
  /// This method is called, whenever an entry was deleted.
  void entryDeletedHandler(event, entryId, target) {
    // Clear the selectedEntryId, if its equal to the id of deleted entry.
    if (selectedEntryId == entryId) {
      selectedEntryId = null;
      location = Location.LIBRARY;
      info("The selected entry was deleted.");
    }
  }
  
  void libraryActivityHandler(event, detail, target) {
    if (location != Location.LIBRARY && location != Location.UNKNOWN)
      libraryActivityCount++;
  }
  
  void referencesActivityHandler(event, detail, target) {
    if (location != Location.REFERENCES) referencesActivityCount++;
  }
  
  void feedActivityHandler(event, detail, target) {
    if (location != Location.FEED) feedsActivityCount++;
  }
  
  /// This method is called, whenever the selection of topics has changed.
  void topicsSelectedHandler(event, detail, target) {
    libraryView.topicsSelectedHandler(event, detail, target);
  }
    
  // ___________________________________________________________________________
  // On-purpose methods.
    
  /// This method is called, whenever the library tab was clicked.
  void onLibraryTabPurpose(event, params, target) {
    location = Location.LIBRARY;
    libraryActivityCount = 0;
  }
  
  /// This method is called, whenever the entry tab was clicked.
  void onReferencesTabPurpose(event, params, target) {
    if (selectedEntryId != null) {
      location = Location.REFERENCES;
      referencesActivityCount = 0;
    }
  }
  
  /// This method is called, whenever the feed tab was clicked.
  void onFeedTabPurpose(event, params, target) {
    if (selectedEntryId != null) {
      location = Location.FEED;
      feedsActivityCount = 0;
    }
  }
        
  /// This method is called, whenever files were uploaded.
  void onUploadFilesPurpose(e, d, t) => libraryView.onUploadFilesPurpose(e, d, t);
  
  /// This method is called, whenever file(s) were uploaded.
  void onUrlUploadPurpose(e, d, t) => libraryView.onUrlUploadPurpose(e, d, t);
   
  /// This method is called, whenever a search was started.
  void onSearchPurpose(event, details, target) => search(searchQuery);
  
  /// This method is called, whenever a search was cancelled.
  void onCancelSearchPurpose(event, details, target) => cancelSearch();
  
  /// Will import the given entry.
  void onImportFromPdfPurpose(event, entry, target) => importFromPdf(entry);
  
  /// This method is called, whenever an entry was selected.
  void onSelectLibraryEntryPurpose(e, d, t) => selectLibraryEntry(e, d, t);
            
  // ___________________________________________________________________________
  // Actions.
   
  /// Selects the given entry.
  void selectLibraryEntry(Event event, LibraryEntry entry, Node target) {
    /// Search a pdf in web, if entry isn't an entry.
    if (entry.brand != 'entry') return searchInWebBeforeSelecting(entry);
    this.selectedEntryId = entry.id;
    libraryView.onSelectLibraryEntryPurpose(event, entry, target);
    referencesView.onSelectLibraryEntryPurpose(event, entry, target);
    feedView.onSelectLibraryEntryPurpose(event, entry, target);
    location = Location.REFERENCES;
  }
  
  /// Propagates the search event to the individual views.
  void search(String query) { 
    libraryView.onSearchPurpose(searchQuery);
    referencesView.onSearchPurpose(searchQuery);
    feedView.onSearchPurpose(searchQuery);
    _pushState(LocationUtil.addQueryParameter(searchQuery));
  }
  
  /// Propagates the cancel-search event to the individual views.
  void cancelSearch() {
    libraryView.onCancelSearchPurpose();
    referencesView.onCancelSearchPurpose();
    feedView.onCancelSearchPurpose();
    _pushState(LocationUtil.removeQueryParameter());
  }
  
  /// Searches for a related pdf for given entry on selecting the entry.
  void searchInWebBeforeSelecting(LibraryEntry entry) {
    loading("Searching in web", pouchable: entry);
    actions.searchPdfInWeb(entry)
      .then((entry) => selectEntry(entry))
      .catchError((e) => error("Error on searching in web: $e"));
  }
    
  /// Searches for a related pdf for given entry on importing from pdf.
  void importFromPdf(LibraryEntry entry) {
    loading("Importing entry \"${entry.title}\"...");
    actions.searchPdfInWeb(entry)
      .then((entry) => success("Entry \"${entry.title}\" imported." 
        "Click to open it.", onClick: (e) => selectEntry(entry)))
      .catchError((e) => error("Error on importing document: ${e}"));
  }
       
  /// Selects the given entry.
  void selectEntry(LibraryEntry entry) {
    fire("select-entry", detail: entry);
  }
  
  // ___________________________________________________________________________
  // Display methods.
  
  // TODO: Refactor this method.
  void changeLocation(Location prevLocation) {    
    switch (prevLocation) {
      case Location.LIBRARY:
        libraryView.unreveal();
        // TODO: Avoid the addition of revealed.
        libraryView.classes.remove("revealed"); 
        break;
      case Location.REFERENCES:
        referencesView.unreveal();
        referencesView.classes.remove("revealed");
        break;
      case Location.FEED:
        feedView.unreveal();
        feedView.classes.remove("revealed");
        break;
      default:
        libraryView.unreveal();
        // TODO: Avoid the addition of revealed.
        libraryView.classes.remove("revealed"); 
        break;
    }
    
    switch (location) {
      case Location.LIBRARY:
        libraryView.reveal();
        libraryView.classes.add("revealed");
        libraryTabClasses = "active";
        referencesTabClasses = selectedEntryId == null ? "disabled" : "";
        feedsTabClasses = selectedEntryId == null ? "disabled" : "";
        _pushState(LocationUtil.getLibraryUrl(query: searchQuery));
        break;
      case Location.REFERENCES:
        referencesView.reveal();
        referencesView.classes.add("revealed");
        libraryTabClasses = "";
        referencesTabClasses = "active";
        feedsTabClasses = selectedEntryId == null ? "disabled" : "";
        _pushState(LocationUtil.getEntryUrl(selectedEntryId, query: searchQuery));
        break;
      case Location.FEED:
        feedView.reveal();
        feedView.classes.add("revealed");
        libraryTabClasses = "";
        referencesTabClasses = selectedEntryId == null ? "disabled" : "";
        feedsTabClasses = "active";
        _pushState(LocationUtil.getFeedUrl(selectedEntryId, query: searchQuery));
        break;
      default:
        libraryView.reveal();
        libraryView.classes.add("revealed");
        libraryTabClasses = "active";
        referencesTabClasses = selectedEntryId == null ? "disabled" : "";
        feedsTabClasses = selectedEntryId == null ? "disabled" : "";
        _pushState(LocationUtil.getLibraryUrl(query: searchQuery));
        break;
    }
  }
  
  // ___________________________________________________________________________
  // Helper methods.
  
  void _pushState(String url) {
    window.history.pushState(null, "", url);
  }
}