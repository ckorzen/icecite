//@MirrorsUsed(targets: 'LibraryEntry')
//library references_view;
//
//import 'dart:html';
//import 'dart:async';
//import 'dart:mirrors';
//import 'package:polymer/polymer.dart' hide ObservableMap;
//import '../models/models.dart';
//import '../elements/icecite_element.dart';
//import '../utils/search/search_util.dart';
//import '../utils/observable_map.dart';
//
////// The references-view, showing the references of an individual entry.
//@CustomTag('references-view')
//class ReferencesView extends IceciteElement {  
//  /// The references to show.
//  @observable Map<String, LibraryEntry> references = new ObservableMap();
//  /// The sort fields.
//  @observable List<String> sortFields = toObservable(SortField.comparators.keys.toList());
//  /// The selected sort field.
//  @observable String selectedSortField;
//  /// True, if the entries should be sorted ascending, false otherwise.
//  @observable bool sortAscending = true;
//  /// For some reason, the selected entry isn't updated in view if the entry
//  /// has changed. But putting the entry into a list works. So use this as a 
//  /// workaround. 
//  @observable List selectedEntryInList = toObservable([null]);  
// 
//  // ___________________________________________________________________________
//  
//  /// The default constructor.
//  ReferencesView.created() : super.created();
//       
//  @override
//  void resetOnLogout() {
//    super.resetOnLogout();
//    if (this.selectedEntryInList != null) this.selectedEntryInList[0] = null;
//    if (this.references != null) this.references.clear();
//    this.selectedSortField = null;
//    this.selectedEntry = null;
//    this.sortAscending = true;
//  }
//  
//  // ___________________________________________________________________________
//  // Handlers.
//    
//  /// This method is called, whenever the view was revealed.
//  void onRevealed() => handleRevealed();
//            
//  /// This method is called, whenever a reference was changed in db.
//  void onReferenceChangedInDb(ref) => handleReferenceChangedInDb(ref); 
//  
//  /// This method is called, whenever a reference was deleted in db.
//  void onReferenceDeletedInDb(ref) => handleReferenceDeletedInDb(ref);
//  
//  /// This method is called, whenever a reference was updated.
//  void onReferenceUpdated(event, ref) => handleReferenceUpdated(event, ref);
//  
//  /// This method is called, whenever a reference was deleted.
//  void onReferenceDeleted(event, ref) => handleReferenceDeleted(event, ref);
//
//  /// This method is called, whenever a search query was typed.
//  void onSearchQueryTyped(query) => handleSearchQueryTyped(query);
//  
//  /// This method is called, whenever a search was cancelled.
//  void onSearchCancelled() => handleSearchCancelled();
//  
//  /// This method is called, whenever a sort field was clicked.
//  void onSortFieldClicked(event, d, target) => 
//      handleSortFieldClicked(event, target);
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
//  void onLibraryEntrySelected(entry) => handleLibraryEntrySelected(entry);
//  
//  /// This method is called, whenever the selected library entry was updated.
//  void onLibraryEntryUpdated(evt, entr) => handleLibraryEntryUpdated(evt, entr);
//  
//  /// This method is called, whenever a library entry was deleted.
//  void onLibraryEntryDeleted(evt, entr) => handleLibraryEntryDeleted(evt, entr);
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
//       handleParticipantDisinvited(event, details);
//  
//  /// This method is called, whenever an invitee was disinvited from entry.
//  void onInviteeDisinvited(event, details) => 
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
//  }
//  
//  /// Handles a change of reference in db.
//  void handleReferenceChangedInDb(LibraryEntry ref) {
//    if (ref == null) return;
//    if (ref.citingEntryId != selectedEntry.id) return;    
//    // Reveal the feed entry.
//    revealReference(ref); 
//  }
//  
//  /// Handles a deletion of feed entry in db.
//  void handleReferenceDeletedInDb(LibraryEntry ref) {
//    if (ref == null) return;
//    if (ref.citingEntryId != selectedEntry.id) return;
//    // Unreveal the feed entry.
//    unrevealReference(ref); 
//  }
//  
//  /// Handles an update of feed entry.
//  void handleReferenceUpdated(Event event, LibraryEntry ref) {
//    retardEvent(event);
//    // Update the feed entry.
//    updateReference(ref);
//  }
//  
//  /// Handles a deletion of feed entry.
//  void handleReferenceDeleted(Event event, LibraryEntry ref) {
//    retardEvent(event);
//    // Delete the feed entry.
//    deleteReference(ref);
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
//  /// Handles a click on sort field.
//  void handleSortFieldClicked(Event event, HtmlElement target) {
//    retardEvent(event);
//    if (target == null) return;
//    // Sort by given field.
//    sort(target.dataset['field']);
//  }
//  
//  
//  /// Handles the change of selected entry.
//  void handleSelectedEntryChange() {
//    if (selectedEntry == null) return;
//    this.selectedEntryInList[0] = selectedEntry;    
//    if (actions.areSupplementsFilled(selectedEntry)) fill();
//    actions.onSupplementsFilled(selectedEntry).listen((_) => fill());
//    actions.onReferenceChanged(selectedEntry).listen(onReferenceChangedInDb);
//    actions.onReferenceDeleted(selectedEntry).listen(onReferenceDeletedInDb);
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
//  /// Handles the selection of a library entry.
//  void handleLibraryEntrySelected(LibraryEntry entry) {
//    // Set the selected entry (Will trigger the call of selectedEntryChanged).
//    selectedEntry = entry;
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
//  /// Handles a disinvitation of an invitee.
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
//  /// Updates the given feed entry.
//  void updateReference(LibraryEntry ref) {
//    if (ref == null) return;
//    setReference(ref..modified = new DateTime.now());
//  }
//  
//  /// Updates the given library entry.
//  void updateLibraryEntry(LibraryEntry entry) {
//    if (entry == null) return;
//    setLibraryEntry(entry..modified = new DateTime.now());
//  }
//  
//  /// Deletes a feed entry.
//  void deleteReference(LibraryEntry ref) { 
//    actions.deleteReference(selectedEntry, ref);
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
//  /// Sets the given reference.
//  Future setReference(LibraryEntry ref) {
//    return actions.setReference(selectedEntry, ref);
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
//  /// Fills the references for the given entry.
//  void fill() {    
//    references.clear();           
//    references.addAll(actions.getReferences(selectedEntry));
//  }
//      
//  /// Reveals a reference, i.e. adds the references, if it isn't present in 
//  /// library and updates it otherwise.
//  void revealReference(LibraryEntry reference) {
//    if (reference == null) return;
//    references[reference.id] = reference;
//  }
//  
//  /// Unreveals the given reference from display.
//  void unrevealReference(LibraryEntry reference) {
//    if (reference == null) return;
//    references.remove(reference.id);
//  }  
//  
//  /// Reveals a reference, i.e. adds the references, if it isn't present in 
//  /// library and updates it otherwise.
//  void revealLibraryEntry(LibraryEntry entry) {
//    selectedEntry = entry;
//    selectedEntryInList[0] = selectedEntry;
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
//  // ___________________________________________________________________________
//  
//  /// Sorts the entries according to given field. If this field is already the 
//  /// current sorting field then reverse the sort
//  Function sortBy(String sortField, bool ascending) {
//    return (Iterable<LibraryEntry> entries) { 
//      if (sortField == null) return entries;
//      var list = entries.toList()..sort(SortField.comparators[sortField]);
//      return ascending ? list : list.reversed;  
//    };
//  }
//   
//  /// Filters the entries by searchQuery.  
//  Function filterBy(String query) { 
//    return (Iterable<LibraryEntry> refs) { 
//      if (refs == null) return [];
//      return refs.where((ref) => filterLibraryEntryByQuery(ref, query));
//    };
//  }
//}
//
////// The sort fields.
//class SortField {
//  final String display;
//  final String field;
//  const SortField._internal(this.display, this.field);
//  static const FIRST = 
//      const SortField._internal("CiteOrder", "positionInBibliography");
//  static const SECOND = const SortField._internal("Title", "title");
//  static const THIRD = const SortField._internal("FirstAuthor", "authors");
//  static const FOURTH = const SortField._internal("Journal", "journal");
//  static const FIFTH = const SortField._internal("Year", "year");
//    
//  static Map<String, Function> comparators = {
//    FIRST.display: IceciteElement.getComparator(FIRST.field),
//    SECOND.display: IceciteElement.getComparator(SECOND.field),
//    THIRD.display: IceciteElement.getComparator(THIRD.field),
//    FOURTH.display: IceciteElement.getComparator(FOURTH.field),
//    FIFTH.display: IceciteElement.getComparator(FIFTH.field),
//  };
//}