@MirrorsUsed(targets: 'LibraryEntry')
library library_view;

import 'dart:html';
import 'dart:mirrors';
import 'package:polymer/polymer.dart' hide ObservableMap;
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../utils/search/search_util.dart' as s;
import '../utils/observable_map.dart';
import '../utils/html/location_util.dart';

/// The library-view, showing the entries of library.
@CustomTag('library-view')
class LibraryView extends IceciteElement {  
  // The members of library.
  @observable Map<String, LibraryEntry> entries = new ObservableMap();
  // The members of a search in an external library.
  @observable List<LibraryEntry> searchEntries = toObservable([]);
  // The available sort fields.
  @observable List<String> sortFields = toObservable(SortField.comparators.keys.toList());
  // The selected sort field.
  @observable String selectedSortField;
  // True, if the entries should be sorted ascending, false otherwise.
  @observable bool sortAscending = true;
  // The ids of selected topics.
  @observable List<String> selectedTopicIds = toObservable([]);
         
  /// The default constructor.
  LibraryView.created() : super.created();
     
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("views/library_view.css"));
    
    // Wait until the library entries are cached.
    if (actions.areLibraryEntriesFilled()) fill();
    actions.onLibraryEntriesFilled.listen((_) => fill());
    actions.onLibraryEntryChanged.listen(libraryEntryChangedHandler);
    actions.onLibraryEntryDeleted.listen(libraryEntryDeletedHandler);
  }
  
  void revealedHandler() {
    super.revealedHandler();
    if (selectedSortField == null) sort(SortField.FIRST, asc: true);
  }
  
  // Override
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
      
  /// Define the behavior when an entry in storage was added or updated.
  void libraryEntryChangedHandler(LibraryEntry entry) {
    if (entry == null) return;
    if (entry.formerUserIds != null && entry.formerUserIds.contains(user.id)) {
      rejectFormerUser(entry);
    } else if (entry.userIds != null && entry.userIds.contains(user.id)) {
      // The entry is shared with user.
      revealLibraryEntry(entry); 
    } else {
      // The entry doesn't belong to user. Delete it.
      libraryEntryDeletedHandler(entry);
    }
  }
             
  /// Define the behavior when an entry in storage was deleted.
  void libraryEntryDeletedHandler(LibraryEntry entry) {
    unrevealLibraryEntry(entry);
    fire("deleted-entry", detail: entry.id);
  }
    
  /// This method is called, whenever the selection of topics has changed.
  void topicsSelectedHandler(event, tops, target) => handleTopicSelection(tops);
    
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// Will add an entry for each uploaded file in fileList.
  void onUploadFilesPurpose(event, files, target) => uploadFiles(files);
  
  /// Will add an entry for the given file.
  void onUploadFilePurpose(event, file, target) => uploadFile(file);
  
  /// This method is called, whenever file(s) were uploaded.
  void onUrlUploadPurpose(event, url, target) => uploadViaUrl(url);
  
  /// Will update the given entry in storage.
  void onUpdateEntryPurpose(event, entry, target) => updateLibraryEntry(entry);
  
  /// Will delete the given entry from storage.
  void onDeleteEntryPurpose(event, entry, target) => deleteLibraryEntry(entry);
    
  /// Will search the database.
  void onSearchPurpose(query) => search(query);
  
  /// Will cancel the search.
  void onCancelSearchPurpose() => cancelSearch();
    
  /// Will sort the library.
  void onSortPurpose(event, entry, target) => sort(target.dataset['field']);
  
  /// This method is called, whenever a library entry was selected.
  void onSelectLibraryEntryPurpose(event, entry, target) {}
  
  /// Will reject the given topic from given entry.
  void onRejectTopicPurpose(e, d, t) => rejectTopic(d['entryId'], d['topicId']);
      
  /// Will unshare the given entry from given user.
  void onRejectUserPurpose(e, d, t) => rejectUser(d['entry'], d['user']);
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Uploads the given files.
  void uploadFiles(List<File> files) {
    if (files == null) return;
    files.forEach((file) => uploadFile(file));
  }
  
  /// Uploads the given file.
  void uploadFile(File f) {
    if (f == null) return;
    actions.installLibraryEntry(new LibraryEntry("entry", f.name, user), f);
  }
  
  /// Uploads the file given by url.
  void uploadViaUrl(String url) {
    if (url == null) return;
    actions.installLibraryEntry(new LibraryEntry("entry", url, user)..ee = url);
  }
  
  /// Updates the given library entry.
  void updateLibraryEntry(entry) {
    actions.setLibraryEntry(entry); 
  }
  
  /// Deletes the given library entry.
  void deleteLibraryEntry(entry) {
    actions.uninstallLibraryEntry(entry); 
  }
    
  /// Handles the actual topic selection.
  void handleTopicSelection(topics) {
    selectedTopicIds = toObservable(new List.from(topics));
  }
     
  /// Checks, if the given entry / entries needs to be matched.
  void matchIfNecessary(var entries) {        
    if (entries == null) return;
    if (entries is LibraryEntry) {
      // Match, if there is no external key.
      if (entries.externalKey == null) {
        if (entries.attachments != null || entries.ee != null) {
          loading("Retrieving metadata", pouchable: entries);
          actions.matchLibraryEntry(entries)
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
              .catchError((e) => error(e.toString(), pouchable: entry));
          }
        }
      }); 
    }
  }
  
  /// Searches.
  void search(String query) {
    this.searchQuery = query;
    this.searchEntries.clear();
    s.search(this.searchQuery).then((res) => searchEntries = toObservable(res));
  }
  
  /// Cancels the search.
  void cancelSearch() {
    this.searchQuery = null;
    this.searchEntries.clear();
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
      
  /// Rejects the given entry from given entry.
  void rejectTopic(String entryId, String topicId) {
    actions.rejectLibraryEntryFromTopic(entryId, topicId);
  }
  
  /// Unshares the given entry from given user.
  void rejectUser(LibraryEntry entry, User user) {
    actions.rejectEntryFromUser(entry, user);
  }
  
  /// Rejects former user.
  void rejectFormerUser(LibraryEntry entry) {
    actions.rejectFormerUserFromEntry(user, entry);
  }
  
  // ___________________________________________________________________________
  // Display methods.
   
  /// Fills the library.
  void fill() {
    Map params = LocationUtil.getUrlParams(window.location.hash);
    this.searchQuery = params['q'];
    
    actions.getLibraryEntries().forEach((key, entry) {
      entries[entry.id] = entry;
      matchIfNecessary(entry);
    });
  }
      
  /// Reveals a library entry, i.e. adds the entry, if it isn't present in
  /// library and updates it otherwise.
  void revealLibraryEntry(LibraryEntry entry) {
    if (entry == null) return;
    if (entry.userIds == null) return;
    if (!entry.userIds.contains(user.id)) return; 
    
    fire("activity");
    if (!entries.containsKey(entry.id)) info("new", pouchable: entry);
    else info("updated", pouchable: entry);
    
    entries[entry.id] = entry;
    matchIfNecessary(entry);
  }
            
  /// Discards the given entry from display.
  LibraryEntry unrevealLibraryEntry(entry) => entries.remove(entry.id); 
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