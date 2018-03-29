@MirrorsUsed(symbols: '*')
part of models;

/// An entry of the library.
class LibraryEntry extends Entry with Observable {    
  // @observable String title = "Hello World";
  
  @observable bool hasReplacedSearchEntry = false;
  
  /// The instance of LibraryEntryPouchDb.
  LibraryEntryPouchDb _libraryDb;
  /// The instance of SupplementsPouchDb.
  SupplementsPouchDb _supplementsDb;
   
  /// The replication objects.
  JsObject replicationTo;
  JsObject replicationFrom;
  
  /// The cached references.
  Map<String, ReferenceEntry> references;
  /// The cached annotations.
  Map<String, PdfAnnotation> annots;
  /// The cached pdf.
  Blob pdf;

  /// The various streams controllers.
  StreamController<ReferenceEntry> referenceUpdatedStream;
  StreamController<ReferenceEntry> referenceDeletedStream;
  StreamController<PdfAnnotation> annotUpdatedStream;
  StreamController<PdfAnnotation> annotDeletedStream;
    
  /// The logger.
  Logger LOG = new Logger("library-entry");
  
  /// The constructor.
  LibraryEntry(User owner) : super(PouchableType.LIBRARY_ENTRY, user: owner) {
    initializeStreamControllers();
  }
  
  /// Creates a library entry from map.
  LibraryEntry.fromData(Map map) : 
      super.fromData(PouchableType.LIBRARY_ENTRY, map)  {
    initializeStreamControllers();
  }
  
  /// Creates a library entry from json.
  LibraryEntry.fromJson(String json) : 
      super.fromJson(PouchableType.LIBRARY_ENTRY, json) {
    initializeStreamControllers();
  }
  
  /// Creates a library entry from json.
  LibraryEntry.fromSearchEntry(SearchEntry entry) : 
      super.fromJson(PouchableType.LIBRARY_ENTRY, entry.toJson()) {
    // Remove the rev.
    this['_id'] = this.id + "_" + uuid.v4();
    this['_rev'] = null;
    initializeStreamControllers();
  }
  
  /// Creates a library entry from json.
  LibraryEntry.fromReferenceEntry(ReferenceEntry entry) : 
      super.fromJson(PouchableType.LIBRARY_ENTRY, entry.toJson()) {
    this['created'] = new DateTime.now().millisecondsSinceEpoch;
    this['_id'] = this.id + "_" + uuid.v4();
    // Remove the rev.
    this['_rev'] = null;
    initializeStreamControllers();
  }
  
  /// Initializes the stream controllers.
  void initializeStreamControllers() {
    this.referenceUpdatedStream = new StreamController.broadcast();
    this.referenceDeletedStream = new StreamController.broadcast();
    this.annotUpdatedStream = new StreamController.broadcast();
    this.annotDeletedStream = new StreamController.broadcast();
  }
  
  /// Returns the instance to library entry db.
  LibraryEntryPouchDb get libraryDb {
    if (this._libraryDb == null) {
      this._libraryDb = new LibraryEntryPouchDb(new Auth().user);
    }
    return this._libraryDb;
  }
  
  /// Returns the instance to supplements db.
  SupplementsPouchDb get supplementsDb {
    if (this._supplementsDb == null) {
      this._supplementsDb = new SupplementsPouchDb(DB_SUPPLEMENTS_NAME(this.id));
      this._supplementsDb.onDbChange.listen(handleSupplementsDbChange); 
    }
    return this._supplementsDb;
  }
    
  /// Define the behavior when a supplement in storage was added or updated.
  void handleSupplementsDbChange(Map change) {
    LOG.finer("Handle supplements db change.");
    if (change == null) return;
        
    DbChangeAction action = change['action'];    
    switch (action) {
      case DbChangeAction.UPDATED:
        applySupplementsDbUpdateAction(change);
        break;
      case DbChangeAction.DELETED:
        applySupplementsDbDeleteAction(change);
        break;
      default:
        break;
    }  
  }
  
  /// Applies the given db update action.
  void applySupplementsDbUpdateAction(Map change) {
    LOG.finer("Apply supplements db update action.");
    if (change == null) return;
    Map data = change['data'];
    if (data == null) return;
      
    PouchableType type = PouchableType.fromData(data['type']);
        
    switch (type) {
      case PouchableType.REFERENCE_ENTRY:
        this.applyReferenceDbUpdateAction(change);
        break;
      case PouchableType.PDF_ANNOTATION:
        this.applyPdfAnnotationDbUpdateAction(change);
        break;
      default: 
        break;
    }
  }

  /// Applies the given db delete action.
  void applySupplementsDbDeleteAction(Map change) {
    if (change == null) return;
    Map data = change['data'];
    if (data == null) return;
    
    LOG.finer("Apply supplements db delete action.");
    
    PouchableType type = PouchableType.fromData(data['type']);
    
    switch (type) {
      case PouchableType.REFERENCE_ENTRY:
        this.applyReferenceDbDeleteAction(change);
        break;
      case PouchableType.PDF_ANNOTATION:
        this.applyPdfAnnotationDbDeleteAction(change);
        break;
      default: 
        break;
    }
  }
  
  /// Applies an update action on a reference.
  void applyReferenceDbUpdateAction(Map change) {
    LOG.finer("Apply reference db update action.");
    if (change == null) return;
    String id = change['id'];
    if (references != null && references.containsKey(id)) {
      Map data = change['data'];
      if (references[id].applyData(data)) {
        referenceUpdatedStream.add(references[id]); 
      }
    }
  }
  
  /// Applies an delete action on a reference.
  void applyReferenceDbDeleteAction(Map change) {
    LOG.finer("Apply reference db delete action.");
    if (change == null) return;
    String id = change['id'];
    if (references != null) {
      ReferenceEntry reference = references.remove(id);
      if (reference != null) {
        referenceDeletedStream.add(reference);
      }
    }
  }
  
  /// Applies an update action on an annotation.
  void applyPdfAnnotationDbUpdateAction(Map change) {
    LOG.finer("Apply pdf annotation db update action.");
    if (change == null) return;
    String id = change['id'];
    Map data = change['data'];
        
    if (annots != null) {
      if (annots.containsKey(id)) {
        if (annots[id].applyData(data)) {
           annotUpdatedStream.add(annots[id]);
        }
      } else {
        PdfAnnotation annot = new PdfAnnotation.fromData(data);
        annots[annot.id] = annot;
        annotUpdatedStream.add(annot);
      }
    }
  }
  
  /// Applies an delete action on an annotation.
  void applyPdfAnnotationDbDeleteAction(Map change) {
    LOG.finer("Apply pdf annotation db delete action.");
    if (change == null) return;
    String id = change['id'];
    if (annots != null) {
      PdfAnnotation annot = annots.remove(id);
      if (annot != null) {
        annotDeletedStream.add(annot);
      }
    }
  }
    
  // ___________________________________________________________________________
  // Pdf.
     
  Future<Blob> getPdf() {
    if (this.pdf != null) {
      return new Future.value(this.pdf);
    }
    
    Completer<Blob> completer = new Completer<Blob>();
    libraryDb.getPdf(this).then((pdf) {
      this.pdf = pdf;
      completer.complete(this.pdf);
    });
    return completer.future;
  }
  
  void setPdf(Blob pdf) => enqueue({'pdf': pdf});
  
  get attachments => this['_attachments'];
  
  bool get hasPdf => attachments != null;
       
  // ___________________________________________________________________________
  // References.
  
  Future<List<ReferenceEntry>> getReferences() {
    if (this.references != null) {
      return new Future.value(new List.from(this.references.values));
    }
      
    Completer completer = new Completer();
    supplementsDb.getSupplements().then((supplements) {
      classifySupplements(supplements);
      completer.complete(new List.from(this.references.values));
    });
    return completer.future;
  }
  
  Future setReferences(List<ReferenceEntry> references) {
    LOG.fine("Set references.");
    return supplementsDb.setReferences(references); 
  }
    
  Future setReference(ReferenceEntry reference) {
    LOG.fine("Set reference: $reference");
    return supplementsDb.setReference(reference); 
  }
  
  Future deleteReferences(List<ReferenceEntry> references) {
    LOG.fine("Delete references: $references");
    return supplementsDb.deleteReferences(references); 
  }
  
  Future deleteReference(ReferenceEntry reference) {
    LOG.fine("Delete reference: $reference");
    return supplementsDb.deleteReference(reference); 
  }
  
  // ___________________________________________________________________________
  // Annotations.
  
  Future<List<PdfAnnotation>> getPdfAnnotations() {
    if (this.annots != null) {
      return new Future.value(new List.from(this.annots.values));
    }  
    Completer completer = new Completer();
    supplementsDb.getSupplements().then((supplements) {
      classifySupplements(supplements);
      completer.complete(new List.from(this.annots.values));
    });
    return completer.future;
  }
  
  Future setPdfAnnotations(List<PdfAnnotation> annots) {
    LOG.fine("Set annots: $annots");
    return supplementsDb.setPdfAnnotations(annots);
  }
  
  Future setPdfAnnotation(PdfAnnotation annot) {
    LOG.fine("Set annots: $annot");
    return supplementsDb.setPdfAnnotation(annot);
  }
  
  Future deletePdfAnnotations([List<PdfAnnotation> annotations]) {
    LOG.fine("Delete annots: $annotations");
    return supplementsDb.deletePdfAnnotations(annotations); 
  }
    
  Future deletePdfAnnotation(PdfAnnotation annotation) {
    LOG.fine("Delete annot: $annotation");
    return supplementsDb.deletePdfAnnotation(annotation); 
  }

  void deleteSupplements() {
    LOG.fine("Delete all supplements.");
    getReferences().then((references) => deleteReferences(references));
    getPdfAnnotations().then((annots) => deletePdfAnnotations(annots));
  }
  
  // ___________________________________________________________________________
  
  /// Selects this library entry. Starts replication.
  void select() {
    this.selected = true;
    startSupplementsReplication();
  }
  
  /// Unselects this library entry.
  void unselect() {
    this.selected = false;
    stopSupplementsReplication();
  }
  
  /// Starts the replication of supplements.
  void startSupplementsReplication() {
    var replications = this.supplementsDb.sync(DB_SUPPLEMENTS_URL(this.id));
    this.replicationFrom = replications['from'];
    this.replicationTo = replications['to'];
  }
  
  /// Stops the replication of supplements.
  void stopSupplementsReplication() {
    if (this.replicationFrom != null) {
//      this.replicationFrom.callMethod("cancel");
      this.replicationFrom = null;
    }
    if (this.replicationTo != null) {
//      this.replicationTo.callMethod("cancel");
      this.replicationTo = null;
    }
  }
  
  /// Acknowledges an incoming invite request.
  void acknowledgeInviteRequest(User user) {
    if (user == null) return;
    
    LOG.finest("Acknowledging invite request for user $user");
    
    if (this.invitees != null) {
      List<String> invitees = new List.from(this.invitees);
      if (invitees.remove(user.id)) this.invitees = invitees;  
    }
    
    if (this.disinvitees != null) {
      List<String> disinvitees = new List.from(this.disinvitees);
      if (disinvitees.remove(user.id)) this.disinvitees = disinvitees;
    }
    
    List<String> participants = null;
    if (this.participants != null) {
      participants = new List.from(this.participants);
    } else {
      participants = [];
    }
    participants.add(user.id);
    this.participants = participants;
  }
  
  /// Acknowledges an incoming disinvite request.
  void acknowledgeDisinviteRequest(User user) {
    if (user == null) return; 
    
    LOG.finest("Acknowledging disinvite request for user $user");
    
    if (this.disinvitees != null) {
      List<String> disinvitees = new List.from(this.disinvitees);
      if (disinvitees.remove(user.id)) this.disinvitees = disinvitees;
    }
     
    if (this.invitees != null) {
      List<String> invitees = new List.from(this.invitees);
      if (invitees.remove(user.id)) this.invitees = invitees;
    }
     
    if (this.participants != null) {
      List<String> participants = new List.from(this.participants);
      if (participants.remove(user.id)) this.participants = participants;   
    }
  }
  
  // ___________________________________________________________________________
    
  @override
  Future<Pouchable> persist() {
    /// The transaction "set pdf" is queued (because it needs the current rev).
    /// To be able to queue this transaction, the property "pdf" with a blob as
    /// value is added to this entry. But because the pdf shouldn't be a 
    /// property of entry in database, we remove it here. If there is a pdf
    /// available, set it as attachments to this entry. 
    Blob pdf = this.data.remove("pdf");
    if (pdf != null) {
      return libraryDb.setPdf(this, pdf);
    }
    
    return libraryDb.setLibraryEntry(this);
  }
  
  bool get isMatched => this.externalKey != null;
  
  /// Classifies the given supplements.
  void classifySupplements(List<Pouchable> supplements) {
//    LOG.finer("Classifying supplements.");
    if (supplements == null) return;
    this.references = {};
    this.annots = {};
    supplements.forEach((Pouchable supplement) {
      PouchableType type = PouchableType.fromData(supplement.type);
      switch (type) {
        case PouchableType.REFERENCE_ENTRY:
          this.references[supplement.id] = supplement;
          break;
        case PouchableType.PDF_ANNOTATION:
          this.annots[supplement.id] = supplement;
          break;
        default: 
          break;
      }
    });
  }
  
  String get rootId => this.id.split("_")[0];
  
  // ___________________________________________________________________________
  
  /// Returns a stream for reference changed events.  
  Stream get onReferenceUpdated => referenceUpdatedStream.stream; 
  
  /// Returns a stream for reference deleted events.  
  Stream get onReferenceDeleted => referenceDeletedStream.stream;
  
  /// Returns a stream for annot changed events.  
  Stream get onAnnotUpdated => annotUpdatedStream.stream;
  
  /// Returns a stream for annot deleted events.  
  Stream get onAnnotDeleted => annotDeletedStream.stream;

}
  