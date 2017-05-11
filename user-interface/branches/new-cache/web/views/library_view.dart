@MirrorsUsed(targets: 'LibraryEntry')
library library_view;

import 'dart:async';
import 'dart:html' hide Notification, Entry, Animation;
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../elements/library_entry_element.dart';
import '../utils/search/search_util.dart' as s;
import '../transform/transform.dart';
import '../cache/library_entry_cache.dart';
import 'package:logging/logging.dart';
import 'package:animation/animation.dart';

/// The library-view, showing the entries of library.
@CustomTag('library-view')
class LibraryView extends IceciteElement {  
  /// The logger.
  Logger LOG = new Logger("library-view");
  
  /// The library entry cache.
  @observable LibraryEntryCache cache;
  
  /// The sort fields.
  @observable List sortFields = toObservable(SortField.comparators.keys);
  /// The selected sort field.
  @observable String selectedSortField;
  /// True, if the entries should be sorted ascending, false otherwise.
  @observable bool sortAscending = true;
  /// True, if the view is in loading state.
  @observable bool isLoading = true;
  
  Element scrollArea;
  MutationObserver scrollAreaObserver;
       
  // ___________________________________________________________________________
  
  /// The default constructor.
  LibraryView.created() : super.created();
          
  @override
  void attached() {
    super.attached();
    this.scrollArea = get("scroll-area");
    this.scrollAreaObserver = new MutationObserver(handleScrollAreaMutation);
    this.scrollAreaObserver.observe(scrollArea, childList: true, subtree: true);
  }
  
  @override
  void reset() { 
    super.reset();
    this.selectedSortField = null;
    this.sortAscending = true;
  }
  
  // ___________________________________________________________________________
  // Listener methods.
  
  @override
  void onLogin(User user) {
    super.onLogin(user);
    cache = new LibraryEntryCache(user);
    if (cache.isFilled) isLoading = false;
    cache.onFilled.listen((_) => isLoading = false);
  }
  
  /// This method is called, whenever the view was revealed.
  void onRevealed() => handleRevealed();
    
  /// This method is called, whenever a library entry was updated.
  void onUpdateEntryRequest(evt, data) => handleUpdateEntryRequest(evt, data);
   
  /// This method is called, whenever a library entry was shared.
  void onShareEntryRequest(evt, data) => handleShareEntryRequest(evt, data);
  
  /// This method is called, whenever a library entry was unshared.
  void onUnshareEntryRequest(evt, data) => handleUnshareEntryRequest(evt, data);
  
  /// This method is called, when a tag was added to an entry.
  void onAddTagsRequest(evt, data) => handleAddTagsRequest(evt, data);
  
  /// This method is called, when a tag was updated.
  void onUpdateTagRequest(evt, data) => handleUpdateTagRequest(evt, data);
  
  /// This method is called, when a tag was deleted.
  void onDeleteTagRequest(evt, data) => handleDeleteTagRequest(evt, data);
  
  /// This method is called, whenever a sort field was clicked.
  void onSortRequest(evt, data, target) => handleSortRequest(evt, target);
     
  /// This method is called, whenever a pdf url was specified.
  void onAddPdfUrlRequest(evt, data) => handleAddPdfUrlRequest(evt, data);
  
  /// This method is called, whenever a repeat stripping request occurs.
  void onRepeatStrippingRequest(evt, data) => handleRepeatStrippingRequest(data);
  
  // ___________________________________________________________________________
  // Handler methods.
    
  /// Handles a mutation in scoll area. This method is needed to determine 
  /// newly added library entry elements and to scroll to them.
  void handleScrollAreaMutation(List mutations, MutationObserver observer) {
    List<LibraryEntryElement> peekedElements = [];
    
    mutations.forEach((mutation) {
      mutation.addedNodes.forEach((node) {
        if (node is LibraryEntryElement) {
          Entry entry = node.entry;
          if (entry is LibraryEntry && entry.isPeeked) {
            peekedElements.add(node);
          }
        }
      });      
    });
        
    // Scroll to the first added element.
    if (peekedElements.isNotEmpty) {
      scrollToElement(peekedElements.first).then((_) {
        peekedElements.forEach((element) => element.entry.unpeek());
      });
    }
  }
  
  /// Reveals the elements of this view.
  void handleRevealed() {
    // Sort the feeds by the first sort field by default.
    if (selectedSortField == null) sort(SortField.FIRST, asc: true);
  }
  
  /// Handles an update of library entry.
  void handleUpdateEntryRequest(Event event, Map details) {
    retardEvent(event);   
    Entry entry = details['entry'];
    if (entry == null) return;
    entry.enqueue(details['data']);
  }
           
  /// Handles a click on sort field.
  void handleSortRequest(Event event, HtmlElement target) {
    retardEvent(event);
    if (target == null) return;
    sort(target.dataset['field']);
  }
    
  /// Handles an invitation from the logged-in user to another user.
  void handleShareEntryRequest(Event event, Map details) {
    retardEvent(event);
    shareEntry(details['entry'], details['users']); 
  }
  
  /// Handles an unshare request.
  void handleUnshareEntryRequest(Event event, Map details) {
    retardEvent(event);
    unshareEntry(details['entry'], details['user']); 
  }
  
  /// Handles a new tag.
  void handleAddTagsRequest(Event event, Map detail) {
    retardEvent(event);
    addTags(detail['entry'], detail['tag']);
  }
  
  /// Handles an update of a tag.
  void handleUpdateTagRequest(Event event, Map detail) {
    retardEvent(event);
    updateTag(detail['entry'], detail['index'], detail['new']);
  }
  
  /// Handles a deletion of a tag.
  void handleDeleteTagRequest(Event event, Map detail) {
    retardEvent(event);
    deleteTag(detail['entry'], detail['index']);
  }
  
  /// Handles a add pdf url request.
  void handleAddPdfUrlRequest(Event event, Map detail) {
    retardEvent(event);
    addPdfUrl(detail['entry'], detail['url']);
  }
  
  /// Handles a add pdf url request.
  void handleRepeatStrippingRequest(LibraryEntry entry) {
    if (entry == null) return;
    entry.getPdf().then((pdf) => strip(entry: entry, pdf: pdf));
  }
  
  // ___________________________________________________________________________
  // Actions. 
  
  /// Selects the given library entry.
  void selectEntry(Entry entry) {
    if (entry == null) return;
    if (entry is LibraryEntry) {
      if (selectedEntry != null) selectedEntry.unselect();
      entry.select();
      this.selectedEntry = entry;
      scrollToEntry(entry);
    }
  }
  
  /// Delete the given entry.
  void deleteEntry(LibraryEntry entry) {
    // Distinguish if user is the owner.
    if (user.isOwner(entry)) {
      // The user is the owner. So delete the library entry.
      uncacheLibraryEntry(entry); 
    } else {
      // The user isn't the owner. So unsubscribe the user.
      unshareEntry(entry, user);
    }
  }
      
  /// Uploads the given files.
  void installFiles(List<File> files) {
    if (files == null) return;
    files.forEach((file) => installFile(file));
  }
  
  /// Uploads the given file.
  void installFile(File file) {
    if (file == null) return;
    LibraryEntry entry = new LibraryEntry.fromData({
      'title': file.name,
      'userId': user.id,
    });
    entry.peek();
    
    strip(entry: entry, pdf: file);
    cacheLibraryEntry(entry, pdf: file);
  }
  
  /// Imports the given reference entry.
  void import(Entry entry) {
    if (entry == null) return;
        
    LibraryEntry toInstall = null;
    if (entry.isLibraryEntry) {
      toInstall = entry;
    } else if (entry.isReferenceEntry) {
      toInstall = new LibraryEntry.fromReferenceEntry(entry);
    } else if (entry.isSearchEntry) {
      toInstall = new LibraryEntry.fromSearchEntry(entry);
    }
    
    if (toInstall != null) {
      toInstall.peek();
      
      strip(entry: toInstall);
      cacheLibraryEntry(toInstall);
    }
  }
    
  /// Uploads the file given by url.
  void installUrl(String url) {
    if (url == null) return;
    
    LibraryEntry entry = new LibraryEntry.fromData({
      'title': url,
      'userId': user.id,
      'ee': url
    });
    entry.peek();
    
    strip(entry: entry);
    cacheLibraryEntry(entry);
  }
  
  /// Handles a search query.
  void search(String query) {
    // Set searchQuery.
    this.searchQuery = query;   
    // Search externally.
    searchExternally().then((Map map) => this.cache.setSearchEntries(map));
  } 
  
  /// Handles a cancellation of search.
  void cancelSearch() {
    // Reset searchQuery.
    this.searchQuery = null;
    this.cache.clearSearchEntries();
  }
  
  /// Sorts.
  void sort(var sortField, {bool asc: false}) {
    String field = sortField is SortField ? sortField.display : sortField;
    sortAscending = (field != selectedSortField || asc) ? true: !sortAscending;
    selectedSortField = field; 
    setSortCssLabel(get(field), sortAscending ? "asc" : "desc");
  }
  
  /// Filters the library by tags.
  void setSelectedTags(List<String> tags) {
    this.selectedTags = new ObservableList.from(tags);
  }
  
  /// Searches externally.
  Future<Map> searchExternally() {
    return s.search(searchQuery);
  }
       
  /// Adds the given tag to the given entry.
  void addTags(LibraryEntry entry, String tag) {
    if (entry == null) return;
    if (tag == null) return;
    List tags = tag.split(new RegExp(r'[\,\;]'));
    for (var i = 0; i < tags.length; i++) {
      tags[i] = tags[i].trim().replaceAll(" ", "_");
    }
    entry.addTags(tags);
  }
  
  /// Updates the tag at given index.
  void updateTag(LibraryEntry entry, int index, String tag) {
    if (entry == null) return;
    if (index == null) return;
    if (tag == null) return;
    tag = tag.trim().replaceAll(" ", "_");
    entry.updateTag(index, tag);
  }
   
  /// Deletes the tag at given index from given entry.
  void deleteTag(LibraryEntry entry, int index) {
    if (entry == null) return;
    if (index == null) return;
    entry.deleteTag(index);
  }
        
  /// Invites the given user to given entry.
  void shareEntry(LibraryEntry entry, List<User> users) {
    if (entry == null) return;
    entry.share(users);
  }
  
  /// Unsubscribes the logged-in user from given library entry.
  void unshareEntry(LibraryEntry entry, User user) {
    if (entry == null) return;
    entry.unshare(user);
  }
    
  /// Add the given pdf url to library entry.
  void addPdfUrl(LibraryEntry entry, String url) {
    if (entry == null) return;
    if (url == null) return;   
    strip(entry: entry..['ee'] = url);
  }
  
  /// Scrolls to the given entry, if it isn't visible.
  Future scrollToEntry(Entry entry) {
    if (entry == null) return new Future.value();
    return scrollToElement(scrollArea.querySelector("#id-${entry.id}"));
  }
  
  /// Scrolls to the given library entry element, if it isn't visible.
  Future scrollToElement(Element element) {
    if (element == null) return new Future.value();
    
    Completer completer = new Completer();
    
    var scrollAreaTop = scrollArea.scrollTop;
    var scrollAreaBottom = scrollAreaTop + scrollArea.clientHeight;
        
    var elementTop = element.offsetTop;
    var elementBottom = elementTop + element.clientHeight;
        
    int offset = 0;
    if (elementTop < scrollAreaTop) {
      // The element is above the current viewport of scrollArea.
      offset = elementTop - scrollAreaTop; // offset is negative
    } else if (elementBottom > scrollAreaBottom) {
      // The element is below the current viewport of scrollArea.
      offset = elementBottom - scrollAreaBottom; // offset is positive
    }
        
    // Recalculate scrollTop for scrollArea.
    var scrollTop = scrollAreaTop + offset;
    
    // Scroll.
    animate(scrollArea, properties: {'scrollTop': scrollTop}, duration: 600)
            ..onComplete.listen((_) => completer.complete());
        
    return completer.future;
  }
  
  // __________________________________________________________________________
  
  /// Adds the given library entry to library.
  void cacheLibraryEntry(Entry entry, {Blob pdf: null}) {    
    cache.addLibraryEntry(entry, pdf: pdf);
  }
    
  /// Deletes the given library entry from library.
  void uncacheLibraryEntry(LibraryEntry entry) {
    cache.deleteLibraryEntry(entry);
  }
            
  // ___________________________________________________________________________
  // Display methods.
                      
  /// Sorts the entries according to given field. If this field is already the 
  /// current sorting field then reverse the sort
  Function sortBy(String sortField, bool ascending) {
    return (Iterable<Entry> entries) { 
      if (sortField == null) return entries;
      var list = entries.toList()..sort(SortField.comparators[sortField]);
      return ascending ? list : list.reversed;  
    };
  }
  
  /// Filters the entries by searchQuery.  
  Function filterByQuery(String query) {
    return (Iterable<Entry> entries) { 
      if (entries == null) return [];
      return entries.where((entry) => s.filterEntryByQuery(entry, query));
    };
  }
   
  /// Filters the entries by selected tags.  
  Function filterByTags(List tags) {
    return (Iterable<Entry> entries) { 
      if (entries == null) return [];
      return entries.where((entry) => s.filterEntryByTags(entry, tags));
    };    
  }
  
  // ___________________________________________________________________________
      
  /// Returns the previous entry of selectedEntry.
  LibraryEntry getPreviousLibraryEntry() {
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
  LibraryEntry getNextLibraryEntry() {
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
    return scrollArea.querySelectorAll("library-entry-element");
  }
    
  /// Returns the html element of the selected entry.
  Element _getSelectedLibraryEntryHtmlElement() {
    if (selectedEntry != null) {
      return scrollArea.querySelector("#id-${selectedEntry.id}");
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