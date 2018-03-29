library search_element;

import 'dart:html';
import 'icecite_element.dart';
import '../utils/request.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('search-element')
/// Our implementation of an search-element.
class SearchElement extends IceciteElement {   
  Logger LOG = logging.get("search-element");

  @published String placeholder;
  @observable String searchQuery;
  @observable List tags = toObservable([]);
  @observable bool showHiddenTags = false;
  int maxNumOfVisibleTags = 2;
  
  DivElement searchWrapper;
  
  // ___________________________________________________________________________
  
  /// The constructor.
  SearchElement.created() : super.created();
  
  @override
  void attached() {
    super.attached();
    
    this.searchWrapper = get("search-wrapper");
  }
  
  /// This method is called, whenever the search input is focused.
  void onSearchInputFocused(event) => handleSearchInputFocused();
  
  /// This method is called, whenever the search input is blurred.
  void onSearchInputBlurred(event) => handleSearchInputBlurred();
  
  /// This method is called, whenever the remove tag button was clicked.
  void onRemoveTagRequest(evt, data, target) => handleRemoveTagRequest(evt, target);
  
  /// This method is called, whenever a search query was typed.
  void onSearchRequest(event) => handleSearchRequest();
  
  /// This method is called, whenever the search was cancelled.
  void onCancelSearchRequest(event) => handleCancelSearchRequest();
  
  /// This method is called, whenever a show all tags reiqest occurred.
  void onToggleHiddenTagsRequest(event) => handleToggleHiddenTagsRequest(); 
  
  // ___________________________________________________________________________
  
  /// Handles a focus on search input.
  void handleSearchInputFocused() {
    searchWrapper.classes.add("focused");
  }
  
  /// Handles a blur on search input.
  void handleSearchInputBlurred() {
    searchWrapper.classes.remove("focused");
  }
  
  /// Handles a click on remove tag button.
  void handleRemoveTagRequest(Event event, Element target) {
    retardEvent(event);
    removeTagAt(int.parse(target.dataset['tagidx']));
  }
  
  /// Handles a search query.
  void handleSearchRequest() {
    fireSearchRequest(searchQuery);
  }
  
  /// Handles a click on remove tag button.
  void handleCancelSearchRequest() {
    this.searchQuery = null;
    fireCancelSearchRequest();
  }
  
  /// Handles a toggle hidden tags request.
  void handleToggleHiddenTagsRequest() {
    if (showHiddenTags) {
      hideHiddenTags();
    } else {
      displayHiddenTags();
    }
  }
  
  // ___________________________________________________________________________
  
  /// Adds the given tags.
  void addTags(List<String> tags) {
    if (tags == null) return;
    bool added = false;
    for (String tag in tags) {
      if (this.tags.contains(tag)) continue; // Don't add the tag twice.
      this.tags.add(tag);
      added = true;
    }
    if (added) {
      notifyPropertyChange(#visibleTags, 0, 1);
      notifyPropertyChange(#hiddenTags, 0, 1);
      fireFilterByTagsRequest();
    }
  }
  
  /// Adds the given tag.
  void addTag(String tag) {
    if (tag == null) return;
    if (tags.contains(tag)) return; // Don't add the tag twice.
    this.tags.add(tag);
    
    notifyPropertyChange(#visibleTags, 0, 1);
    notifyPropertyChange(#hiddenTags, 0, 1);
    fireFilterByTagsRequest();
  }
  
  /// Removes the given tag.
  void removeTag(String tag) {
    if (tag == null) return;
    if (this.tags.remove(tag)) {
      
      notifyPropertyChange(#visibleTags, 0, 1);
      notifyPropertyChange(#hiddenTags, 0, 1);
      fireFilterByTagsRequest();  
    }
  }
  
  /// Removes the tag at given index.
  void removeTagAt(int index) {
    if (index < 0) return;
    if (index > tags.length - 1) return;
    this.tags.removeAt(index);
    
    notifyPropertyChange(#visibleTags, 0, 1);
    notifyPropertyChange(#hiddenTags, 0, 1);
    fireFilterByTagsRequest();
  }
  
  void clear() {
    clearTags();
    clearSearchQuery();
  }
  
  /// Clears the tags.
  void clearTags() {
    if (this.tags.isEmpty) return;
    this.tags.clear();
    
    notifyPropertyChange(#visibleTags, 0, 1);
    notifyPropertyChange(#hiddenTags, 0, 1);
    fireFilterByTagsRequest();
  }
  
  /// Clears the tags.
  void clearSearchQuery() {
    this.searchQuery = null;
  }
  
  // ___________________________________________________________________________
  
  void hideHiddenTags() {
    showHiddenTags = false;
  }
  
  void displayHiddenTags() {
    showHiddenTags = true;
  }
  
  @observable get visibleTags {
    if (tags.length <= maxNumOfVisibleTags) {
      return tags.sublist(0);
    } else {
      return tags.sublist(0, maxNumOfVisibleTags);
    }
  }
  
  @observable get hiddenTags {
    if (tags.length <= maxNumOfVisibleTags) {
      return [];
    } else {
      return tags.sublist(maxNumOfVisibleTags);
    }
  }
  
  // ___________________________________________________________________________
  
  /// Fires a search request.
  void fireSearchRequest(String searchQuery) {
    fire(IceciteRequest.SEARCH, detail: searchQuery);
  }
  
  /// Fires a cancel search request.
  void fireCancelSearchRequest() {
    fire(IceciteRequest.CANCEL_SEARCH);
  }
  
  /// Fires a cancel search request.
  void fireFilterByTagsRequest() {
    fire(IceciteRequest.FILTER_BY_TAGS, detail: tags);
  }
}