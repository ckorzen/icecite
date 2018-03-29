part of models;

/// A search entry.
class SearchEntry extends Entry {  
  @observable String externalId;
  @observable String externalSource;
  
  /// The constructor.
  SearchEntry() : super(PouchableType.SEARCH_ENTRY);
  
  /// Creates a search entry from map.
  SearchEntry.fromData(this.externalSource, Map data) : super.fromData(PouchableType.SEARCH_ENTRY, data);
  
  /// Creates a search entry from json.
  SearchEntry.fromJson(this.externalSource, String json) : super.fromJson(PouchableType.SEARCH_ENTRY, json);
        
  Future persist() {
    return new Future.value();
  }
}