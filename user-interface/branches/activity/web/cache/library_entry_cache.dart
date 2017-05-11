library library_entry_cache;

import 'dart:js';
import 'dart:html';
import 'dart:async';
import 'dart:mirrors';
import 'cache_impl.dart';
import '../models/models.dart';
import '../properties.dart';
import 'database/pouch_db.dart';

part 'library_entry_conflict_resolver.dart';
part 'library_entry_pouch_db.dart';

/// The library entry cache.
class LibraryEntryCache extends Cache<String, LibraryEntry> {
  /// The internal instance.
  static LibraryEntryCache _instance;
  /// The instance of FeedEntryPouchDb.
  LibraryEntryPouchDb db;
  /// The user.
  User user;
  bool isFilled = false; 
  
  /// The topics cache.
  Map<String, LibraryEntry> topicsCache; 
  /// The references cache.
  Map<String, Blob> pdfCache; 
  /// Map entryId -> citingEntryId to be able to identify the parent entry.
  Map<String, String> citingEntryIdCache;
  /// Map topicId -> entry to be able to identify the entries of a topic.
  Map<String, Map<String, LibraryEntry>> entriesByTopics;
  
  /// The various stream controllers.
  StreamController fillStream;
  StreamController<LibraryEntry> libraryEntryChangedStream;
  StreamController<LibraryEntry> libraryEntryDeletedStream;
  StreamController<LibraryEntry> topicChangedStream;
  StreamController<LibraryEntry> topicDeletedStream;
    
  /// The factory constructor, returning the current instance.
  factory LibraryEntryCache(User user) {
    if (_instance == null || _instance.user != user) {
      _instance = new LibraryEntryCache._internal(user);
    } else {
      // Fill the instance, if it isn't filled yet (cache is cleared on logout).
      if (!_instance.isFilled) _instance.fill();
    }
    return _instance;
  }

  /// The internal constructor.
  LibraryEntryCache._internal(User user) {
    this.user = user;
    this.topicsCache = {};
    this.pdfCache = {};
    this.citingEntryIdCache = {};
    this.entriesByTopics = {};
    
    // Declare the stream controllers.
    fillStream = new StreamController.broadcast();
    libraryEntryChangedStream = new StreamController<LibraryEntry>.broadcast();
    libraryEntryDeletedStream = new StreamController<LibraryEntry>.broadcast();
    topicChangedStream = new StreamController<LibraryEntry>.broadcast();
    topicDeletedStream = new StreamController<LibraryEntry>.broadcast();
   
    // Declare the database.
    db = new LibraryEntryPouchDb(DB_ENTRIES_NAME(user));
    db.onLibraryEntryChanged.listen((entr) => libraryEntryChangedHandler(entr));
    db.onLibraryEntryDeleted.listen((entr) => libraryEntryDeletedHandler(entr));
      
    var fromOpts = {
      'continuous': 'true',
      'conflicts': 'true',
      'include_docs': 'true',
      'filter': context['replicateFromFilter'],
      'query_params': {'userId': user.id}
    };
    db.sync(DB_ENTRIES_URL(user), fromOpts: fromOpts);
    
    fill();
  }
  
  /// Resets the cache.
  void resetOnLogout() {
    if (this.db != null) this.db.resetOnLogout();
    this.user = null;
    this.isFilled = false; 
    if (this.topicsCache != null) this.topicsCache.clear();
    if (this.pdfCache != null) this.pdfCache.clear();
    if (this.citingEntryIdCache != null) this.citingEntryIdCache.clear();
    if (this.entriesByTopics != null) this.entriesByTopics.clear();
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// Define the behavior when a library entry in storage was added or updated.
  void libraryEntryChangedHandler(LibraryEntry entry) {
    if (entry != null) _cacheLibraryEntry(entry);
  }
  
  /// Define the behavior when a library entry in storage was deleted.
  void libraryEntryDeletedHandler(String entryId) {
    if (entryId != null) _uncacheLibraryEntry(get(entryId));
  }
    
  // ___________________________________________________________________________
  // Database actions.
    
  /// Fills the caches.
  void fill() {
    db.getLibraryEntries().then((list) {
      if (list != null) list.forEach((entry) {
         _cacheLibraryEntry(entry, avoidFire: true);
      });
      fillStream.add(null);
      isFilled = true;
    });
  }
  
  /// Sets the given entry.
  Future setLibraryEntries(Iterable<LibraryEntry> entries) {
    return db.setLibraryEntries(entries); 
  }
  
  /// Sets the given entry.
  Future setLibraryEntry(LibraryEntry entry) {
    return db.setLibraryEntry(entry); 
  }
   
  /// Deletes the given user.
  Future deleteLibraryEntries(Iterable<LibraryEntry> entries) {
    return db.deleteLibraryEntries(entries);
  }
  
  /// Deletes the given user.
  Future deleteLibraryEntry(LibraryEntry entry) {
    return db.deleteLibraryEntry(entry);
  }
  
  /// Sets the given topic.
  Future setTopics(Iterable<LibraryEntry> topics) {
    return db.setLibraryEntries(topics); 
  }
  
  /// Sets the given entry.
  Future setTopic(LibraryEntry topic) {
    return db.setLibraryEntry(topic); 
  }
   
  /// Deletes the given user.
  Future deleteTopics(Iterable<LibraryEntry> topics) {
    return db.deleteLibraryEntries(topics);
  }
  
  /// Deletes the given user.
  Future deleteTopic(LibraryEntry topic) {
    return db.deleteLibraryEntry(topic);
  }
  
  /// Sets the pdf.
  Future setPdf(LibraryEntry entry, Blob pdf) {
    return db.setPdf(entry, pdf); // TODO: Cache the pdfs?
  }
  
  /// Deletes the blob.
  Future deletePdf(var entry) {
    return db.deletePdf(entry); // TODO: Cache the pdfs?
  }
  
  // ___________________________________________________________________________
  // Getters.
  
  /// Returns the library entry / topic with given id.
  LibraryEntry get(String entryId) {
    // Check, if entry is library entry.
    if (this[entryId] != null) return this[entryId];
    // Check, if entry is topic.
    if (topicsCache[entryId] != null) return topicsCache[entryId];
    return null;
  }
 
  /// Returns an iterable with all entries inside. 
  Map<String, LibraryEntry> getLibraryEntries() => this;
  
  /// Returns the library entry / topic / reference with given id.
  LibraryEntry getLibraryEntry(String entryId) {
    return this[entryId];
  }
     
  /// Returns the topics.
  Map getTopics([topicIds]) {
    if (topicIds == null) return topicsCache;
    Map<String, LibraryEntry> topics = {};
    topicIds.forEach((topicId) {
      LibraryEntry topic = topicsCache[topicId];
      if (topic != null) topics[topic.id] = topic;
    });
    return topics; 
  }
  
  /// Returns the topic with given id.
  LibraryEntry getTopic(String topicId) {
    return topicsCache[topicId];
  }
  
  Iterable<LibraryEntry> getEntriesByTopic(var topic) {
    String topicId = (topic is LibraryEntry) ? topic.id : topic;
    Map<String, LibraryEntry> entries = entriesByTopics[topicId];
    if (entries != null) return entries.values;
    return null;
  }
  
  /// Returns the blob
  Future<Blob> getPdf(var entry) {
    return db.getPdf(entry); // TODO: Cache the pdfs?
  }
    
  // ___________________________________________________________________________
  // Helpers.
  
  /// Caches the given entry.
  void _cacheLibraryEntry(LibraryEntry entry, {bool avoidFire: false}) {
    if (entry != null) {
      // TODO: Use attachments as indicator for entry?
      if (entry.brand == 'entry') {
        // Handle the topicIds.
        List<String> topicIds = entry.topicIds;
        if (topicIds != null) {
          topicIds.forEach((topicId) {
            Map entriesByTopic = entriesByTopics[topicId];
            if (entriesByTopic != null) entriesByTopic[entry.id] = entry;
            else entriesByTopics[topicId] = {entry.id: entry};
          });
        }
        this[entry.id] = entry;
        if (!avoidFire) libraryEntryChangedStream.add(entry);
      }
                 
      if (entry.brand == 'topic') {
        topicsCache[entry.id] = entry;
        if (!avoidFire) topicChangedStream.add(entry);   
      }
    }
  }
  
  /// Uncaches the given entry.
  void _uncacheLibraryEntry(LibraryEntry entry, {bool avoidFire: false}) {
    if (entry != null) {
      // TODO: Use attachments as indicator for entry?
      if (entry.brand == 'entry') {
        // Handle the topicIds.
        List<String> topicIds = entry.topicIds;
        if (topicIds != null) {
          topicIds.forEach((topicId) {
            Map entriesByTopic = entriesByTopics[topicId];
            if (entriesByTopic != null) entriesByTopic.remove(entry.id);
          });
        }
                
        LibraryEntry removedEntry = this.remove(entry.id);
        if (removedEntry != null && !avoidFire) 
          libraryEntryDeletedStream.add(removedEntry);
      } 
      
      // Remove entry from topicsCache. 
      // TODO: reject topic from all associated entries and fire changedevent.
      if (entry.brand == 'topic') {
        // Handle the topicIds.
//        topicAssignments.remove(entry.id);
        
        LibraryEntry removedTopic = topicsCache.remove(entry.id);
        if (removedTopic != null && !avoidFire)
          topicDeletedStream.add(removedTopic);
      }
    }
  }
  
  // Override the clear method.
  void clear() {
    super.clear();
    topicsCache.clear();
    citingEntryIdCache.clear();
    isFilled = false;
  }
  
  // Override the clear method.
  void close() {
    clear();
    db.close();
    fillStream.close();
    libraryEntryChangedStream.close();
    libraryEntryDeletedStream.close();
    topicChangedStream.close();
    topicDeletedStream.close();
  }
  
  // ___________________________________________________________________________
  // The streams.
  
  /// Returns a stream for filled events.
  Stream get onFilled => fillStream.stream;
  
  /// Returns a stream for library entry changed events.  
  Stream get onLibraryEntryChanged => libraryEntryChangedStream.stream; 
  
  /// Returns a stream for library entry deleted events.  
  Stream get onLibraryEntryDeleted => libraryEntryDeletedStream.stream;
  
  /// Returns a stream for topic changed events.  
  Stream get onTopicChanged => topicChangedStream.stream;
  
  /// Returns a stream for topic deleted events.  
  Stream get onTopicDeleted => topicDeletedStream.stream;
}