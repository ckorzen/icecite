@MirrorsUsed(targets: 'LibraryEntry,Notification,NotificationType')
library stage_view;

import 'dart:html' hide Notification, Location, Entry;
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import 'library_view.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../elements/upload_element.dart';
import '../elements/search_element.dart';
import '../utils/html/location_util.dart';

/**
 * This is the area, where all the main functionality of Icecite is placed. 
 * The stage includes the library, the references and the feed.
 */
@CustomTag('stage-view')
class StageView extends IceciteElement {   
  /// The library view.
  LibraryView libraryView;
  /// The uploader.
  UploadElement uploadElement;
  /// The search element.
  SearchElement searchElement;    
  
  /// The default constructor.
  StageView.created() : super.created();
        
  @override
  void reset() {
    super.reset();
    if (uploadElement != null) uploadElement.reset();
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  @override
  void onRevealed() => handleRevealed();
  
  /// This method is called, whenever files were uploaded.
  void onUploadFilesRequest(event, data) => handleUploadFilesRequest(data); 
  
  /// This method is called, whenever there is an url for upload.
  void onUploadUrlRequest(event, data) => handleUploadUrlRequest(data); 
  
  /// This method is called, whenever a search was started.
  void onSearchRequest(event, data) => handleSearchRequest(data);
  
  /// This method is called, whenever a search was cancelled.
  void onCancelSearchRequest(event) => handleCancelSearchRequest();
      
  /// This method is called, whenever a tag was selected.
  void onSelectTagRequest(event, data) => handleSelectTagRequest(data);
  
  /// This method is called, whenever a filter by tags request occurred.
  void onFilterByTagsRequest(event, data) => handleFilterByTagsRequest(data);
  
  // ___________________________________________________________________________
  // Handlers.
    
  /// Reveals the elements of this view.
  void handleRevealed() {
    this.libraryView = get("library-view");  
    this.uploadElement = get("upload-element");
    this.searchElement = get("search-element");
    
    if (searchQuery != null) handleSearchRequest(searchQuery);
    if (selectedTags != null) handleSelectTagsRequest(selectedTags);
    
    this.uploadElement.reveal();
    this.libraryView.reveal();
    this.libraryView.classes.add("revealed"); // TODO
    
    pushState(LocationUtil.getLibraryUrl(query: searchQuery, 
                                         entryId: selectedEntryId));
  }
  
  /// Handles a upload-files request.
  void handleUploadFilesRequest(Iterable files) {
    // Propagate the event to libraryView.
    libraryView.installFiles(files);
  }
  
  /// Handles an upload-url request.
  void handleUploadUrlRequest(String url) {
    // Propagate the event to libraryView.
    libraryView.installUrl(url);
  } 
  
  /// Handles a search query.
  void handleSearchRequest(String searchQuery) {
    this.searchQuery = searchQuery;
    // Propagate the event to underlying views.
    libraryView.search(searchQuery);
    pushState(LocationUtil.addParameter(searchQuery: searchQuery));
  }
  
  /// Handles a cancellation of search.
  void handleCancelSearchRequest() {
    this.searchQuery = null;
    // Propagate the event to library view.
    libraryView.cancelSearch();
    searchElement.clear();
    pushState(LocationUtil.removeParameter(searchQuery: true));
  }
  
  /// Handles the selection of a tag.
  void handleSelectTagsRequest(List<String> tags) {
    if (tags == null) return;
    searchElement.addTags(tags);
  }
  
  /// Handles the selection of a tag.
  void handleSelectTagRequest(String tag) {
    searchElement.addTag(tag);
  }
  
  /// Handles the filter by tags request.
  void handleFilterByTagsRequest(List<String> tags) {
    // Propagate to library view.
    libraryView.setSelectedTags(tags);
    if (tags == null || tags.isEmpty) {
      pushState(LocationUtil.removeParameter(tags: true));  
    } else {
      pushState(LocationUtil.addParameter(tags: tags));
    }
  }
                  
  // ___________________________________________________________________________
  // Actions.
  
  /// Handles the selection of a library entry.
  void selectEntry(Entry entry) {
    if (entry == null) return;
    this.selectedEntryId = entry.id;
    // Propagate the event to libraryView, referencesView and feedView.
    libraryView.selectEntry(entry);
    pushState(LocationUtil.getLibraryUrl(query: searchQuery, 
                                         entryId: selectedEntryId));
  }
    
  /// Imports the given entry.
  void import(Entry entry, {bool cancelSearch: false}) {
    /// Propagate the task to libraryView.
    if (cancelSearch) handleCancelSearchRequest();
    libraryView.import(entry);
  }
  
  /// Deletes the given entry.
  void deleteEntry(Entry entry) {
    libraryView.deleteEntry(entry);
  }
  
  /// Handles a previous-entry request.
  LibraryEntry getPreviousEntry() => libraryView.getPreviousLibraryEntry();
   
  /// Handles a next-entry request.
  LibraryEntry getNextEntry() => libraryView.getNextLibraryEntry();
          
  /// Pushes the current state.
  void pushState(String url) {
    window.history.pushState(null, "", url);
  }
}