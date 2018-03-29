library actions;

import 'dart:js';
import 'dart:async';
import 'dart:convert';
import 'dart:html' hide Notification;
import '../auth/auth.dart';
import '../cache/library_entry_cache.dart';
import '../cache/user_cache.dart';
import '../cache/supplements_cache.dart';
import '../models/models.dart';
import '../utils/pdf/pdf_enricher.dart';
import '../utils/pdf/pdf_resolver.dart';
import '../utils/html/notification_util.dart';

class Actions {
  /// The current instance.
  static Actions _instance; 
  /// The notification util.
  NotificationUtil notificationUtil;
  
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
  StreamController<Activity> activityStream;
  
  /// The auth manager.
  Auth auth;
  /// The pdf enricher.
//  PdfEnricher pdfEnricher;
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
    this.activityStream = new StreamController<Activity>.broadcast();
//    this.pdfEnricher = new PdfEnricher();
    this.pdfResolver = new PdfResolverImpl();
    this.auth = new Auth();
    this.notificationUtil = new NotificationUtil();
    
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
    bool fireActivity = (entry.rev == null); 
    
    if (entry.rev == null && blob != null) {
      // TODO
      extractNativeAnnotations(blob).then((annots) {
        setPdfAnnots(entry, annots);
      });
    }
    
    /// Will be excecuted on completion.
    void complete(LibraryEntry e) {
      if (fireActivity) 
        activityStream.add(new Activity(ActivityType.CREATED, e, auth.user));
      completer.complete(e);
    }
    
    _installLibraryEntryAndBlob(entry, blob).then((entry) {
      if (refs == null) complete(entry);
      else {
        // Set the citing entry id for each reference.
        refs.forEach((ref) => ref.citingEntryId = entry.id);
        setReferences(entry, refs).then((_) => complete(entry));
      }
    });
    return completer.future;
  }
      
  /// Deletes the given entry.
  void uninstallLibraryEntry(LibraryEntry entry) {
    if (!userIsOwner(entry)) return;
    deleteLibraryEntry(entry);
    deleteReferences(entry);
    deleteFeedEntries(entry);
    deletePdfAnnots(entry);
  }
    
  /// Adds the given library entry to library.
  Future _installLibraryEntryAndBlob(LibraryEntry entry, [Blob blob]) {
    Completer<LibraryEntry> completer = new Completer<LibraryEntry>();
        
    setLibraryEntry(entry).then((entry) {
      setPdf(entry, blob).then((rev) {
        completer.complete(entry != null ? (entry..rev = rev) : null);
      });
    });
    
//    Future.wait([
//      setLibraryEntry(entry),
//      setPdf(entry, blob)
//    ]).then((result) {
//      LibraryEntry entry = result[0];
//      String rev = result[1];
//      completer.complete(entry != null ? (entry..rev = rev) : null);
//    });
    
//    Future.wait([
//      setLibraryEntry(entry),
//      pdfEnricher.enrich(blob) // TODO
//    ]).then((result) {
//      LibraryEntry entry = result[0];
//      Blob blob = result[1];
//      setPdf(entry, blob).then((String rev) {
//        // Grab the rev from setPdf.
//        completer.complete(entry != null ? (entry..rev = rev) : null);
//      });
//    });
    return completer.future;
  }
  
  // ___________________________________________________________________________
  
  // TODO: Move into any extern method.
  Future<List<PdfAnnotation>> extractNativeAnnotations(Blob blob) {
    Completer<PdfAnnotation> completer = new Completer();
    /// Read the pdf from database.
    FileReader reader = new FileReader();
    reader.readAsDataUrl(blob);    
    reader.onLoadEnd.listen((_) {
      String dataUrl = reader.result;
      if (dataUrl != null) {
        int index = dataUrl.indexOf("base64,") + 7;
        if (index > 6) {
          String base64 = dataUrl.substring(index);
          
          // Define the callback.
          callback(JsObject error, [JsObject result]) {
            if (error != null) {
              completer.completeError(_dartify(error)); 
            } else {
              List annots = [];
              List annotsData = _dartify(result);
              for (Map annotData in annotsData) {
                annots.add(new PdfAnnotation.fromMap(annotData));
              }              
              completer.complete(annots);
            }
          }
          context.callMethod("extractNativeAnnotations", [base64, callback]);
        }
      }
    });
    return completer.future;
  }
  
  /// Transforms the given js object into a dart object.
  static _dartify(JsObject object) {
    // Workaround to put the jsObject into map: Encode the jsObject into JSON 
    // (within JS) and decode it again (within dart).
    return JSON.decode(context['JSON'].callMethod('stringify', [object]));
  }
  
  // ___________________________________________________________________________
  
  /// Matches the given entry.
  Future matchLibraryEntry(LibraryEntry entry) {
    if (!userIsOwner(entry)) return new Future.value();
    if (entry.attachments == null) {
      return pdfResolver.meta2Pdf(entry).then((res) {
        installLibraryEntry(res['entry'], res['blob'], res['refs']);
      }); 
    }
        
    return getPdf(entry)
      .then((blob) => pdfResolver.pdf2Meta(entry, blob)
      .then((r) => installLibraryEntry(r['entry'], r['blob'], r['refs'])));
  }
  
  /// Investigates the pdf and the references for given library entry.
  Future<LibraryEntry> installFromWeb(LibraryEntry entry, {bool globalNotifications: false}) {
    Completer<LibraryEntry> completer = new Completer<LibraryEntry>();
    
    LibraryEntry notificationsEntry = globalNotifications ? null : entry;
//    loading("Creating server request.", pouchable: notificationsEntry);  
    pdfResolver.meta2Pdf(entry, globalNotifications: globalNotifications).then((res) {
      // Cache the downloaded stuff.
      LibraryEntry newEntry = new LibraryEntry.twin(res['entry'], "entry", auth.user);
//      loading("Installing library entry.", pouchable: notificationsEntry);
      installLibraryEntry(newEntry, res['blob'], res['refs'])
        .then((entry) => completer.complete(entry))
        .catchError((e) => completer.completeError(e));
      }).catchError((e) => completer.completeError(e));
    return completer.future;
  }
  
  // ===========================================================================
  
  /// Assigns the given library entry to given topic.
  void assignLibraryEntryToTopic(var entry, var topic) {    
    if (entry is String) entry = getLibraryEntry(entry);
    if (topic is String) topic = getTopic(topic);
    if (entry == null || topic == null) return;
    if (!userIsOwner(entry)) return;
            
    // Assign the entry to topic (if it isn't already yet). 
    if (entry.topicIds == null) entry.topicIds = [];
    if (!entry.topicIds.contains(topic.id)) {
      entry.topicIds.add(topic.id);
    
      // Assign the entry to all user, which are assigned to the topic.
      List topicParticips = topic.participants != null ? topic.participants : [];
      List entryParticips = entry.participants != null ? entry.participants : [];
      topicParticips.forEach((String userId) {
        if (!entryParticips.contains(userId)) entryParticips.add(userId);
        // User is now a participant. Therefore it is not allowed, that the user 
        // is prenst in invitees and disinvitees.
        if (entry.invitees != null) entry.invitees.remove(userId);
        if (entry.disinvitees != null) entry.disinvitees.remove(userId);
      });
      entry.participants = entryParticips;
    
      // Persist the entry.
      setLibraryEntry(entry).then((_) {
        var acty = new Activity(ActivityType.TOPIC_ASSIGNED, entry, auth.user);
        activityStream.add(acty);
      });
    }
  }
  
  /// Assigns the given library entry to given topic.
  void rejectLibraryEntryFromTopic(var entry, var topic) {
    if (entry is String) entry = getLibraryEntry(entry);
    if (topic is String) topic = getTopic(topic);
    if (entry == null || topic == null) return;
    if (!userIsOwner(entry)) return;
    if (entry.topicIds == null || !entry.topicIds.remove(topic.id)) return;
     
    // Disinvite all participants of the topic.
    List topicParticips = topic.participants != null ? topic.participants : [];
    List entryDisinvitees = entry.disinvitees != null ? entry.disinvitees : [];
    topicParticips.forEach((String userId) {
      if (entry.participants != null) entry.participants.remove(userId);
      if (entry.invitees != null) entry.invitees.remove(userId);
      if (!entryDisinvitees.contains(userId)) entryDisinvitees.add(userId);
    });
    entry.disinvitees = entryDisinvitees;
        
    setLibraryEntry(entry).then((_) {
      var activty = new Activity(ActivityType.TOPIC_REJECTED, entry, auth.user);
      activityStream.add(activty);
    });
  }
  
  /// Assigns the given entry to user.
  void inviteUserToEntry(var entry, var user) {    
    if (entry is String) entry = getLibraryEntryOrTopic(entry);
    if (user is String) user = getUser(user);
    if (entry == null || user == null) return;
    if (!userIsOwner(entry)) return;
    
    // Add userId to entry.
    List invitees = entry.invitees != null ? entry.invitees : [];
    // The user must not be the owner or a participant and must not be invited
    // already.
    if (!user.isOwnerOrParticipant(entry) && !user.isInvited(entry)) {
      entry.invitees = invitees..add(user.id);
      // Because the user was invited, make sure, that he isn't an disinvitee.
      if (entry.disinvitees != null) entry.disinvitees.remove(user.id);
      setLibraryEntry(entry).then((entry) { 
        activityStream.add(new Activity(ActivityType.INVITED, entry, user));
      });
    }
    // Assign the user to all assigned entries.
    Iterable entries = getEntriesByTopic(entry);
    if (entries != null) {
      entries.forEach((entry) => inviteUserToEntry(entry, user));
    }
  }
  
  /// Assigns the given library entry to given topic.
  void unsubscribeUserFromEntry(var user, var entry, bool disinvite) {
    if (entry is String) entry = getLibraryEntryOrTopic(entry);
    if (user is String) user = getUser(user);
    if (entry == null || user == null) return;
   
    // Delete user from participants.      
    if (entry.participants != null) entry.participants.remove(user.id);
    // Delete user from invitees.
    if (entry.invitees != null) entry.invitees.remove(user.id);
    if (disinvite) {
      // Add user to disinvitees, if it isn't already.
      List disinv = entry.disinvitees != null ? entry.disinvitees : [];
      if (!disinv.contains(user.id)) entry.disinvitees = disinv..add(user.id);
    } else {
      // Remove user from disinvitees.
      if (entry.disinvitees != null) entry.disinvitees.remove(user.id);
    }
    // Set the library entry. 
    setLibraryEntry(entry).then((entry) {
      activityStream.add(new Activity(ActivityType.UNSUBSCRIBED, entry, user));
    });
    
    // Reject the user from all assigned entries.
    Iterable entries = getEntriesByTopic(entry);
    if (entries != null) {
      entries.forEach((e) => unsubscribeUserFromEntry(user, e, disinvite));
    }
  }
    
  /// Acknowledges an incoming invite request.
  void acknowledgeInviteRequest(var user, var entry) {
    if (user is String) user = getLibraryEntry(user);
    if (entry is String) entry = getLibraryEntryOrTopic(entry);
    if (user == null || entry == null) return;
    if (entry.invitees != null) entry.invitees.remove(user.id);
    if (entry.disinvitees != null) entry.disinvitees.remove(user.id);
    List participants = entry.participants != null ? entry.participants : [];
    entry.participants = participants..add(user.id);
    setLibraryEntry(entry);
  }
  
  /// Acknowledges an incoming disinvite request.
  void acknowledgeDisinviteRequest(var user, var entry) {
    if (user is String) user = getUser(user);
    if (entry is String) entry = getLibraryEntryOrTopic(entry);
    if (user != null && entry != null) {
      if (entry.disinvitees != null) entry.disinvitees.remove(user.id);
      if (entry.invitees != null) entry.invitees.remove(user.id);
      if (entry.participants != null) entry.participants.remove(user.id);
      setLibraryEntry(entry);
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
  Map getUsers([userIds]) => userCache.getUsers(userIds);
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
  LibraryEntry getLibraryEntryOrTopic(id) => libEntryCache.get(id);
  /// Returns the library entry with given id.
  LibraryEntry getLibraryEntry(id) => libEntryCache.getLibraryEntry(id);
  /// Caches the given library entry.
  Future setLibraryEntry(entry) => libEntryCache.setLibraryEntry(entry);
  /// Deletes the given library entry.
  Future deleteLibraryEntry(entry) => libEntryCache.deleteLibraryEntry(entry);
   
  /// Returns the topics.
  Map getTopics([topicIds]) => libEntryCache.getTopics(topicIds);
  /// Returns the topic with given id.
  LibraryEntry getTopic(id) => libEntryCache.getTopic(id);
  /// Caches the given topic.
  Future setTopic(topic) => libEntryCache.setTopic(topic);
  /// Deletes the given topic and rejects all assigned entries from topic.
  void deleteTopicAndRejectEntries(user, topic) { 
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
  Map getPdfAnnots(entry) => getCache(entry).getPdfAnnots(); 
  /// Sets the given pdf annotations of given entry.
  Future setPdfAnnots(entry, annots) => getCache(entry).setPdfAnnots(annots);
  /// Sets the given pdf annotation of given library entry.
  Future setPdfAnnot(entry, annot) => getCache(entry).setPdfAnnot(annot);
  /// Deletes the pdf annotations of given entry.
  Future deletePdfAnnots(entry) => getCache(entry).deletePdfAnnots();
  /// Deletes the given feed entry.
  Future deletePdfAnnot(entry, annot) => getCache(entry).deletePdfAnnot(annot);
      
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
  
  /// Returns a stream for activity events.  
  Stream get onActivity => activityStream.stream;
 
  bool userIsOwner(LibraryEntry entry) {
    return (auth.user != null && auth.user.isOwner(entry));
  }
  
  /// Shows loading notification. If entry is null, the notification is global.
  void loading(String msg, {Pouchable pouchable, Function onClick}) {
    notificationUtil.loading(msg, pouchable: pouchable, onClick: onClick);
  }
}

/// The activities.
class Activity {
  ActivityType type;
  LibraryEntry entry;
  User user;
  Activity(this.type, this.entry, this.user);
}

class ActivityType {
  final String name;
  static const CREATED = const ActivityType._internal("1");
  static const INVITED = const ActivityType._internal("2");
  static const UNSUBSCRIBED = const ActivityType._internal("3");
  static const TOPIC_ASSIGNED = const ActivityType._internal("4");
  static const TOPIC_REJECTED = const ActivityType._internal("5");
  
  const ActivityType._internal(this.name);
}