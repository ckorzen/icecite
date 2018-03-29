@MirrorsUsed(targets: 'LibraryEntry')
library library_view;

import 'dart:async';
import 'dart:html' hide Notification;
import 'dart:mirrors';
import 'package:polymer/polymer.dart' hide ObservableMap;
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../elements/library_entry_element.dart';
import '../utils/search/search_util.dart' as s;
import '../utils/observable_map.dart';
import '../utils/html/notification_util.dart';
import '../actions/actions.dart';

/// The library-view, showing the entries of library.
@CustomTag('library-view')
class LibraryView extends IceciteElement {  
  /// The entries to show.
  @observable Map<String, LibraryEntry> entries = new ObservableMap();
  /// The entries of search result.
  @observable Map<String, LibraryEntry> searchEntries = new ObservableMap();
  /// The sort fields.
  @observable List<String> sortFields = toObservable(SortField.comparators.keys.toList());
  /// The selected sort field.
  @observable String selectedSortField;
  /// True, if the entries should be sorted ascending, false otherwise.
  @observable bool sortAscending = true;
  /// The ids of selected topics.
  @observable List<String> selectedTopicIds = toObservable([]);
  
  /// The activity counters.
  Map<String, int> activityCounters = {};
  Element htmlContainer;
  
  /// The name of "entry-deleted" event.
  static const String EVENT_ENTRY_DELETED = "entry-deleted";
  /// The name of "entry-selected" event.
  static const String EVENT_ENTRY_SELECTED = "entry-selected";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  LibraryView.created() : super.created();
  
  @override
  void attached() {
    super.attached();
    // Wait until the library entries are cached.
    if (actions.areLibraryEntriesFilled()) fill();
    actions.onLibraryEntriesFilled.listen((_) => fill());
    actions.onLibraryEntryChanged.listen(onLibraryEntryChangedInDb);
    actions.onLibraryEntryDeleted.listen(onLibraryEntryDeletedInDb);
//    actions.onActivity.listen(onActivity);
  }
  
  void ready() {
    
  }
      
  @override
  void resetOnLogout() { 
    super.resetOnLogout();
    if (this.entries != null) this.entries.clear();
    if (this.searchEntries != null) this.searchEntries.clear();
    if (this.selectedTopicIds != null) this.selectedTopicIds.clear();
    this.selectedSortField = null;
    this.sortAscending = true;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever the selected entry was changed.
  void selectedEntryChanged(prevEntry) => handleSelectedEntryChange(prevEntry);
  
  /// This method is called, whenever the view was revealed.
  void onRevealed() => handleRevealed();
      
  /// The notification handler.
  void onNotification(event) => handleNotification(event);
  
  /// This method is called, whenever a library entry was changed in db.
  void onLibraryEntryChangedInDb(entry) => handleLibraryEntryChangedInDb(entry);
               
  /// This method is called, whenever a library entry was deleted in db.
  void onLibraryEntryDeletedInDb(entry) => handleLibraryEntryDeletedInDb(entry);
  
  /// This method is called, whenever a library entry was updated.
  void onLibraryEntryUpdated(evt, entr) => handleLibraryEntryUpdated(evt, entr);
  
  /// This method is called, whenever a library entry was deleted.
  void onLibraryEntryDeleted(evt, entr) => handleLibraryEntryDeleted(evt, entr);
  
  /// This method is called, whenever a library entry was selected.
  void onLibraryEntrySelected(entry) => handleLibraryEntrySelected(entry);
  
//  /// This method is called, whenever there is an activity.
//  void onActivity(activity) => handleActivity(activity);
        
  /// This method is called, whenever the selection of topics has changed.
  void onTopicsSelected(topicIds) => handleTopicsSelected(topicIds);
  
  /// This method is called, whenever file(s) were selected for upload.
  void onFilesUpload(files) => handleFilesUpload(files);
  
  /// This method is called, whenever an url to file to upload was entered.
  void onUrlUpload(url) => handleUrlUpload(url); 
  
  /// This method is called, whenever a search query was typed.
  void onSearchQueryTyped(query) => handleSearchQueryTyped(query);
  
  /// This method is called, whenever a search was cancelled.
  void onSearchCancelled() => handleSearchCancelled();
    
  /// This method is called, whenever a sort field was clicked.
  void onSortFieldClicked(evt, d, trgt) => handleSortFieldClicked(evt, trgt);
   
  /// This method is called, whenever a topic was rejected from topic.
  void onTopicRejected(event, details) => handleTopicRejected(event, details);
    
  /// This method is called, whenever the logged-in user was invited to a entry.
  void onUserIsInvited(entry) => handleUserIsInvited(entry);
  
  /// This method is called, when the logged-in user was disinvited from entry.
  void onUserIsDisinvited(entry) => handleUserIsDisinvited(entry);
  
  /// This method is called, whenever the logged-in user has invited another 
  /// user to an entry.
  void onUserHasInvited(event, details) => handleUserHasInvited(event, details);
  
  /// This method is called, when a participant was disinvited from entry.
  void onParticipantDisinvited(event, details) => 
      handleParticipantDisinvited(event, details);
  
  /// This method is called, when a participant was disinvited from entry.
  void onInviteeDisinvited(event, details) => 
      handleInviteeDisinvited(event, details);
  
  /// This method is called, when a tag was added to an entry.
  void onTagAdded(event, details) => handleTagAdded(event, details);
  
  /// This method is called, when a tag was updated.
  void onTagUpdated(event, details) => handleTagUpdated(event, details);
  
  /// This method is called, when a tag was deleted.
  void onTagDeleted(event, details) => handleTagDeleted(event, details);
   
  /// This method is called, whenever a previous-entry-request occurs.
  void onPreviousEntryRequest() => handlePreviousEntryRequest();
  
  /// This method is called, whenever a next-entry-request occurs.
  void onNextEntryRequest() => handleNextEntryRequest();
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Handles the change of selected entry.
  void handleSelectedEntryChange(LibraryEntry prevEntry) {
    if (prevEntry != null) prevEntry.selected = false;
    
    // TODO
    LibraryEntry entry = entries[selectedEntry.id];
    if (entry != null) {
      entry.selected = true; 
    } else if (selectedEntry != null) {
      selectedEntry.selected = true;
    }
  }
  
  /// Reveals the elements of this view.
  void handleRevealed() {
    // Sort the feeds by the first sort field by default.
    print("handle revealed: ${selectedSortField}");
    if (selectedSortField == null) sort(SortField.FIRST, asc: false);
    this.htmlContainer = get("scroll-area");
  }
  
  /// Handles a notification.
  void handleNotification(NotificationEvent event) {
    if (event == null) return;
    String entryId = event.pouchId;
    Notification notification = event.notification;
    if (entryId == null) return;
    if (notification == null) return;
    
    /// Set the notification to related entry.
    if (entries.containsKey(entryId)) {
      LibraryEntry entry = entries[entryId]; 
      if (entry != null) entry.notification = notification;
    }
    
    if (searchEntries.containsKey(event.pouchId)) {
      LibraryEntry entry = searchEntries[entryId]; 
      if (entry != null) entry.notification = notification;
    }
  }
  
  /// Handles the change of a library entry.
  void handleLibraryEntryChangedInDb(LibraryEntry entry) {
    if (user.isInvited(entry)) onUserIsInvited(entry);
    else if (user.isDisinvited(entry)) onUserIsDisinvited(entry); 
    else if (user.isOwnerOrParticipant(entry)) revealLibraryEntry(entry);
    else onLibraryEntryDeletedInDb(entry);
  }
  
  /// Handles the deletion of a library entry.
  void handleLibraryEntryDeletedInDb(LibraryEntry entry) {
    // Unreveal the entry.
    unrevealLibraryEntry(entry);
    // Fire 'entry-deleted' event.
    fireEntryDeletedEvent(entry);
  }

  /// Handles an update of library entry.
  void handleLibraryEntryUpdated(Event event, LibraryEntry entry) {
    retardEvent(event);
    // Update the library entry.
    updateLibraryEntry(entry);
  }
  
  /// Handles a update of deletion of feed entry.
  void handleLibraryEntryDeleted(Event event, LibraryEntry entry) {
    retardEvent(event);
    // Distinguish if user is the owner.
    if (user.isOwner(entry)) {
      // The user is the owner. So delete the library entry.
      deleteLibraryEntry(entry); 
    } else {
      // The user isn't the owner. So unsubscribe the user.
      unsubscribeUserFromLibraryEntry(entry);
    }
  }
  
  /// Handles a selection of a library entry.
  void handleLibraryEntrySelected(LibraryEntry entry) {
    // Set the selected entry (Will trigger the call of selectedEntryChanged).
    selectedEntry = entry;
  }
  
//  /// Handles an activity.
//  void handleActivity(Activity activity) {
//    if (activity == null) return;
//    if (activity.entry == null) return;
//    if (activityCounters.containsKey(activity.entry.id))
//      activityCounters[activity.entry.id] += 1;
//    else 
//      activityCounters[activity.entry.id] = 1;
//    activity.entry.activityCounter = activityCounters[activity.entry.id];
//  }
   
  /// Handles the actual topic selection.
  void handleTopicsSelected(Iterable topicIds) {
    // Set the selectedTopicIds.
    selectedTopicIds = toObservable(new List.from(topicIds));
  }
  
  /// Handles an upload of files.
  void handleFilesUpload(Iterable files) {
    // Install the files.
    installFiles(files);
  }
  
  /// Handles an upload via url.
  void handleUrlUpload(String url) {
    // Install the files.
    installUrl(url);
  }
  
  /// Handles a search query.
  void handleSearchQueryTyped(String query) {
    // Set searchQuery.
    this.searchQuery = query;
    this.searchEntries.clear();
    // Search externally.
    searchExternally().then((Map map) {
      searchEntries.addAll(map);
    });
  } 
  
  /// Handles a cancellation of search.
  void handleSearchCancelled() {
    // Reset searchQuery.
    this.searchQuery = null;
    this.searchEntries.clear();
  }
  
  /// Handles a click on sort field.
  void handleSortFieldClicked(Event event, HtmlElement target) {
    retardEvent(event);
    if (target == null) return;
    // Sort by given field.
    sort(target.dataset['field']);
  }
  
  /// Handles a reject of topic (for selected library entry).
  void handleTopicRejected(Event event, Map detail) {
    retardEvent(event);
    // Reject library entry from topic.
    rejectLibraryEntryFromTopic(detail['entry'], detail['topicId']);
  }
  
  /// Handles a invitation of the logged-in user to given entry.
  void handleUserIsInvited(LibraryEntry entry) {
    // Acknowledge the invite request.
    acknowledgeInviteRequest(entry); 
  }
  
  /// Handles a disinvitation of the logged-in user from given topic.
  void handleUserIsDisinvited(LibraryEntry entry) {
    // Acknowledge the disinvite request.
    acknowledgeDisinviteRequest(entry); 
  }
  
  /// Handles an invitation from the logged-in user to another user.
  void handleUserHasInvited(Event event, Map details) {
    retardEvent(event);
    // Invite the user to entry.
    inviteUserToEntry(details['entry'], details['userId']); 
  }
  
  /// Handles a disinvitation of participant.
  void handleParticipantDisinvited(Event event, Map detail) {
    retardEvent(event);
    // Unsubscribe the participant.
    unsubscribeParticipantFromLibraryEntry(detail['entry'], detail['user']);
  }
  
  /// Handles a disinvitation of invitee.
  void handleInviteeDisinvited(Event event, Map detail) {
    retardEvent(event);
    // Unsubscribe the participant.
    unsubscribeInviteeFromLibraryEntry(detail['entry'], detail['user']);
  }
  
  /// Handles a new tag.
  void handleTagAdded(Event event, Map detail) {
    retardEvent(event);
    // Unsubscribe the participant.
    addTag(detail['entry'], detail['tag']);
  }
  
  /// Handles an update of a tag.
  void handleTagUpdated(Event event, Map detail) {
    retardEvent(event);
    updateTag(detail['entry'], detail['index'], detail['new']);
  }
  
  /// Handles a deletion of a tag.
  void handleTagDeleted(Event event, Map detail) {
    retardEvent(event);
    deleteTag(detail['entry'], detail['index']);
  }
  
  /// Handles a previous-entry request.
  void handlePreviousEntryRequest() {
    var prevEntry = _getPreviousLibraryEntry();
    if (prevEntry != null && prevEntry.rev != null) {
      // Fire entry selected event, if it has a rev (is a member of library).
      fireLibraryEntrySelectedEvent(prevEntry);
    }
  }
  
  /// Handles a next-entry request.
  void handleNextEntryRequest() {
    var nextEntry = _getNextLibraryEntry();
    if (nextEntry != null && nextEntry.rev != null) {
      // Fire entry selected event, if it has a rev (is a member of library).
      fireLibraryEntrySelectedEvent(nextEntry);
    }
  }
    
  // ___________________________________________________________________________
    
  /// Uploads the given files.
  void installFiles(List<File> files) {
    if (files == null) return;
    files.forEach((file) => installFile(file));
  }
  
  /// Uploads the given file.
  void installFile(File file) {
    if (file == null) return;
    installLibraryEntry(new LibraryEntry("entry", file.name, user), file)
      .then((entry) => success("Library entry was installed successfully", pouchable: entry));
  }
  
  /// Uploads the file given by url.
  void installUrl(String url) {
    if (url == null) return;
    installLibraryEntry(new LibraryEntry("entry", url, user)..ee = url)
      .then((entry) => success("Library entry was installed successfully", pouchable: entry));
  }
  
  /// Sorts.
  void sort(var sortField, {bool asc}) {
    String field = sortField is SortField ? sortField.display : sortField;
//    sortAscending = (field != selectedSortField || asc) ? true: !sortAscending;
    sortAscending = asc != null ? asc : !sortAscending;
    selectedSortField = field; 
    setSortCssLabel(get(field), sortAscending ? "asc" : "desc");
  }
  
  /// Searches externally.
  Future<Map> searchExternally() {
    return s.search(searchQuery);
  }
  
  /// Checks, if the given entry / entries needs to be matched. TODO: Refactor.
  void _matchIfNecessary(var entries) { 
    if (entries == null) return;
    if (entries is LibraryEntry) {
      // Match, if there is no external key.
      if (entries.externalKey == null) {
        if (entries.attachments != null || entries.ee != null) {
          loading("Retrieving metadata", pouchable: entries);
          actions.matchLibraryEntry(entries)
            .then((_) => success("Metadata successfully retrieved.", pouchable: entries))
            .catchError((e) => error(e.toString(), pouchable: entries));
        }
      }
    } else if (entries is List) {
      entries.forEach((LibraryEntry entry) {
        // Match, if there is no external key and entry has attachments.
        if (entry.externalKey == null) {
          if (entry.attachments != null || entry.ee != null) {
            loading("Retrieving metadata", pouchable: entry);
            actions.matchLibraryEntry(entry)
              .then((_) => success("Metadata successfully retrieved.", pouchable: entry))
              .catchError((e) => error(e.toString(), pouchable: entry));
          }
        }
      }); 
    }
  }
   
  /// Resets the activity counter of given entry.
  void resetActivityCounter(LibraryEntry entry) {
    if (entry == null) return;
    activityCounters.remove(entry.id);
    entry.activityCounter = 0;
  }
  
  // __________________________________________________________________________
  
  /// Installs the given library entry.
  Future installLibraryEntry(LibraryEntry entry, [File file]) {
    return actions.installLibraryEntry(entry, file);
  }
  
  /// Updates the given library entry.
  void updateLibraryEntry(LibraryEntry entry) {
    if (entry == null) return;
    setLibraryEntry(entry..modified = new DateTime.now());
  }
    
  /// Deletes the given library entry.
  void deleteLibraryEntry(LibraryEntry entry) {
    actions.uninstallLibraryEntry(entry);
  }
  
  /// Adds the given tag to the given entry.
  void addTag(LibraryEntry entry, String tag) {
    if (entry == null) return;
    if (tag == null) return;
    List tags = tag.split(new RegExp(r'[\,\;]'));
    List entryTags = entry.tags != null ? entry.tags : [];
    tags.forEach((String tag) {
      tag = tag.trim().replaceAll(" ", "_");
      // Add the tag to the list of tags of entry.
      entryTags.add(tag);
    });
    updateLibraryEntry(entry..tags = entryTags);
  }
  
  /// Updates the tag at given index.
  void updateTag(LibraryEntry entry, int index, String tag) {
    if (entry == null) return;
    if (index == null) return;
    if (tag == null) return;
    if (entry.tags == null) return;
    if (index < 0) return;
    if (index > entry.tags.length - 1) return;
    tag = tag.trim().replaceAll(" ", "_");
    // Remove the tag at the given index.
    entry.tags = entry.tags..[index] = tag;
    updateLibraryEntry(entry);
  }
   
  /// Deletes the tag at given index from given entry.
  void deleteTag(LibraryEntry entry, int index) {
    if (entry == null) return;
    if (index == null) return;
    if (entry.tags == null) return;
    if (index < 0) return;
    if (index > entry.tags.length - 1) return;
    // Remove the tag at the given index.
    entry.tags = entry.tags..removeAt(index);
    updateLibraryEntry(entry);
  }
  
  /// Unsubscribes the logged-in user from given library entry.
  void unsubscribeUserFromLibraryEntry(LibraryEntry entry) {
    actions.unsubscribeUserFromEntry(user, entry, false);
  }
  
  /// Disinvites the given participant from library entry.
  void unsubscribeParticipantFromLibraryEntry(LibraryEntry entry, User user) {
    actions.unsubscribeUserFromEntry(user, entry, true);
  }
  
  /// Disinvites the given invitee from library entry.
  void unsubscribeInviteeFromLibraryEntry(LibraryEntry entry, User user) {
    actions.unsubscribeUserFromEntry(user, entry, true);
  }
  
  /// Rejects the given topic from given entry.
  void rejectLibraryEntryFromTopic(LibraryEntry entry, String topicId) {
    actions.rejectLibraryEntryFromTopic(entry.id, topicId);
  }
  
  /// Acknowledges an invite request.
  void acknowledgeInviteRequest(LibraryEntry topic) {
    actions.acknowledgeInviteRequest(user, topic);
  }
  
  /// Acknowleges a disinvite request.
  void acknowledgeDisinviteRequest(LibraryEntry topic) {
    actions.acknowledgeDisinviteRequest(user, topic);
  }
  
  /// Sets the given library entry.
  Future setLibraryEntry(LibraryEntry entry) {
    return actions.setLibraryEntry(entry);
  }
    
  /// Invites the given user to given entry.
  void inviteUserToEntry(var entry, var user) {
    actions.inviteUserToEntry(entry, user);
  }
  
  // ___________________________________________________________________________
  // Display methods.
  
  /// Fills the library.
  void fill() {    
   actions.getLibraryEntries().forEach((key, entry) {
     if (user.isOwnerOrParticipant(entry)) entries[entry.id] = entry;
     _matchIfNecessary(entry);
   });
  }
     
  /// Reveals a library entry, i.e. adds the entry, if it isn't present in
  /// library and updates it otherwise.
  void revealLibraryEntry(LibraryEntry entry) {
    if (entry == null) return;
    entry.activityCounter = activityCounters[entry.id];
    entry.notification = notificationUtil.getNotification(entry);
    if (searchEntries.containsKey(entry.id)) {
      searchEntries[entry.id] = entry;
    } else {
      entries[entry.id] = entry; 
    }
    _matchIfNecessary(entry);
  }
           
  /// Discards the given entry from display.
  void unrevealLibraryEntry(entry) {
    if (entry == null) return;
    entries.remove(entry.id); 
  }
  
  // ___________________________________________________________________________
  
  /// Sorts the entries according to given field. If this field is already the 
  /// current sorting field then reverse the sort
  Function sortBy(String sortField, bool ascending) {
    return (Iterable<LibraryEntry> entries) { 
      if (sortField == null) return entries;
      var list = entries.toList()..sort(SortField.comparators[sortField]);
      return ascending ? list : list.reversed;  
    };
  }
  
  /// Filters the entries by searchQuery.  
  Function filterByQuery(String q) {
    return (Iterable<LibraryEntry> entries) { 
      if (entries == null) return [];
      return entries.where((entry) => s.filterLibraryEntryByQuery(entry, q));
    };
  }
  
  /// Filters the entries by searchQuery.  
  Function filterByTopics(List<String> topics) {
    return (Iterable<LibraryEntry> entries) { 
      if (entries == null) return [];   
      return entries.where((entry) => s.filterByTopics(entry, topics));
    };
  }
          
  // ___________________________________________________________________________
  
  /// Fires an entry-selected event.
  void fireLibraryEntrySelectedEvent(LibraryEntry entry) {  
    fire(EVENT_ENTRY_SELECTED, detail: {'entry': entry});
  }
  
  /// Fires an "entry-deleted" event.
  void fireEntryDeletedEvent(LibraryEntry entry) {
    fire(EVENT_ENTRY_DELETED, detail: entry);
  }
  
  /// Returns the previous entry of selectedEntry.
  LibraryEntry _getPreviousLibraryEntry() {
    var htmlEntries = _getLibraryEntryHtmlElements();
    if (htmlEntries != null && htmlEntries.isNotEmpty) {
      int index = _getIndexOfSelectedLibraryEntry(htmlEntries);
      LibraryEntryElement element = null;
      if (index < 1) {
        element = htmlEntries[htmlEntries.length - 1];
      } else {
        element = htmlEntries[index - 1];
      }
      if (element != null) return element.entry;
    }
    return null;
  }
  
  /// Returns the next library entry of selectedEntry.
  LibraryEntry _getNextLibraryEntry() {
    var htmlEntries = _getLibraryEntryHtmlElements();
    if (htmlEntries != null && htmlEntries.isNotEmpty) {
      int index = _getIndexOfSelectedLibraryEntry(htmlEntries);
      LibraryEntryElement element = null;
      if (index == htmlEntries.length - 1) {
        element = htmlEntries[0]; // Build a circular structure.
      } else {
        element = htmlEntries[index + 1];
      }
      if (element != null) return element.entry;
    } 
    return null;
  }
      
  /// Returns a list of html elements of all library entries. 
  ElementList _getLibraryEntryHtmlElements() {
    return htmlContainer.querySelectorAll("library-entry-element");
  }
    
  /// Returns the html element of the selected entry.
  Element _getSelectedLibraryEntryHtmlElement() {
    if (selectedEntry != null) {
      return htmlContainer.querySelector("#id-${selectedEntry.id}");
    }
    return null;
  }  
    
  /// Returns the index of selected entry in given htmlEntries.
  int _getIndexOfSelectedLibraryEntry(htmlEntries) {
    var selectedHtmlElement = _getSelectedLibraryEntryHtmlElement();
      
    if (htmlEntries != null && selectedHtmlElement != null) {
      return htmlEntries.indexOf(selectedHtmlElement);
    }
    return -1;
  }
}

/// The sort fields.
class SortField {
  final String display;
  final String field;
  const SortField._internal(this.display, this.field);
  static const FIRST = const SortField._internal("CreationDate", "created");
  static const SECOND = const SortField._internal("Title", "title");
  static const THIRD = const SortField._internal("FirstAuthor", "authors");
  static const FOURTH = const SortField._internal("Journal", "journal");
  static const FIFTH = const SortField._internal("Year", "year");
    
  static Map<String, Function> comparators = {
    FIRST.display: IceciteElement.getComparator(FIRST.field),
    SECOND.display: IceciteElement.getComparator(SECOND.field),
    THIRD.display: IceciteElement.getComparator(THIRD.field),
    FOURTH.display: IceciteElement.getComparator(FOURTH.field),
    FIFTH.display: IceciteElement.getComparator(FIFTH.field),
  };
}