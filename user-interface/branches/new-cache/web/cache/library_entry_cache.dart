
library library_entry_cache;

import 'dart:js';
import 'dart:async';
import 'dart:collection';
import 'dart:html' hide Entry;
import '../properties.dart';
import '../models/models.dart';
import '../database/pouch_db.dart'; // TODO: Don't import this here. Is currently needed for DbChangeAction.
import '../database/library_entry_pouch_db.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

/// The library entry cache.
class LibraryEntryCache extends ObservableMap<String, Entry> {
  /// The logger.
  Logger LOG = new Logger("library-entry-cache");

  /// The instance of library entry database.
  LibraryEntryPouchDb libraryEntryDb;
  /// The ids of search entries.
  HashSet<String> searchEntryIds;
  /// The user.
  User user;
    
  /// The object, representing the replication to server.
  JsObject replicationTo;
  /// The object, representing the replication from server.
  JsObject replicationFrom;
  
  /// The streams.
  StreamController filledStream;
  bool isFilled = false;
  
  /// The internal constructor.
  LibraryEntryCache._internal(User user) {
    LOG.fine("Create library entry cache for user $user.");
    this.libraryEntryDb = new LibraryEntryPouchDb(user);
    this.libraryEntryDb.onDbChange.listen(handleLibraryEntryDbChange);
    this.filledStream = new StreamController.broadcast();
    
    // _________________________________________________________________________
    // TODO: Move this into LibraryEntryPouchDb.
    var fromOpts = {
      'continuous': 'true',
      'conflicts': 'true',
      'include_docs': 'true',
      'filter': context['replicateFromFilter'],
      'query_params': {'userId': user.id}
    };
    var rep = this.libraryEntryDb.sync(DB_ENTRIES_URL(), fromOpts: fromOpts);
    this.replicationFrom = rep['from'];
    this.replicationTo = rep['to'];
    
    this.searchEntryIds = new HashSet();
    this.user = user;
  }
    
  /// Initializes this library entry cache.
  Future initialize() {
    LOG.fine("Inititalize library entry cache for user $user.");
    return fill();
  }
  
  /// Resets this library entry cache.
  void reset() {
    LOG.fine("Reset the library entry cache for user $user.");
    clear();
    searchEntryIds.clear();
    this.user = null;
    // Stop syncing.
    if (this.replicationFrom != null) {
      this.replicationFrom.callMethod("cancel");
      this.replicationFrom = null;
    }
    if (this.replicationTo != null) {
      this.replicationTo.callMethod("cancel");
      this.replicationTo = null;
    }
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// Define the behavior when a library entry in storage was added or updated.
  void handleLibraryEntryDbChange(Map change) {
    LOG.finer("Handle library entry db-change: $change");
    if (change == null) return;
       
    DbChangeAction action = change['action'];    
    
    switch (action) {
      case DbChangeAction.UPDATED:
        applyLibraryEntryDbUpdateAction(change);
        break;
      case DbChangeAction.DELETED:
        applyLibraryEntryDbDeleteAction(change);
        break;
      default:
        break;
    }  
  }
  
  /// Applies the given db update action.
  void applyLibraryEntryDbUpdateAction(Map change) {
    LOG.finer("Apply library entry db update action.");
    if (change == null) return;
    
    String entryId = change['id'];    
    Map data = change['data'];    

    String rootId = entryId.split("_")[0];
        
    Entry entry = this[rootId];
    if (entry == null) {
      _cacheLibraryEntry(new LibraryEntry.fromData(data));
      return;
    } else {        
      _recacheLibraryEntry(rootId, data);
    }
  }
    
  /// Applies the given db delete action.
  void applyLibraryEntryDbDeleteAction(Map change) {
    LOG.finer("Apply library entry db delete action.");
    if (change == null) return;
    _uncacheEntry(change['id'].split("_")[0]);
  }

  // ___________________________________________________________________________
  // Internal methods.
  
  /// Caches the given library entry after db change.
  void _cacheLibraryEntry(LibraryEntry entry) {
    LOG.finest("Cache library entry $entry.");
    if (entry == null) return;
    
    if (searchEntryIds.contains(entry.rootId)) {
      entry.hasReplacedSearchEntry = true;
    }
    
    UserRole role = entry.getUserRole(user);
        
    switch(role) {
      case UserRole.OWNER:
      case UserRole.PARTICIPANT:
        this[entry.rootId] = entry;
        notifyPropertyChange(#entries, 0, 1);
        break;
      case UserRole.INVITEE:
        entry.acknowledgeInviteRequest(user);
        return;
      case UserRole.DISINVITEE:
        entry.acknowledgeDisinviteRequest(user);
        return;
      case UserRole.ALIEN:
        return;
      default:
        return;
    }  
  }
  
  /// Updates an already cached entry with given data.
  void _recacheLibraryEntry(String entryId, Map data) { 
    LOG.finest("Recache library entry with id $entryId. Data: $data.");
    LibraryEntry entry = this[entryId];
    if (entry != null) { 
      bool applied = entry.applyData(data);
            
      UserRole role = entry.getUserRole(user);
      switch(role) {
        case UserRole.OWNER:
        case UserRole.PARTICIPANT:
        case UserRole.INVITEE:     
          notifyPropertyChange(#entries, 0, 1);
          break;
        case UserRole.DISINVITEE:
          entry.acknowledgeDisinviteRequest(user);
          break;
        case UserRole.ALIEN:
          _uncacheEntry(entryId);
          break;
        default:
          break;
      }
    }
  }
  
  /// Uncaches the given library entry after db change.
  void _uncacheEntry(String entryId) {
    LOG.finest("Uncache entry with id $entryId.");
    Entry entry = remove(entryId);
    if (entry != null) {
      if (entry is LibraryEntry) {
        entry.deleteSupplements();
      }
      notifyPropertyChange(#entries, 0, 1);
    }
  }
    
  // ___________________________________________________________________________
  // Database actions.
    
  /// Fills the caches.
  Future fill() {
    LOG.finest("Filling the cache.");
    return libraryEntryDb.getLibraryEntries().then((entries) {
      if (entries == null) return;
      entries.forEach((entry) {
        _cacheLibraryEntry(entry);
      });
      
      isFilled = true;
      filledStream.add(null);
      
      LOG.finest("Filling the cache finished.");
    });
  }
  
  /// Sets the given entry.
  Future addLibraryEntries(Iterable<LibraryEntry> entries) {
    LOG.finest("Add ${entries.length} library entries.");
    entries.forEach((entry) => _cacheLibraryEntry(entry));
    return libraryEntryDb.setLibraryEntries(entries); 
  }
  
  /// Sets the given entry.
  void addLibraryEntry(LibraryEntry entry, {Blob pdf: null}) {
    LOG.finest("Add library entry $entry.");
    _cacheLibraryEntry(entry);
    
    libraryEntryDb.setLibraryEntry(entry).then((entry) {
      if (pdf != null) libraryEntryDb.setPdf(entry, pdf);
    });
  }
    
  /// Deletes the given user.
  Future deleteLibraryEntries(Iterable<LibraryEntry> entries) {
    LOG.finest("Delete ${entries.length} library entries.");
    return libraryEntryDb.deleteLibraryEntries(entries);
  }
  
  /// Deletes the given user.
  Future deleteLibraryEntry(LibraryEntry entry) {
    LOG.finest("Delete library entry $entry.");
    return libraryEntryDb.deleteLibraryEntry(entry);
  }
        
  // ___________________________________________________________________________
  
  /// Includes the given list of search entries.
  void setSearchEntries(Map<String, SearchEntry> searchEntries) {
    if (searchEntries == null) return;
    _removeSearchEntries();
    
    LOG.finest("Setting search entries.");
    searchEntries.keys.forEach((key) {
      searchEntryIds.add(key);
      this[key] = searchEntries[key];
    });
    notifyPropertyChange(#entries, 0, 1);
  }
  
  /// Clears the search entries.
  void clearSearchEntries() {
    LOG.finest("Clearing search entries.");
    if (_removeSearchEntries()) {
      notifyPropertyChange(#entries, 0, 1);  
    }
  }
  
  /// Removes each map entry, which is not a library entry. 
  bool _removeSearchEntries() {
    bool removed = false;
    searchEntryIds.forEach((key) {
      Entry entry = this[key];
      if (entry is SearchEntry) {
        remove(key);
        removed = true;
      } else if (entry is LibraryEntry) {
        entry.hasReplacedSearchEntry = false;
      }
    });
    searchEntryIds.clear();
    return removed;
  }
  
  // ___________________________________________________________________________
  // Getters.
       
  /// Returns an iterable with all library entries inside. 
  Iterable<Entry> get entries => this.values;
   
  /// Returns the library entry / topic / reference with given id.
  LibraryEntry getLibraryEntry(String entryId) {
    LibraryEntry entry = this[entryId];
    return entry;
  }
             
  // ___________________________________________________________________________
  // Helpers.
      
  /// Checks, if cache contains the given user.
  bool contains(Entry entry) {
    return entry != null && this.containsKey(entry.id);
  }
    
  Stream get onFilled => filledStream.stream;
  
  // ___________________________________________________________________________
    
  /// The factory constructor, returning the current instance.
  factory LibraryEntryCache(User user) {
    if (_instance == null || _instance.user != user) {
      _instance = new LibraryEntryCache._internal(user);
    }
    return _instance;
  }
  
  /// The internal instance.
  static LibraryEntryCache _instance;
}