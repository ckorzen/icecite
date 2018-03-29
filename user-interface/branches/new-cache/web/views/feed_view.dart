//library feed_view;
//
//import 'dart:html';
//import 'dart:async';
//import 'package:polymer/polymer.dart' hide ObservableMap;
//import '../models/models.dart';
//import '../actions/actions.dart';
//import '../elements/icecite_element.dart';
//import '../utils/search/search_util.dart';
//import '../utils/observable_map.dart';
//
////// The feed of Icecite.
//@CustomTag('feed-view')
//class FeedView extends IceciteElement {   
//  /// The unfiltered feed entries.
//  @observable Map<String, FeedEntry> feedEntries = new ObservableMap();
//  /// The sort fields.
//  @observable List<String> sortFields = toObservable(SortField.comparators.keys.toList());
//  /// The selected sort field.
//  @observable String selectedSortField;
//  /// True, if the entries should be sorted ascending, false otherwise.
//  @observable bool sortAscending = true;
//  /// The content of textarea.
//  @observable String data;
//  /// For some reason, the selected entry isn't updated in view if the entry
//  /// has changed. But putting the entry into a list works. So use this as a 
//  /// workaround. 
//  @observable List selectedEntryInList = toObservable([null]);  
//  /// The selected types (activity / comment)
//  @observable List selectedTypeFilters;
//  
//  /// The checkbox to display activities. 
//  InputElement activityFilterCheckBox;
//  /// The checkbox to display comments. 
//  InputElement commentsFilterCheckBox;
//
//  // ___________________________________________________________________________
//  
//  /// The default constructor.
//  FeedView.created() : super.created();
//     
//  @override
//  void attached() {
//    super.attached();
//    actions.onActivity.listen(onActivity);
//  }
//      
//  @override
//  void resetOnLogout() {
//    super.resetOnLogout();
//    if (this.selectedEntryInList != null) selectedEntryInList[0] = null;
//    if (this.feedEntries != null) this.feedEntries.clear();
//    this.selectedSortField = null;
//    this.sortAscending = true;
//    this.data = null;
//  }
//  
//  // ___________________________________________________________________________
//  // Handlers.
//  
//  /// This method is called, whenever the view was revealed.
//  void onRevealed() => handleRevealed();
//        
//  /// This method is called, whenever a feed entry was changed in db.
//  void onFeedEntryChangedInDb(feed) => handleFeedEntryChangedInDb(feed);
//  
//  /// This method is called, whenever a feed entry was deleted in db.
//  void onFeedEntryDeletedInDb(feed) => handleFeedEntryDeletedInDb(feed);
//  
//  /// This method is called, whenever a feed was updated.
//  void onFeedEntryUpdated(event, feed) => handleFeedEntryUpdated(event, feed);
//  
//  /// This method is called, whenever a feed was deleted.
//  void onFeedEntryDeleted(event, feed) => handleFeedEntryDeleted(event, feed);
//  
//  /// This method is called, whenever there is an activity.
//  void onActivity(activity) => handleActivity(activity);
//      
//  /// This method is called, whenever a key was pressed in new-feed-form.
//  void onKeyPressed(event) => handleKeyPressed(event);
//  
//  /// This method is called, whenever the submit button was clicked.
//  void onSubmitButtonClicked(event) => handleSubmitButtonClicked(event);
//  
//  /// This method is called, whenever a sort field was clicked.
//  void onSortFieldClicked(evt, d, trgt) => handleSortFieldClicked(evt, trgt);
//  
//  /// This method is called, whenever a type filter field was clicked.
//  void onTypeFilterClicked(event) => handleTypeFilterClicked(event);
//  
//  /// This method is called, whenever a search query was typed.
//  void onSearchQueryTyped(query) => handleSearchQueryTyped(query);
//  
//  /// This method is called, whenever a search was cancelled.
//  void onSearchCancelled() => handleSearchCancelled();
//  
//  
//  // ___________________________________________
//  // Handlers related to selected library entry.
//  
//  /// This method is called, whenever the selected entry was changed.
//  void selectedEntryChanged(prevEntry) => handleSelectedEntryChange();
//  
//  /// This method is called, whenever a library entry was changed in db.
//  void onLibraryEntryChangedInDb(entry) => handleLibraryEntryChangedInDb(entry);
//  
//  /// This method is called, whenever a library entry was updated.
//  void onLibraryEntryUpdated(evt, entr) => handleLibraryEntryUpdated(evt, entr);
//   
//  /// This method is called, whenever a library entry was deleted.
//  void onLibraryEntryDeleted(evt, entr) => handleLibraryEntryDeleted(evt, entr);
//  
//  /// This method is called, whenever an entry was selected.
//  void onLibraryEntrySelected(entry) => handleLibraryEntrySelected(entry); 
//  
//  /// This method is called, whenever a topic was rejected from library entry.
//  void onTopicRejected(event, details) => handleTopicRejected(event, details);
//  
//  /// This method is called, whenever the logged-in user has invited another 
//  /// user to an entry.
//  void onUserHasInvited(event, details) => handleUserHasInvited(event, details);
//  
//  /// This method is called, whenever a participant was disinvited from entry.
//  void onParticipantDisinvited(event, details) => 
//      handleParticipantDisinvited(event, details);
//  
//  /// This method is called, whenever an invitee was disinvited from entry.
//   void onInviteeDisinvited(event, details) => 
//       handleInviteeDisinvited(event, details);
//          
//  /// This method is called, when a tag was added to an entry.
//  void onTagAdded(event, details) => handleTagAdded(event, details);
//  
//  /// This method is called, when a tag was updated.
//  void onTagUpdated(event, details) => handleTagUpdated(event, details);
//   
//  /// This method is called, when a tag was deleted.
//  void onTagDeleted(event, details) => handleTagDeleted(event, details);
//   
//  // ___________________________________________________________________________
//  // Actions.
//  
//  /// Reveals the elements of this view.
//  void handleRevealed() {
//    // Sort the feeds by the first sort field by default.
//    if (selectedSortField == null) sort(SortField.FIRST, asc: true);
//    this.activityFilterCheckBox = get("activity-filter");
//    this.commentsFilterCheckBox = get("comments-filter");
//  }
//  
//  /// Handles a change of feed entry in db.
//  void handleFeedEntryChangedInDb(FeedEntry feed) {
//    // Reveal the feed entry.
//    revealFeedEntry(feed); 
//  }
//  
//  /// Handles a deletion of feed entry in db.
//  void handleFeedEntryDeletedInDb(FeedEntry feed) {
//    // Unreveal the feed entry.
//    unrevealFeedEntry(feed); 
//  }
//  
//  /// Handles an update of feed entry.
//  void handleFeedEntryUpdated(Event event, FeedEntry feed) {
//    retardEvent(event);
//    // Update the feed entry.
//    updateFeedEntry(feed);
//  }
//  
//  /// Handles a deletion of feed entry.
//  void handleFeedEntryDeleted(Event event, FeedEntry feed) {
//    retardEvent(event);
//    // Delete the feed entry.
//    deleteFeedEntry(feed);
//  }
//  
//  /// Handles an activity.
//  void handleActivity(Activity a) {
//    if (a == null) return;
//    // Create feed entry.
//    FeedEntry feed = new FeedEntry(createActivityText(a.type, a.user), true);
//    setFeedEntry(feed, a.entry);
//  }
//  
//  /// Handles a key press in new feed form.
//  void handleKeyPressed(KeyboardEvent event) {
//    // Ignore all key presses, which aren't the enter key.
//    if (event.keyCode != KeyCode.ENTER) return;
//    if (data == null) return;
//    if (data.trim().isEmpty) return;
//    // Add the feed entry to db and reset the data if done.
//    addFeedEntry().then((_) => resetData());
//  }
//  
//  /// Handles a click on add feed entry button.
//  void handleSubmitButtonClicked(Event event) {
//    retardEvent(event);
//    if (data == null) return;
//    if (data.trim().isEmpty) return;
//    // Add the feed entry to db and reset the data if done.
//    addFeedEntry().then((_) => resetData());
//  }
//  
//  /// Handles a click on sort field.
//  void handleSortFieldClicked(Event event, HtmlElement target) {
//    retardEvent(event);
//    if (target == null) return;
//    // Sort by given field.
//    sort(target.dataset['field']);
//  }
//  
//  /// Handles a click on type filter.
//  void handleTypeFilterClicked(Event event) {    
//    selectedTypeFilters = toObservable([]);
//    if (activityFilterCheckBox.checked) selectedTypeFilters.add("activities");
//    if (commentsFilterCheckBox.checked) selectedTypeFilters.add("comments");
//  }
//  
//  /// Handles a search query.
//  void handleSearchQueryTyped(String query) {
//    this.searchQuery = query;
//  }
//  
//  /// Handles a cancellation of search.
//  void handleSearchCancelled() {
//    this.searchQuery = null;
//  }
//  
//  
//  /// Handles the change of selected entry.
//  void handleSelectedEntryChange() {
//    if (selectedEntry == null) return;
//    this.selectedEntryInList[0] = selectedEntry;
//    if (actions.areSupplementsFilled(selectedEntry)) fill();
//    actions.onSupplementsFilled(selectedEntry).listen((_) => fill());
//    actions.onFeedEntryChanged(selectedEntry).listen(onFeedEntryChangedInDb);
//    actions.onFeedEntryDeleted(selectedEntry).listen(onFeedEntryDeletedInDb);
//    actions.onLibraryEntryChanged.listen(onLibraryEntryChangedInDb);
//    // cache.onLibraryEntryDeleted.listen(libraryEntryDeletedHandler);
//  }
//  
//  /// Handles a change of library entry in db.
//  void handleLibraryEntryChangedInDb(LibraryEntry entry) {
//    if (entry == null) return;
//    if (!user.isOwnerOrParticipant(entry)) return;
//    if (entry != selectedEntry) return;
//    // Unreveal the feed entry.
//    revealLibraryEntry(entry); 
//  }
//  
//  /// Handles an update of library entry.
//  void handleLibraryEntryUpdated(Event event, LibraryEntry entry) {
//    retardEvent(event);
//    // Update the library entry.
//    updateLibraryEntry(entry);
//  }
//  
//  /// Handles a update of deletion of feed entry.
//  void handleLibraryEntryDeleted(Event event, LibraryEntry entry) {
//    retardEvent(event);
//    // Distinguish if user is the owner.
//    if (user.isOwner(entry)) {
//      // The user is the owner. So delete the library entry.
//      deleteLibraryEntry(entry); 
//    } else {
//      // The user isn't the owner. So unsubscribe the user.
//      unsubscribeUserFromLibraryEntry(entry);
//    }
//  }
//  
//  /// Handles the selection of a library entry.
//  void handleLibraryEntrySelected(LibraryEntry entry) {
//    // Set the selected entry (Will trigger the call of selectedEntryChanged).
//    selectedEntry = entry;
//  }
//
//  /// Handles a reject of topic (for selected library entry).
//  void handleTopicRejected(Event event, Map detail) {
//    retardEvent(event);
//    // Reject library entry from topic.
//    rejectLibraryEntryFromTopic(detail['entry'], detail['topicId']);
//  }
//  
//  /// Handles an invitation from the logged-in user to another user.
//  void handleUserHasInvited(Event event, Map details) {
//    retardEvent(event);
//    // Invite the user to entry.
//    inviteUserToEntry(details['entry'], details['userId']); 
//  }
//  
//  /// Handles a disinvitation of participant.
//  void handleParticipantDisinvited(Event event, Map detail) {
//    retardEvent(event);
//    // Unsubscribe the participant.
//    unsubscribeParticipantFromLibraryEntry(detail['entry'], detail['user']);
//  }
//  
//  /// Handles a disinvitation of invitee.
//  void handleInviteeDisinvited(Event event, Map detail) {
//    retardEvent(event);
//    // Unsubscribe the participant.
//    unsubscribeInviteeFromLibraryEntry(detail['entry'], detail['user']);
//  }
//
//  /// Handles a new tag.
//  void handleTagAdded(Event event, Map detail) {
//    retardEvent(event);
//    // Unsubscribe the participant.
//    addTag(detail['entry'], detail['tag']);
//  }
//   
//  /// Handles an update of a tag.
//  void handleTagUpdated(Event event, Map detail) {
//    retardEvent(event);
//    updateTag(detail['entry'], detail['index'], detail['new']);
//  }
//   
//  /// Handles a deletion of a tag.
//  void handleTagDeleted(Event event, Map detail) {
//    retardEvent(event);
//    deleteTag(detail['entry'], detail['index']);
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Adds a feed entry.
//  Future addFeedEntry() {
//    return setFeedEntry(new FeedEntry(data, false)..userId = user.id);
//  }
//  
//  /// Updates the given feed entry.
//  void updateFeedEntry(FeedEntry feed) {
//    if (feed == null) return;
//    setFeedEntry(feed..modified = new DateTime.now());
//  }
//  
//  /// Updates the given library entry.
//  void updateLibraryEntry(LibraryEntry entry) {
//    if (entry == null) return;
//    setLibraryEntry(entry..modified = new DateTime.now());
//  }
//  
//  /// Deletes a feed entry.
//  void deleteFeedEntry(FeedEntry feed) { 
//    actions.deleteFeedEntry(selectedEntry, feed);
//  }
//    
//  /// Deletes the given library entry.
//  void deleteLibraryEntry(LibraryEntry entry) {
//    actions.uninstallLibraryEntry(entry);
//  }
//  
//  /// Adds the given tag to the given entry.
//  void addTag(LibraryEntry entry, String tag) {
//    if (entry == null) return;
//    if (tag == null) return;
//    List tags = tag.split(new RegExp(r'[\,\;]'));
//    List entryTags = entry.tags != null ? entry.tags : [];
//    tags.forEach((String tag) {
//      tag = tag.trim().replaceAll(" ", "_");
//      // Add the tag to the list of tags of entry.
//      entryTags.add(tag);
//    });
//    updateLibraryEntry(entry..tags = entryTags);
//  }
//  
//  /// Updates the tag at given index.
//  void updateTag(LibraryEntry entry, int index, String tag) {
//    if (entry == null) return;
//    if (index == null) return;
//    if (tag == null) return;
//    if (entry.tags == null) return;
//    if (index < 0) return;
//    if (index > entry.tags.length - 1) return;
//    tag = tag.trim().replaceAll(" ", "_");
//    // Remove the tag at the given index.
//    entry.tags = entry.tags..[index] = tag;
//    updateLibraryEntry(entry);
//  }
//   
//  /// Deletes the tag at given index from given entry.
//  void deleteTag(LibraryEntry entry, int index) {
//    if (entry == null) return;
//    if (index == null) return;
//    if (entry.tags == null) return;
//    if (index < 0) return;
//    if (index > entry.tags.length - 1) return;
//    // Remove the tag at the given index.
//    entry.tags = entry.tags..removeAt(index);
//    updateLibraryEntry(entry);
//  }
//  
//  /// Unsubscribes the logged-in user from given library entry.
//  void unsubscribeUserFromLibraryEntry(LibraryEntry entry) {
//    actions.unsubscribeUserFromEntry(user, entry, false);
//  }
//  
//  /// Disinvites the given participant from library entry.
//  void unsubscribeParticipantFromLibraryEntry(LibraryEntry entry, User user) {
//    actions.unsubscribeUserFromEntry(user, entry, true);
//  }
//   
//  /// Disinvites the given invitee from library entry.
//  void unsubscribeInviteeFromLibraryEntry(LibraryEntry entry, User user) {
//    actions.unsubscribeUserFromEntry(user, entry, true);
//  }
//  
//  /// Rejects the given topic from given entry.
//  void rejectLibraryEntryFromTopic(LibraryEntry entry, String topicId) {
//    actions.rejectLibraryEntryFromTopic(entry.id, topicId);
//  }
//  
//  /// Sets the given feed entry.
//  Future setFeedEntry(FeedEntry feed, [LibraryEntry libraryEntry]) {
//    if (libraryEntry != null) return actions.setFeedEntry(libraryEntry, feed);
//    return actions.setFeedEntry(selectedEntry, feed);
//  }
//  
//  /// Sets the given library entry.
//  Future setLibraryEntry(LibraryEntry entry) {
//    return actions.setLibraryEntry(entry);
//  }
//   
//  /// Invites the given user to given entry.
//  void inviteUserToEntry(var entry, var user) {
//    actions.inviteUserToEntry(entry, user);
//  }
//  
//  // ___________________________________________________________________________
//  // Display methods.
//    
//  /// Fills the feed for the given entry.
//  void fill() {    
//    feedEntries.clear();
//    feedEntries.addAll(actions.getFeedEntries(selectedEntry));
//  }
//    
//  /// Reveals a feed entry, i.e. adds the feed entry, if it isn't present in 
//  /// feed and updates it otherwise.
//  void revealFeedEntry(FeedEntry feed) {
//    if (feed == null) return;
//    if (selectedEntry == null) return;
//    feedEntries[feed.id] = feed;
//  }
//  
//  /// Unreveals the given feed entry from display.
//  void unrevealFeedEntry(FeedEntry feed) {
//    if (feed == null) return;
//    if (selectedEntry == null) return;
//    feedEntries.remove(feed.id);
//  }
//  
//  /// Reveals the selected library entry.
//  void revealLibraryEntry(LibraryEntry entry) {
//    this.selectedEntry = entry;
//    this.selectedEntryInList[0] = selectedEntry;
//  }
//    
//  /// Sorts.
//  void sort(var sortField, {bool asc: false}) {
//    String field = sortField is SortField ? sortField.display : sortField;
//    sortAscending = (field != selectedSortField || asc) ? true: !sortAscending;
//    selectedSortField = field; 
//    setSortCssLabel(get(field), sortAscending ? "asc" : "desc");
//  }
//  
//  /// Resets the data.
//  void resetData() {
//    this.data = null;
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Sorts the entries according to given field. If this field is already the 
//  /// current sorting field then reverse the sort
//  Function sortBy(String sortField, bool ascending) {
//    return (Iterable<FeedEntry> entries) { 
//      if (sortField == null) return entries;
//      var list = entries.toList()..sort(SortField.comparators[sortField]);
//      return ascending ? list : list.reversed;    
//    };
//  }
//  
//  /// Filters the feeds by given query.
//  Function filterByType(List<String> types) {
//    return (Iterable<FeedEntry> feedEntries) {
//      if (feedEntries == null) return [];
//      return feedEntries.where((entry) => filterFeedEntryByType(entry, types)); 
//    };
//  }
//  
//  /// Filters the feeds by given query.
//  Function filterByQuery(String query) {
//    return (Iterable<FeedEntry> feedEntries) {
//      if (feedEntries == null) return [];
//      return feedEntries.where((entry) => filterFeedEntryByQuery(entry, query)); 
//    };
//  }
//    
//  // ___________________________________________________________________________
//  // Helper methods.
//  
//  String createActivityText(ActivityType type, User user) {
//    switch (type) {
//      case ActivityType.CREATED:
//        return "Entry was created by ${user.firstName} ${user.lastName}.";
//      case ActivityType.INVITED:
//        return "User ${user.firstName} ${user.lastName} was invited.";
//      case ActivityType.UNSUBSCRIBED:
//        return "User ${user.firstName} ${user.lastName} was unsubscribed.";
//      case ActivityType.TOPIC_ASSIGNED:
//        return "Entry was assigned to new topic.";
//      case ActivityType.TOPIC_REJECTED:
//        return "Entry was rejected from topic.";
//      default:
//        return null;
//    }
//  }
//}
//
////// The sort fields.
//class SortField {
//  final String display;
//  final String field;
//  const SortField._internal(this.display, this.field);
//  static const FIRST = const SortField._internal("CreationDate", "created");
//  static const SECOND = const SortField._internal("Content", "data");
//    
//  static Map<String, Function> comparators = {
//    FIRST.display: IceciteElement.getComparator(FIRST.field),
//    SECOND.display: IceciteElement.getComparator(SECOND.field),
//  };
//}