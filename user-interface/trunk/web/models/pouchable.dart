part of models;

/// Interface Pouchable. To store an object into a PouchDb, it must implement
/// this interface.
class Pouchable extends Observable {
  @observable Map map;
  /// Temporary properties (will not be stored in db).
  @observable Notification notification;  
  
  DateFormat dateFormat = new DateFormat.yMMMMd("en_US").add_Hms();
  
  /// The constructor.
  Pouchable() {
    this.map = {};
    this.created = new DateTime.now();
  }
  
  /// Creates a pouchable from json.
  Pouchable.fromJson(String json) : this.fromMap(JSON.decode(json));
  
  /// Creates a pouchable from map.
  Pouchable.fromMap(Map map) {
    this.map = {};
    map.forEach((key, value) => this[key] = value);
    if (this.created == null) this.created = new DateTime.now();
  }
  
  /// Clones the given pouchable.
  Pouchable.clone(Pouchable pouchable) {
    this.map = {};
    if (pouchable != null && pouchable.map != null) {
      pouchable.map.forEach((key, value) => this[key] = value);
    }
  }
  
  /// Transforms the pouchable to map.
  Map toMap() => this.map;
    
  /// Sets the id.
  set id(value) => this['_id'] = value;
  
  /// Sets the rev.
  set rev(value) => this['_rev'] = value;
  
  /// Sets the brand.
  set brand(value) => this['brand'] = value;
  
  /// Sets the creation date.
  set created(DateTime value) => this['created'] = dateFormat.format(value); 

  /// Sets the modify date.
  set modified(DateTime value) => this['modified'] = dateFormat.format(value); 
  
  // ___________________________________________________________________________
  
  /// Returns the id.
  get id => this['_id'];
  
  /// Returns the rev.
  get rev => this['_rev'];
  
  /// Returns the brand.
  get brand => this['brand'];
  
  /// Returns the creation date.
  get created => this['created'];
  
  /// Returns the modify date.
  get modified => this['modified'];
  
  // ___________________________________________________________________________
  
  /// Enriches the entry with all properties of other entry, which are not 
  /// included yet.
  bool enrich(other, {bool overwrite: false}) {
    if (other is List) {
      bool changed = false;
      other.forEach((Pouchable e) {
        changed = changed || apply(e.toMap(), overwrite: overwrite);
      });
      return changed;
    } else if (other is Pouchable) {
      return apply(other.toMap(), overwrite: overwrite);
    }
    return false;
  }
  
  /// Applies the parameters of the given map to entry.
  bool apply(Map map, {bool overwrite: false}) {
    bool changed = false;
    if (map != null) {
      for (var key in map.keys) {
        if (overwrite || !this.map.containsKey(key)) {
          this[key] = map[key];
          changed = true;
        }
      }
    }
    return changed;
  }
    
//  /// Returns a string representation of given object.
//  stringify(var value) {
//    if (value != null) {
//      if (value is String) return value;
//      if (value is List) {
//        for (int i = 0; i < value.length; i++) {
//          if (value[i] != null) value[i] = stringify(value[i]);
//        };
//        return value;
//      }
//      if (value is Map) {
//        for (var key in value.keys) {
//          if (value[key] != null) value[key] = stringify(value[key]);
//        };
//        return value;
//      }
//      return value.toString();    
//    }
//  }
  
  /// Creates a json string from pouchable.
  String toJson() => JSON.encode(map);
  
  /// Returns a string representation of this library entry.
  String toString() => toJson();
         
  /// Returns the hashCode of this library entry.
  get hashCode => super.hashCode;
  
  /// Sets a specific property of library entry.
  operator[] (key) => map[key];
  
  /// Returns a specific property of library entry.
  operator[]= (key, value) {
    if (key == null) return;
    if (value == null) map.remove(key);
    else map[key] = value; 
  }
}