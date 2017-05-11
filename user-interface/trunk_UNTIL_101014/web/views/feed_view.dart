library feed_view;

import 'dart:html';
import 'package:polymer/polymer.dart' hide ObservableMap;
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../utils/search/search_util.dart';
import '../utils/observable_map.dart';

/// The feed of Icecite.
@CustomTag('feed-view')
class FeedView extends IceciteElement {   
  // The unfiltered feed entries.
  @observable Map<String, FeedEntry> feedEntries = new ObservableMap();
  // The sort fields.
  @observable List<String> sortFields = toObservable(SortField.comparators.keys.toList());
  // The selected sort field.
  @observable String selectedSortField;
  // True, if the entries should be sorted ascending, false otherwise.
  @observable bool sortAscending = true;
  // The content of textarea.
  @observable String data;
  /// For some reason, the selected entry isn't updated in view if the entry
  /// has changed. But putting the entry into a list works. So use this as a 
  /// workaround. 
  @observable List selectedEntryInList = toObservable([null]);  
  
  /// The default constructor.
  FeedView.created() : super.created();
       
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("views/feed_view.css"));
  }
  
  void revealedHandler() {
    super.revealedHandler();
    if (selectedSortField == null) sort(SortField.FIRST, asc: true);
  }
  
  /// Resets the view to default values.  
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.selectedEntryInList != null) selectedEntryInList[0] = null;
    if (this.feedEntries != null) this.feedEntries.clear();
    this.selectedSortField = null;
    this.sortAscending = true;
    this.data = null;
  }
  
  // ___________________________________________________________________________
  // Handlers.
      
  /// This method is automatically called, whenever the selected entry was
  /// changed.
  void selectedEntryChanged(LibraryEntry prevSelectedEntry) {
    if (selectedEntry == null) return;
    
    this.selectedEntryInList[0] = selectedEntry;
    
    if (actions.areSupplementsFilled(selectedEntry)) fill();
    actions.onSupplementsFilled(selectedEntry).listen((_) => fill());
    actions.onFeedEntryChanged(selectedEntry).listen(feedEntryChangedHandler);
    actions.onFeedEntryDeleted(selectedEntry).listen(feedEntryDeletedHandler);
    actions.onLibraryEntryChanged.listen(libraryEntryChangedHandler);
    // cache.onLibraryEntryDeleted.listen(libraryEntryDeletedHandler);
  }
  
  /// Define the behavior when a feed entry in storage was added or updated.
  void feedEntryChangedHandler(feedEntry) => revealFeedEntry(feedEntry); 
  
  /// Define the behavior when a feed entry in storage was deleted.
  void feedEntryDeletedHandler(feedEntry) => unrevealFeedEntry(feedEntry);
  
  /// Define the behavior when a library entry was changed.
  void libraryEntryChangedHandler(entry) => revealSelectedEntry(entry);
  
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// This method is called, whenever an entry was selected.
  void onSelectLibraryEntryPurpose(event, entry, target) { 
    selectedEntry = entry; // Will trigger the call of selectedEntryChanged.
  }
  
  /// Will add a feed entry.
  void onAddFeedEntryPurpose(event, details, target) => addFeedEntry(data);
  
  /// Will update the given entry.
  void onUpdateFeedEntryPurpose(event, feed, target) => updateFeedEntry(feed);
  
  /// Will delete the given entry.
  void onDeleteFeedEntryPurpose(event, feed, target) => deleteFeedEntry(feed);
  
  /// Will update the given entry in storage.
  void onUpdateSelectedEntryPurpose(e, entry, t) => updateSelectedEntry(entry);
   
  /// Will update the given entry in storage.
  void onDeleteSelectedEntryPurpose(e, entry, t) => deleteSelectedEntry(entry);
  
  /// Will reject the given topic from given entry.
  void onRejectTopicPurpose(e, d, t) => rejectTopic(d['entryId'], d['topicId']);
  
  /// Will search the database.
  void onSearchPurpose(query) => search(query);
  
  /// Will cancel the search.
  void onCancelSearchPurpose() => cancelSearch();
  
  /// Will sort the feeds.
  void onSortPurpose(event, entry, target) => sort(target.dataset['field']);
  
  /// Will add a new feed entry.
  void onKeypress(event, details, target) {
    if (event.keyCode == KeyCode.ENTER) addFeedEntry(data);
  }
    
  /// Rejects the given user from selected entry.
  void onRejectUserPurpose(e, d, t) => rejectUser(d['entry'], d['user']);
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Adds a feed entry.
  void addFeedEntry(String data) {
    if (data == null || data.trim().isEmpty) return;
    FeedEntry feedEntry = new FeedEntry(auth.user, data, selectedEntry.id);
    actions.setFeedEntry(selectedEntry, feedEntry).then((_) => resetData());
  }
  
  /// Updates a feed entry.
  void updateFeedEntry(FeedEntry feed) { 
    actions.setFeedEntry(selectedEntry, feed..modified = new DateTime.now());
  }
  
  /// Deletes a feed entry.
  void deleteFeedEntry(FeedEntry feed) { 
    actions.deleteFeedEntry(selectedEntry, feed);
  }
  
  /// Updates the given entry.
  void updateSelectedEntry(LibraryEntry entry) {
    actions.setLibraryEntry(entry..modified = new DateTime.now());
  }
  
  /// Updates the given entry.
  void deleteSelectedEntry(LibraryEntry entry) {
    actions.uninstallLibraryEntry(entry);
  }
  
  /// Searches.
  void search(String query) {
    this.searchQuery = query;
  }
  
  /// Cancels the search.
  void cancelSearch() {
    this.searchQuery = null;
  }
        
  /// Rejects the given topic from given entry.
  void rejectTopic(String entryId, String topicId) {
    actions.rejectLibraryEntryFromTopic(entryId, topicId);
  }
  
  /// Unshares the given entry from given user.
  void rejectUser(LibraryEntry entry, User user) {
    actions.rejectEntryFromUser(entry, user);
  }
  
  // ___________________________________________________________________________
  // Display methods.
    
  /// Fills the feed for the given entry.
  void fill() {    
    feedEntries.clear();
    feedEntries.addAll(actions.getFeedEntries(selectedEntry));
  }
    
  /// Reveals a feed entry, i.e. adds the feed entry, if it isn't present in 
  /// feed and updates it otherwise.
  void revealFeedEntry(FeedEntry feed) {
    if (feed == null || selectedEntry == null) return;
    if (feed.entryId != selectedEntry.id) return;
    
    fire("activity"); 
    if (!feedEntries.containsKey(feed.id)) info("new", pouchable: feed);
    else info("updated", pouchable: feed);
    feedEntries[feed.id] = feed;
  }
  
  /// Unreveals the given feed entry from display.
  void unrevealFeedEntry(FeedEntry feed) {
    if (feed == null || selectedEntry == null) return;
    if (feed.entryId != selectedEntry.id) return;
    feedEntries.remove(feed.id);
  }
  
  /// Reveals the selected library entry.
  void revealSelectedEntry(LibraryEntry entry) {
    if (entry == null) return;
    if (entry != selectedEntry) return;
    if (entry.userIds == null) return;
    if (!entry.userIds.contains(user.id)) return;
    this.selectedEntry = entry;
    this.selectedEntryInList[0] = selectedEntry;
  }
    
  /// Sorts.
  void sort(var sortField, {bool asc: false}) {
    String field = sortField is SortField ? sortField.display : sortField;
    sortAscending = (field != selectedSortField || asc) ? true: !sortAscending;
    selectedSortField = field; 
    setSortCssLabel(get(field), sortAscending ? "asc" : "desc");
  }
  
  /// Sorts the entries according to given field. If this field is already the 
  /// current sorting field then reverse the sort
  Function sortBy(String sortField, bool ascending) {
    return (Iterable<FeedEntry> entries) { 
      if (sortField == null) return entries;
      var list = entries.toList()..sort(SortField.comparators[sortField]);
      return ascending ? list : list.reversed;    
    };
  }
  
  /// Filters the feeds by given query.
  Function filterBy(String query) {
    return (Iterable<FeedEntry> feedEntries) {
      if (feedEntries == null) return [];
      return feedEntries.where((entry) => filterFeedEntryByQuery(entry, query)); 
    };
  }
  
  /// Resets the data.
  void resetData() {
    this.data = null;
  }
}

/// The sort fields.
class SortField {
  final String display;
  final String field;
  const SortField._internal(this.display, this.field);
  static const FIRST = const SortField._internal("CreationDate", "created");
  static const SECOND = const SortField._internal("Content", "data");
    
  static Map<String, Function> comparators = {
    FIRST.display: IceciteElement.getComparator(FIRST.field),
    SECOND.display: IceciteElement.getComparator(SECOND.field),
  };
}