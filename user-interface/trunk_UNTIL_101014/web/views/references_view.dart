@MirrorsUsed(targets: 'LibraryEntry')
library references_view;

import 'dart:mirrors';
import 'package:polymer/polymer.dart' hide ObservableMap;
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../utils/search/search_util.dart';
import '../utils/observable_map.dart';

/// The references-view, showing the references of an individual entry.
@CustomTag('references-view')
class ReferencesView extends IceciteElement {  
  // The entries of library.
  @observable Map<String, LibraryEntry> references = new ObservableMap();
  // The sort fields.
  @observable List<String> sortFields = toObservable(SortField.comparators.keys.toList());
  // The selected sort field.
  @observable String selectedSortField;
  // True, if the entries should be sorted ascending, false otherwise.
  @observable bool sortAscending = true;
  /// For some reason, the selected entry isn't updated in view if the entry
  /// has changed. But putting the entry into a list works. So use this as a 
  /// workaround. 
  @observable List selectedEntryInList = toObservable([null]);  
 
  /// The default constructor.
  ReferencesView.created() : super.created();
     
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("views/references_view.css"));
  }
  
  void revealedHandler() {
    super.revealedHandler();
    if (selectedSortField == null) sort(SortField.FIRST, asc: true);
  }
  
  // Override.
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.references != null) this.references.clear();
    this.selectedEntry = null;
    this.selectedSortField = null;
    this.sortAscending = true;
    if (this.selectedEntryInList != null) this.selectedEntryInList[0] = null;
  }
  
  // ___________________________________________________________________________
  // Handlers.
    
  /// This method is automatically called, whenever the selected entry was
  /// changed, and is not called, when a property of the selected entry changed.
  void selectedEntryChanged(LibraryEntry prevSelectedEntry) {
    if (selectedEntry == null) return;
        
    this.selectedEntryInList[0] = selectedEntry;
    
    if (actions.areSupplementsFilled(selectedEntry)) fill();
    actions.onSupplementsFilled(selectedEntry).listen((_) => fill());
    actions.onReferenceChanged(selectedEntry).listen(referenceChangedHandler);
    actions.onReferenceDeleted(selectedEntry).listen(referenceDeletedHandler);
    actions.onLibraryEntryChanged.listen(libraryEntryChangedHandler);
    // cache.onLibraryEntryDeleted.listen(libraryEntryDeletedHandler);
  }
  
  /// Define the behavior when a reference in storage was added or updated.
  void referenceChangedHandler(reference) => revealReference(reference); 
  
  /// Define the behavior when a reference in storage was deleted.
  void referenceDeletedHandler(reference) => unrevealReference(reference);
  
  /// Define the behavior when a reference in storage was deleted.
  void libraryEntryChangedHandler(entry) => revealSelectedLibraryEntry(entry);
    
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// This method is called, whenever an entry was selected.
  void onSelectLibraryEntryPurpose(event, entry, target) { 
    selectedEntry = entry; // Will trigger the call of selectedEntryChanged.
  }
  
  /// Will update the given entry in storage.
  void onUpdateReferencePurpose(event, ref, target) => updateReference(ref);
  
  /// Will delete the given entry from storage.
  void onDeleteReferencePurpose(event, ref, target) => deleteReference(ref);
    
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
  
  /// Will sort the references.
  void onSortPurpose(event, entry, target) => sort(target.dataset['field']);
  
  /// Will reject the given user from selected entry.
  void onRejectUserPurpose(e, d, t) => rejectUser(d['entry'], d['user']);
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Updates the given entry.
  void updateReference(LibraryEntry ref) {
    actions.setReference(selectedEntry, ref..modified = new DateTime.now());
  }
  
  /// Deletes the given entry.
  void deleteReference(LibraryEntry reference) {
    actions.deleteReference(selectedEntry, reference);
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
    searchQuery = query;
  }
  
  /// Cancels the search.
  void cancelSearch() {
    searchQuery = null;
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
    
  /// Fills the references for the given entry.
  void fill() {    
    references.clear();           
    references.addAll(actions.getReferences(selectedEntry));
  }
      
  /// Reveals a reference, i.e. adds the references, if it isn't present in 
  /// library and updates it otherwise.
  void revealReference(LibraryEntry reference) {
    if (reference == null || selectedEntry == null) return;
    if (reference.citingEntryId != selectedEntry.id) return;
    
    fire("activity"); 
    if (!references.containsKey(reference.id)) info("new", pouchable: reference);
    else info("updated", pouchable: reference);
    
    references[reference.id] = reference;
  }
  
  /// Unreveals the given reference from display.
  void unrevealReference(LibraryEntry reference) {
    if (reference == null || selectedEntry == null) return;
    if (reference.citingEntryId != selectedEntry.id) return;
    references.remove(reference.id);
  }  
  
  /// Reveals a reference, i.e. adds the references, if it isn't present in 
  /// library and updates it otherwise.
  void revealSelectedLibraryEntry(LibraryEntry entry) {
    if (entry == null) return;
    if (entry != selectedEntry) return;
    if (entry.userIds == null) return;
    if (!entry.userIds.contains(user.id)) return;
    selectedEntry = entry;
    selectedEntryInList[0] = selectedEntry;
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
    return (Iterable<LibraryEntry> entries) { 
      if (sortField == null) return entries;
      var list = entries.toList()..sort(SortField.comparators[sortField]);
      return ascending ? list : list.reversed;  
    };
  }
   
  /// Filters the entries by searchQuery.  
  Function filterBy(String query) { 
    return (Iterable<LibraryEntry> refs) { 
      if (refs == null) return [];
      return refs.where((ref) => filterLibraryEntryByQuery(ref, query));
    };
  }
}

/// The sort fields.
class SortField {
  final String display;
  final String field;
  const SortField._internal(this.display, this.field);
  static const FIRST = const SortField._internal("CiteOrder", "positionInBibliography");
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