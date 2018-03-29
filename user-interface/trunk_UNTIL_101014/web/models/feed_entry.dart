part of models;

/// A feed entry.
class FeedEntry extends Pouchable {
  /// The default constructor.
  FeedEntry(User user, String data, String entryId) {
    this.user = user;
    this.data = data;
    this.entryId = entryId;
    this.brand = "feed";
  }
       
  /// Creates a pouchable from map.
  FeedEntry.fromMap(Map map) : super.fromMap(map);
  
  // ___________________________________________________________________________
  // Setters.
  
  /// Sets the entryId.
  set entryId(value) => this['entryId'] = value;
  
  /// Sets the user.
  set user(value) => this['user'] = value.toJson();
      
  /// Sets the data.
  set data(value) => this['data'] = value;
    
  // ___________________________________________________________________________
  // Getters.
    
  /// Returns the entryId.
  get entryId => this['entryId'];
  
  /// Returns the user.
  get user => new User.fromJson(this['user']);
      
  /// Returns the data.
  get data => this['data'];
}