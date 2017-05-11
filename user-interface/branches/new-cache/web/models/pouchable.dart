@MirrorsUsed(symbols: '*')
part of models;

/// Interface Pouchable. To store an object into a PouchDb, it must implement
/// this interface.
abstract class Pouchable extends Observable {
  Logger LOG = logging.get("pouchable");
  
  /// Observable properties.
  @observable Map data = toObservable({});
  @observable Notification notification;
  
  /// The date formatter.
  DateFormat dateFormat = new DateFormat.yMMMMd("en_US").add_Hms();
  /// The uuid generator.
  Uuid uuid = new Uuid();
  /// The queue of db transactions.
  Queue<Map> dbQueue = new Queue<Map>();
  
  /// The default constructor.
  Pouchable(PouchableType type, {Map data}) {
    this['_id'] = uuid.v4();
    this['created'] = new DateTime.now().millisecondsSinceEpoch;
    
    if (data != null) {
      data.forEach((key, value) => this[key] = value);
    }
    this['type'] = type.toString();
  }
    
  /// Creates a pouchable from map.
  Pouchable.fromData(PouchableType type, Map data) : this(type, data: data);
  
  /// Creates a pouchable from json.
  Pouchable.fromJson(PouchableType type, String json) : 
    this.fromData(type, JSON.decode(json));
      
  // ___________________________________________________________________________
      
  /// Sets the id.
  set id(value) => enqueue({'_id': value});
  
  /// Sets the rev.
  set rev(value) => enqueue({'_rev': value});
  
  /// Sets the type.
  set type(value) => enqueue({'type': value});
  
  /// Sets the parentId.
  set parentId(value) => enqueue({'parentId': value});
  
  /// Sets the userId.
  set userId(value) => enqueue({'userId': value});
  
  /// Sets the creation date.
  set created(int value) => enqueue({'created': value}); 

  /// Sets the modify date.
  set modified(int value) => enqueue({'modified': value}); 
  
  // ___________________________________________________________________________
  
  /// Returns the id.
  get id => this['_id'];
  
  /// Returns the rev.
  get rev => this['_rev'];
  
  /// Returns the type.
  get type => this['type'];
  
  /// Returns the parentId.
  get parentId => this['parentId'];
  
  /// Returns the userId.
  get userId => this['userId'];
  
  /// Returns the creation date.
  get created => this['created'] is int ? new DateTime.fromMillisecondsSinceEpoch(this['created']) : "";
  
  /// Returns the modify date.
  get modified => this['modified'] is int ? new DateTime.fromMillisecondsSinceEpoch(this['modified']) : "";
  
  // ___________________________________________________________________________
  
  /// Transforms the pouchable to map.
  Map toMap() => this.data;
  
  /// Creates a json string from pouchable.
  String toJson() => JSON.encode(data);
    
  /// Returns a string representation of this library entry.
  String toString() => toJson();
         
  // ___________________________________________________________________________
  
  /// Sets a specific property of library entry.
  operator[] (key) => data[key];
  
  /// Returns a specific property of library entry.
  operator[]= (key, value) {
    if (key == null) return;
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }    
    notifyPropertyChange(_getSymbol(key), 0, 1);
  }
  
  /// Applies all the given data. That overwrites(!) existing properties. 
  bool applyData(Map data) {
    if (data == null) return false;
    
    bool applied = false;
    data.forEach((key, value) {
      if (!_isEqual(this[key], value)) {
        this[key] = value;
        applied = true;
      }
    });
    this.data = new ObservableMap.from(this.data);
       
    return applied;
  }
  
  // ___________________________________________________________________________
  
  /// Enqueues the given annotation to ensure, that the proper rev is used.
  void enqueue(Map transaction) {
    var wasEmpty = dbQueue.isEmpty;
    dbQueue.add(transaction);
    if (wasEmpty) processDbQueue();
  }
   
  /// Processes the db queue.
  void processDbQueue() {
    Map transaction = dbQueue.first;
        
    LOG.finest("Process db queue: $transaction");
    
    /// Perform the transaction.
    if (applyData(transaction)) {  
      // Set modification date.
      this['modified'] = new DateTime.now().millisecondsSinceEpoch;
      
      persist().then((result) {
        this['_rev'] = result.rev;
        dbQueue.removeFirst();
        if (dbQueue.isNotEmpty) processDbQueue();
      }).catchError((e) {
        dbQueue.removeFirst();
        if (dbQueue.isNotEmpty) processDbQueue(); // TODO: It doesn't make sense, to process here.
      });
    } else {
      dbQueue.removeFirst();
      if (dbQueue.isNotEmpty) processDbQueue();
    }
  }
  
  Future<Pouchable> persist();
  
  void loading(String msg, {Function onAbort}) {
    this.notification = new Notification(NotificationType.LOADING, msg, 
        onAbort: onAbort);
  }
  
  void error(String msg) {
    this.notification = new Notification(NotificationType.ERROR, msg);
  }
  
  void success(String msg) {
    this.notification = new Notification(NotificationType.SUCCESS, msg);
  }
  
  void info(String msg) {
    this.notification = new Notification(NotificationType.INFO, msg);
  }
  
  void warn(String msg) {
    this.notification = new Notification(NotificationType.WARN, msg);
  }
  
  /// Returns the symbol for associated getter of map key. In most cases, the
  /// smybol name is equal to the key name. But for example, for the key "_rev"
  /// the name of getter is "rev".
  Symbol _getSymbol(String key) {
    if (key == null) return null; 
    if (key.startsWith("_")) {
      key = key.replaceFirst("_", "");
    }
    key = key.replaceAll("-", "");
    return new Symbol(key);
  }
  
  bool _isEqual(Object o1, Object o2) {
    if (identical(o1, o2)) return true;
    if (o1 == o2) return true;
    
    if (o1 is Iterable && o2 is Iterable) {
      if (o1.length != o2.length) return false;
      for (int i = 0; i < o1.length; i++) {
        if (!_isEqual(o1.elementAt(i), o2.elementAt(i))) return false; 
      }
      return true;
    }
    
    if (o1 is Map && o2 is Map) {
      if (o1.length != o2.length) return false;
      for (int i = 0; i < o1.length; i++) {
        if (!_isEqual(o1[i], o2[i])) return false; 
      }
      return true;
    }
    return false;
  }
}

// _____________________________________________________________________________

/// The class PouchableType. 
class PouchableType {
  /// The type of this pouchable.
  final String _type;
  /// The internal constructor.
  const PouchableType._internal(this._type);
    
  static PouchableType fromData(String data) => types[data];
  
  /// The type library-entry.
  static const LIBRARY_ENTRY = const PouchableType._internal('library-entry');
  
  /// The type search-entry.
  static const SEARCH_ENTRY = const PouchableType._internal('search-entry');
  
  /// The type reference-entry.
  static const REFERENCE_ENTRY = const PouchableType._internal('reference-entry');
  
  /// The type pdf-annotation.
  static const PDF_ANNOTATION = const PouchableType._internal('pdf-annotation');
  
  /// The type user.
  static const USER = const PouchableType._internal('user');
  
  /// The types in a map.
  static Map<String, PouchableType> types = {
    LIBRARY_ENTRY._type: LIBRARY_ENTRY,
    SEARCH_ENTRY._type: SEARCH_ENTRY,
    REFERENCE_ENTRY._type: REFERENCE_ENTRY,
    PDF_ANNOTATION._type: PDF_ANNOTATION,
    LIBRARY_ENTRY._type: LIBRARY_ENTRY,
    USER._type: USER,
  };
  
  /// Returns a string representation of this type.
  String toString() => _type;
  
  /// Returns a json representation of this type.
  String toJson() => toString();
}