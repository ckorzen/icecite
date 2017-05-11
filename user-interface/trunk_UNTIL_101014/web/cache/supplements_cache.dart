library supplements_cache;

import 'dart:async';
import 'dart:mirrors';
import 'cache_impl.dart';
import '../models/models.dart';
import '../properties.dart';
import 'database/pouch_db.dart';

part 'supplements_conflict_resolver.dart';
part 'supplements_pouch_db.dart';

/// The supplements cache. Primarily, it holds the references of an entry, but
/// also the feed entries and the pdf annotations.
class SupplementsCache extends Cache<String, LibraryEntry> { 
  /// The internal instance.
  static Map<String, SupplementsCache> _caches = {};
  /// The instance of FeedEntryPouchDb.
  SupplementsPouchDb db;
  bool isFilled;
  
  /// The cache with feed entries.
  Map<String, FeedEntry> feedEntryCache;
  /// The cache with annots.
  Map<String, PdfAnnotation> annotsCache;

  /// The various stream controllers.
  StreamController fillStream;
  StreamController<LibraryEntry> referenceChangedStream;
  StreamController<LibraryEntry> referenceDeletedStream;
  StreamController<PdfAnnotation> pdfAnnotChangedStream;
  StreamController<PdfAnnotation> pdfAnnotDeletedStream;
  StreamController<FeedEntry> feedEntryChangedStream;
  StreamController<FeedEntry> feedEntryDeletedStream;
  
  static SupplementsCache getCache(var entry) {
    if (entry == null) return null;
    String entryId = (entry is LibraryEntry) ? entry.id : entry;
    if (!_caches.containsKey(entryId)) {
      _caches[entry.id] = new SupplementsCache._internal(entryId);
    } else {
      // TODO: Do we need the following snippet?
//      // Fill the instance, if it isn't filled yet (cache is cleared on logout).
//      if (!_caches[entry.id].isFilled) {
//        print("XXX");
//        _caches[entry.id].fill(); 
//      }
    }
    return _caches[entry.id];
  }
  
  /// The internal constructor.
  SupplementsCache._internal(String entryId) {
    isFilled = false;
    feedEntryCache = {};
    annotsCache = {};
    
    // Declare the stream controllers.
    fillStream = new StreamController.broadcast();
    referenceChangedStream = new StreamController<LibraryEntry>.broadcast();
    referenceDeletedStream = new StreamController<LibraryEntry>.broadcast();
    pdfAnnotChangedStream = new StreamController<PdfAnnotation>.broadcast();
    pdfAnnotDeletedStream = new StreamController<PdfAnnotation>.broadcast();
    feedEntryChangedStream = new StreamController<FeedEntry>.broadcast();
    feedEntryDeletedStream = new StreamController<FeedEntry>.broadcast();
    
    db = new SupplementsPouchDb(DB_SUPPLEMENTS_NAME(entryId)); 
    db.onSupplementChanged.listen((supp) => supplementChangedHandler(supp));
    db.onSupplementDeleted.listen((supp) => supplementDeletedHandler(supp));
    db.sync(DB_SUPPLEMENTS_URL(entryId));
    fill();
  }
     
  /// Resets the cache.
  void resetOnLogout() {
    _caches.clear();
    this.isFilled = false;
    if (this.feedEntryCache != null) this.feedEntryCache.clear();
    if (this.annotsCache != null) this.annotsCache.clear();
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// Define the behavior when a supplement in storage was added or updated.
  void supplementChangedHandler(Pouchable pouchable) {
    if (pouchable != null) _cacheSupplement(pouchable);
  }
  
  /// Define the behavior when a supplement in storage was deleted.
  void supplementDeletedHandler(String supplementId) {
    if (supplementId != null) _uncacheSupplement(getSupplement(supplementId));
  }
  
  // ___________________________________________________________________________
  // Database actions.
    
  void fill() {
    db.getSupplements().then((list) {
      if (list != null) list.forEach((supplement) {
        _cacheSupplement(supplement, avoidFire: true);
      });
      fillStream.add(null);
      isFilled = true;
    });
  }
    
  /// Sets the given references.
  Future setReferences(Iterable<LibraryEntry> references) {
    return db.setReferences(references); 
  }
  
  /// Sets the given reference.
  Future setReference(LibraryEntry reference) {
    return db.setReference(reference); 
  }
    
  /// Deletes the given references.
  Future deleteReferences() {   
    return db.deleteReferences(this.values);
  }
  
  /// Deletes the given reference.
  Future deleteReference(LibraryEntry reference) {   
    return db.deleteReference(reference);
  }
  
  /// Sets the given annotations.
  Future setPdfAnnotations(Iterable<PdfAnnotation> annots) {
    return db.setPdfAnnotations(annots); 
  }
  
  /// Sets the given annotation.
  Future setPdfAnnotation(PdfAnnotation annot) {
    return db.setPdfAnnotation(annot); 
  }
    
  /// Deletes the given user.
  Future deletePdfAnnotations() {   
    return db.deletePdfAnnotations(this.annotsCache.values);
  }
  
  /// Deletes the given user.
  Future deletePdfAnnotation(PdfAnnotation annot) {   
    return db.deletePdfAnnotation(annot);
  }
  
  /// Sets the given feed entries.
  Future setFeedEntries(Iterable<FeedEntry> feeds) {
    return db.setFeedEntries(feeds); 
  }
  
  /// Sets the given feed entry.
  Future setFeedEntry(FeedEntry feed) {
    return db.setFeedEntry(feed); 
  }
    
  /// Deletes the given feed entries.
  Future deleteFeedEntries() {   
    return db.deleteFeedEntries(this.feedEntryCache.values);
  }
  
  /// Deletes the given feed entry.
  Future deleteFeedEntry(FeedEntry feed) {   
    return db.deleteFeedEntry(feed);
  }
  
  // ___________________________________________________________________________
  // Getters.
  
  /// Returns the reference / annot / feed entry with given id.
  Pouchable getSupplement(String id) {
    // Check, if entry is reference.
    if (this[id] != null) return this[id];
    // Check, if entry is an annot.
    if (annotsCache[id] != null) return annotsCache[id];
    // Check, if entry is a feed entry.
    if (feedEntryCache[id] != null) return feedEntryCache[id];
    return null;
  }
  
  /// Returns the references.
  Map<String, LibraryEntry> getReferences() {
    return this;
  }
  
  /// Returns the reference with given id.
  LibraryEntry getReference(String id) {
    return this[id];
  }
  
  /// Returns the pdf annotations.
  Map<String, PdfAnnotation> getPdfAnnotations() {
    return annotsCache;
  }
  
  /// Returns the pdf annotation with given id.
  PdfAnnotation getPdfAnnotation(String id) {
    return annotsCache[id];
  }
  
  /// Returns the feed entries.
  Map<String, FeedEntry> getFeedEntries() {
    return feedEntryCache;
  }
  
  /// Returns the feed entry with given id.
  FeedEntry getFeedEntry(String id) {
    return feedEntryCache[id];
  }
    
  // ___________________________________________________________________________
  // Helpers.
  
  /// Caches the given entry.
  void _cacheSupplement(Pouchable pouchable, {bool avoidFire: false}) {
    if (pouchable != null) {
      // Check, if pouchable is a reference.
      if (pouchable.brand == 'reference') {
//        LibraryEntry cachedReference = this[pouchable.id];
//        if (cachedReference == null || cachedReference.rev < pouchable.rev) {
          // change reference, if there is no cached reference or if the cached
          // reference is older than the reference to insert.
          this[pouchable.id] = pouchable; // TODO: cast?
          if (!avoidFire) referenceChangedStream.add(pouchable);
//        }
      }
                
      // Check, if pouchable is a pdf annotation.
      if (pouchable.brand == 'annot') {
//        PdfAnnotation cachedAnnot = annotsCache[pouchable.id];
//        if (cachedAnnot == null || cachedAnnot.rev < pouchable.rev) {
          // change annot, if there is no cached annot or if the cached
          // annot is older than the annot to insert.
          annotsCache[pouchable.id] = pouchable; // TODO: cast?
          if (!avoidFire) pdfAnnotChangedStream.add(pouchable);
//        }        
      }
      
      // Check, if entry is a feed entry.
      if (pouchable.brand == 'feed') {
//        FeedEntry cachedFeed = feedEntryCache[pouchable.id];
//        if (cachedFeed == null || cachedFeed.rev < pouchable.rev) {
//          // change annot, if there is no cached annot or if the cached
//          // annot is older than the annot to insert.
          feedEntryCache[pouchable.id] = pouchable; // TODO: cast?
          if (!avoidFire) {
            feedEntryChangedStream.add(pouchable);
          }
//        }         
      }
    }
  }
  
  /// Uncaches the given entry.
  void _uncacheSupplement(Pouchable pouchable, {bool avoidFire: false}) {
    if (pouchable != null) {
      // TODO: Use attachments as indicator for entry?
      // Check, if pouchable is a reference.
      if (pouchable.brand == 'reference') {
        LibraryEntry removedRef = this.remove(pouchable.id);
        if (removedRef != null && !avoidFire) 
          referenceDeletedStream.add(pouchable); // TODO: Cast?
      } 
      
      // Check, if pouchable is a reference.
      if (pouchable.brand == 'annot') {
        PdfAnnotation removedAnnot = annotsCache.remove(pouchable.id);
        if (removedAnnot != null && !avoidFire) 
          pdfAnnotDeletedStream.add(pouchable); // TODO: Cast?
      } 
      
      // Check, if pouchable is a feed entry.
      if (pouchable.brand == 'feed') {
        FeedEntry removedFeed = feedEntryCache.remove(pouchable.id);
        if (removedFeed != null && !avoidFire) 
          feedEntryDeletedStream.add(pouchable); // TODO: Cast?
      }
    }
  }
  
  // Override the clear method.
  void clear() {
    super.clear();
    annotsCache.clear();
    feedEntryCache.clear();
    isFilled = false;
  }
  
  void close() {
    db.close();
    referenceChangedStream.close();
    referenceDeletedStream.close();
    pdfAnnotChangedStream.close();
    pdfAnnotDeletedStream.close();
    feedEntryChangedStream.close();
    feedEntryDeletedStream.close();
    fillStream.close();
  }
  
  // ___________________________________________________________________________
  // The streams.
  
  /// Returns a stream for filled events.
  Stream get onFilled => fillStream.stream;
  
  /// Returns a stream for reference changed events.  
  Stream get onReferenceChanged => referenceChangedStream.stream; 
  
  /// Returns a stream for reference deleted events.  
  Stream get onReferenceDeleted => referenceDeletedStream.stream;
  
  /// Returns a stream for annot changed events.  
  Stream get onPdfAnnotChanged => pdfAnnotChangedStream.stream;
  
  /// Returns a stream for annot deleted events.  
  Stream get onPdfAnnotDeleted => pdfAnnotDeletedStream.stream;
  
  /// Returns a stream for feed entry changed events.  
  Stream get onFeedEntryChanged => feedEntryChangedStream.stream;
  
  /// Returns a stream for feed entry deleted events.  
  Stream get onFeedEntryDeleted => feedEntryDeletedStream.stream;
}