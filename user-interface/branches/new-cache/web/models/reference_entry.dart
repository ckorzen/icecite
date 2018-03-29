part of models;

/// A reference entry.
class ReferenceEntry extends Entry {  
  /// The constructor.
  ReferenceEntry() : super(PouchableType.REFERENCE_ENTRY);
  
  /// Creates a reference entry from map.
  ReferenceEntry.fromData(Map data) : super.fromData(PouchableType.REFERENCE_ENTRY, data);
   
  /// Creates a reference entry from json.
  ReferenceEntry.fromJson(String json) : super.fromJson(PouchableType.REFERENCE_ENTRY, json);
  
  Future persist() {
    return new Future.value();
  }
  
  /// Sets the tags.
  get positionInBibliography => this['positionInBibliography']; 
  
  /// Sets the tags.
  set positionInBibliography(value) => enqueue({'positionInBibliography': value}); 
}