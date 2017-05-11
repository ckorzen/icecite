library actions;

import 'dart:async';
import 'dart:html';
import '../auth/auth.dart';
import '../cache/library_entry_cache.dart';
import '../cache/user_cache.dart';
import '../cache/supplements_cache.dart';
import '../models/models.dart';
import '../utils/pdf/pdf_enricher.dart';
import '../utils/pdf/pdf_resolver.dart';

class Actions {
  /// The current instance.
  static Actions _instance; 

  /// The caches.
  UserCache userCache;
  LibraryEntryCache libEntryCache;
 
  /// The stream controllers.
  StreamController usersFilledStream;
  StreamController<User> userChangedStream;
  StreamController<User> userDeletedStream;
  StreamController libEntriesFilledStream;
  StreamController<LibraryEntry> libEntryChangedStream;
  StreamController<LibraryEntry> libEntryDeletedStream;
  StreamController<LibraryEntry> topicChangedStream;
  StreamController<LibraryEntry> topicDeletedStream;
  
  /// The auth manager.
  Auth auth;
  /// The pdf enricher.
  PdfEnricher pdfEnricher;
  /// The pdf resolver.
  PdfResolverInterface pdfResolver;  
  
  /// The factory constructor, returning the current instance.
  factory Actions() {
    if (_instance == null)
      _instance = new Actions._internal();
    return _instance;
  }

  /// The internal constructor.
  Actions._internal() {
    this.usersFilledStream = new StreamController.broadcast();
    this.userChangedStream = new StreamController<User>.broadcast();
    this.userDeletedStream = new StreamController<User>.broadcast();
    this.libEntriesFilledStream = new StreamController.broadcast();
    this.libEntryChangedStream = new StreamController<LibraryEntry>.broadcast();
    this.libEntryDeletedStream = new StreamController<LibraryEntry>.broadcast();
    this.topicChangedStream = new StreamController<LibraryEntry>.broadcast();
    this.topicDeletedStream = new StreamController<LibraryEntry>.broadcast();
    this.pdfEnricher = new PdfEnricher();
    this.pdfResolver = new PdfResolverImpl();
    this.auth = new Auth();
    
    _initializeUserCache();
    
    if (auth.isLoggedIn) _initializeLibraryEntryCache();
    this.auth.onLogin.listen((_) => _initializeLibraryEntryCache());
    this.auth.onLogout.listen((_) => libEntryCache.clear());
  }
  
  /// Initializes the user cache.
  void _initializeUserCache() {
    // Initialize the user cache.
    this.userCache = new UserCache()
     ..onFilled.listen((_) => usersFilledStream.add(null))
     ..onUserChanged.listen((user) => userChangedStream.add(user))
     ..onUserDeleted.listen((user) => userDeletedStream.add(user));
  }
  
  /// Initializes the library entry cache.
  void _initializeLibraryEntryCache() {
    // Initialize the library entry cache on login.
    this.libEntryCache = new LibraryEntryCache(auth.user)
     ..onFilled.listen((_) => libEntriesFilledStream.add(null))
     ..onLibraryEntryChanged.listen((e) => libEntryChangedStream.add(e))
     ..onLibraryEntryDeleted.listen((e) => libEntryDeletedStream.add(e))
     ..onTopicChanged.listen((e) => topicChangedStream.add(e))
     ..onTopicDeleted.listen((e) => topicDeletedStream.add(e));
  }
    
  void resetOnLogout() {
    if (this.auth != null) this.auth.resetOnLogout();
    if (this.userCache != null) this.userCache.resetOnLogout();
    if (this.libEntryCache != null) this.libEntryCache.resetOnLogout();
  }
  
  // ___________________________________________________________________________
  // Complex actions.
  
  /// Installs the given library entry with given blob and given references.
  Future installLibraryEntry(LibraryEntry entry, [Blob blob, List refs]) {
    if (entry == null) return new Future.value();
    Completer<LibraryEntry> completer = new Completer<LibraryEntry>();
    _installLibraryEntryAndBlob(entry, blob).then((entry) {
      if (refs != null) {
        // Set the citing entry id for each reference.
        refs.forEach((ref) => ref.citingEntryId = entry.id);
        setReferences(entry, refs).then((_) => completer.complete(entry)); 
      } else {
        completer.complete(entry);
      }
    });
    return completer.future;
  }
  
  /// Updates the given entry.
  Future reinstallLibraryEntry(LibraryEntry entry, [List refs, Blob blob]) {
    if (entry == null) return new Future.value();
    entry.modified = new DateTime.now();
    return installLibraryEntry(entry, blob, refs);
  }
  
  /// Deletes the given entry.
  void uninstallLibraryEntry(LibraryEntry entry) {
    deleteLibraryEntry(entry);
    deleteReferences(entry);
    deleteFeedEntries(entry);
    deletePdfAnnotations(entry);
  }
    
  /// Adds the given library entry to library.
  Future _installLibraryEntryAndBlob(LibraryEntry entry, [Blob blob]) {
    Completer<LibraryEntry> completer = new Completer<LibraryEntry>();
    
    Future.wait([setLibraryEntry(entry), pdfEnricher.enrich(blob)])
      .then((result) => setPdf(result[0], result[1])
      .then((_) => completer.complete(result[0])));
    
    return completer.future;
  }
  
  /// Matches the given entry.
  Future matchLibraryEntry(LibraryEntry entry) {
    if (entry.attachments != null) {
      return getPdf(entry)
        .then((blob) => pdfResolver.pdf2Meta(entry, blob)
        .then((r) => reinstallLibraryEntry(r['entry'], r['references'], r['blob'])));
    } else {
      return pdfResolver.meta2Pdf(entry).then((res) {
        reinstallLibraryEntry(res['entry'], res['references'], res['blob']);
      }); 
    }
  }
  
  /// Investigates the pdf and the references for given library entry.
  Future<LibraryEntry> searchPdfInWeb(LibraryEntry entry) {
    Completer<LibraryEntry> completer = new Completer<LibraryEntry>();
    pdfResolver.meta2Pdf(entry).then((res) {
      // Cache the downloaded stuff.
      LibraryEntry entry = new LibraryEntry.twin(res['entry'], "entry");
      installLibraryEntry(entry, res['blob'], res['references'])
        .then((entry) => completer.complete(entry))
        .catchError((e) => completer.completeError(e));
      }).catchError((e) => completer.completeError(e));
    return completer.future;
  }
  
  /// Assigns the given library entry to given topic.
  void assignLibraryEntryToTopic(var entry, var topic) {
    LibraryEntry _entry = entry is String ? getLibraryEntry(entry) : entry;
    LibraryEntry _topic = topic is String ? getTopic(topic) : topic;
    if (_entry != null && _topic != null) {
      List topicIds = _entry.topicIds != null ? _entry.topicIds : [];
      List userIdsOfEntry = _entry.userIds != null ? _entry.userIds : [];
      List userIdsOfTopic = _topic.userIds != null ? _topic.userIds : [];
      /// Add topic to topicIds if entry doesn't belong to topic already. 
      if (!topicIds.contains(_topic.id)) {
        _entry.topicIds = topicIds..add(_topic.id); 
        
        /// Add all userIds of topic to userIds of entry.
        userIdsOfTopic.forEach((String userId) {
          if (!userIdsOfEntry.contains(userId)) userIdsOfEntry.add(userId);
        });
        _entry.userIds = userIdsOfEntry;
        setLibraryEntry(_entry);
      }
    } 
  }
  
  /// Assigns the given library entry to given topic.
  void rejectLibraryEntryFromTopic(var entry, var topic) {
    LibraryEntry _entry = entry is String ? getLibraryEntry(entry) : entry;
    LibraryEntry _topic = topic is String ? getTopic(topic) : topic;
    if (_entry != null && _topic != null) {
      List<String> topicIds = _entry.topicIds;
      bool removed = false;
      if (topicIds != null) removed = topicIds.remove(_topic.id);
      if (removed) setLibraryEntry(_entry);
    }
  }
  
  /// Assigns the given entry to user.
  void assignEntryToUser(var entry, var user) {
    LibraryEntry _entry = entry is String ? getLibraryEntryOrTopic(entry) : entry;
    User _user = user is String ? getUser(user) : user;

    if (_entry != null && _user != null) {
      // Add userId to entry.
      List userIds = _entry.userIds != null ? _entry.userIds : [];
      if (!userIds.contains(_user.id)) {
        _entry.userIds = userIds..add(_user.id);
        setLibraryEntry(_entry);
      }
    }
    // Assign the user to all assigned entries.
    Iterable entries = getEntriesByTopic(entry);
    if (entries != null) {
      entries.forEach((entry) => assignEntryToUser(entry, _user));
    }
  }
  
  /// Assigns the given library entry to given topic.
  void rejectEntryFromUser(var entry, var user) {
    LibraryEntry _entry = entry is String ? getLibraryEntryOrTopic(entry) : entry;
    User _user = user is String ? getUser(user) : user;
    if (_user != null && _entry != null) {
      /// Delete user from userIds.
      List userIds = _entry.userIds != null ? _entry.userIds : [];
      userIds.remove(_user.id);
      if (userIds.isEmpty) { 
        /// Delete library entry, if there are no further users.
        uninstallLibraryEntry(_entry);
      } else {
        _entry.userIds = userIds;
        /// Add user to formerUserIds.
        List former = _entry.formerUserIds != null ? _entry.formerUserIds : [];
        _entry.formerUserIds = former..add(_user.id);
        setLibraryEntry(_entry);
      }
      // Reject the user from all assigned entries.
      Iterable entries = getEntriesByTopic(entry);
      if (entries != null) {
        entries.forEach((entry) => rejectEntryFromUser(entry, _user));
      }
    }
  }
  
  /// Reject the given user as former user from given entry.
  void rejectFormerUserFromEntry(var user, var entry) {
    User _user = user is String ? getLibraryEntry(user) : user;
    LibraryEntry _entry = entry is String ? getTopic(entry) : entry;
    if (_user != null && _entry != null) {
      _entry.formerUserIds.remove(_user.id);
      setLibraryEntry(_entry);
    }
  }
  
  /// Caches the given user if absent.
  void cacheUserIfAbsent(User user) {
    // Cache the user, if he isn't already cached yet.
    if (user != null && !containsUser(user)) setUser(user);
  }
  
  // ===========================================================================
  
  // ___________________________________________________________________________
  // User cache actions.
  
  /// Returns the users.
  Map<String, User> getUsers([userIds]) => userCache.getUsers(userIds);
  /// Returns the user with given id.
  User getUser(id) => userCache.getUser(id);
  /// Returns true, if the the given user is cached, fals otherwise.
  bool containsUser(User user) => userCache.contains(user);
  /// Caches the given user.
  Future setUser(User user) => userCache.setUser(user);
  
  // ___________________________________________________________________________
  // Library entry cache actions.
  
  /// Returns the library entries.
  Map getLibraryEntries() => libEntryCache.getLibraryEntries();
  /// Returns the library entry (or topic) with given id.
  LibraryEntry getLibraryEntryOrTopic(id) => libEntryCache.getLibraryEntryOrTopic(id);
  /// Returns the library entry with given id.
  LibraryEntry getLibraryEntry(id) => libEntryCache.getLibraryEntry(id);
  /// Caches the given library entry.
  Future setLibraryEntry(entry) => libEntryCache.setLibraryEntry(entry);
  /// Deletes the given library entry.
  Future deleteLibraryEntry(entry) => libEntryCache.deleteLibraryEntry(entry);
  
  /// Returns the topics.
  Iterable<LibraryEntry> getTopics([topicIds]) => libEntryCache.getTopics(topicIds);
  /// Returns the topic with given id.
  LibraryEntry getTopic(id) => libEntryCache.getTopic(id);
  /// Caches the given topic.
  Future setTopic(topic) => libEntryCache.setTopic(topic);
  /// Deletes the given topic and rejects all assigned entries from topic.
  void deleteTopicAndRejectEntries(topic) { 
    /// Reject all assigned entries from deleted topic.
    Iterable entries = getEntriesByTopic(topic);
    if (entries != null) {
      entries.forEach((entry) {
        rejectLibraryEntryFromTopic(entry, topic); 
      });
    }
    deleteTopic(topic);
  }
  /// Deletes the given topic.
  Future deleteTopic(topic) => libEntryCache.deleteTopic(topic);
  /// Returns the pdf of given entry.
  Future<Blob> getPdf(entry) => libEntryCache.getPdf(entry);
  /// Caches the given pdf.
  Future setPdf(entry, blob) => libEntryCache.setPdf(entry, blob);
  /// Returns the entries which are assigned to given topic
  Iterable getEntriesByTopic(top) => libEntryCache.getEntriesByTopic(top);
  
  // ___________________________________________________________________________
  // Supplements cache actions.
  
  /// Returns the supplements cache of given entry.
  SupplementsCache getCache(entry) => SupplementsCache.getCache(entry);
  
  /// Returns the references of given entry.
  Map getReferences(entry) => getCache(entry).getReferences(); 
  /// Sets the given references of given entry.
  Future setReferences(entry, refs) => getCache(entry).setReferences(refs);
  /// Sets the given references of given entry.
  Future setReference(entry, ref) => getCache(entry).setReference(ref);
  /// Deletes the references of given entry.
  Future deleteReferences(entry) => getCache(entry).deleteReferences();
  /// Deletes the given reference.
  Future deleteReference(entry, ref) => getCache(entry).deleteReference(ref);
  
  /// Returns the feed entries of given entry.
  Map getFeedEntries(entry) => getCache(entry).getFeedEntries(); 
  /// Sets the given feed entries of given entry.
  Future setFeedEntries(entry, feeds) => getCache(entry).setFeedEntries(feeds);
  /// Sets the given feed entry of given library entry.
  Future setFeedEntry(entry, feed) => getCache(entry).setFeedEntry(feed);
  /// Deletes the feed entries of given library entry.
  Future deleteFeedEntries(entry) => getCache(entry).deleteFeedEntries();
  /// Deletes the given feed entry.
  Future deleteFeedEntry(entry, feed) => getCache(entry).deleteFeedEntry(feed);
  
  /// Returns the pdf annotations of given entry.
  Map getPdfAnnotations(entry) => getCache(entry).getPdfAnnotations(); 
  /// Sets the given pdf annotations of given entry.
  Future setPdfAnnotations(entry, annots) => getCache(entry).setPdfAnnotations(annots);
  /// Sets the given pdf annotation of given library entry.
  Future setPdfAnnotation(entry, annot) => getCache(entry).setPdfAnnotation(annot);
  /// Deletes the pdf annotations of given entry.
  Future deletePdfAnnotations(entry) => getCache(entry).deletePdfAnnotations();
  /// Deletes the given feed entry.
  Future deletePdfAnnotation(entry, annot) => getCache(entry).deletePdfAnnotation(annot);
      
  // ___________________________________________________________________________
  // The streams.
  
  /// Returns stream for userCacheFilled event.
  Stream get onUsersFilled => usersFilledStream.stream;
  /// Returns stream for userChanged event.
  Stream get onUserChanged => userChangedStream.stream;
  /// Returns stream for userDeleted event.
  Stream get onUserDeleted => userDeletedStream.stream;
  /// Returns true when the user cache is filled.
  bool areUsersFilled() => (userCache != null) ? userCache.isFilled : false;
  
  /// Returns a stream for libEntryCacheFilled events.  
  Stream get onLibraryEntriesFilled => libEntriesFilledStream.stream;
  /// Returns a stream for libraryEntryChanged events.  
  Stream get onLibraryEntryChanged => libEntryChangedStream.stream;
  /// Returns a stream for libraryEntryDeleted events.  
  Stream get onLibraryEntryDeleted => libEntryDeletedStream.stream;
  /// Returns a stream for topicChanged events.  
  Stream get onTopicChanged => topicChangedStream.stream;
  /// Returns a stream for libraryEntryDeleted events.  
  Stream get onTopicDeleted => topicDeletedStream.stream;
  /// Returns true when the library entry cache is filled.
  bool areLibraryEntriesFilled() => libEntryCache != null ? 
      libEntryCache.isFilled : false;
  
  /// Returns a stream for supplementsCacheFilled events.  
  Stream onSupplementsFilled(entry) => getCache(entry).onFilled;
  /// Returns a stream for feedEntryChanged events.  
  Stream onFeedEntryChanged(entry) => getCache(entry).onFeedEntryChanged;
  /// Returns a stream for feedEntryDeleted events.  
  Stream onFeedEntryDeleted(entry) => getCache(entry).onFeedEntryDeleted;
  /// Returns a stream for referenceChanged events.  
  Stream onReferenceChanged(entry) => getCache(entry).onReferenceChanged;
  /// Returns a stream for referenceDeleted events.  
  Stream onReferenceDeleted(entry) => getCache(entry).onReferenceDeleted;
  /// Returns a stream for pdfAnnotChanged events.  
  Stream onPdfAnnotChanged(entry) => getCache(entry).onPdfAnnotChanged;
  /// Returns a stream for pdfAnnotDeleted events.  
  Stream onPdfAnnotDeleted(entry) => getCache(entry).onPdfAnnotDeleted;
  /// Returns true when the library entry cache is filled.
  bool areSupplementsFilled(entry) => getCache(entry).isFilled;
  
  // TODO: Implement close().
}