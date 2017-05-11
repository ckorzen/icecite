part of models;

/// A feed entry.
class FeedEntry extends Pouchable {
  /// The default constructor.
  FeedEntry(String data, bool isActivity) {
    this.data = data;
    this.brand = "feed";
    this.isActivity = isActivity;
  }
       
  /// Creates a pouchable from map.
  FeedEntry.fromMap(Map map) : super.fromMap(map);
  
  // ___________________________________________________________________________
  // Setters.
  
  /// Sets the user.
  set userId(value) => this['user'] = value;
      
  /// Sets the data.
  set data(value) => this['data'] = value;
    
  /// Sets the activity flag.
  set isActivity(value) => this['isActivity'] = value;
  
  // ___________________________________________________________________________
  // Getters.
      
  /// Returns the user.
  get userId => this['user'];
      
  /// Returns the data.
  get data => this['data'];
  
  /// Returns the activity flag.
  get isActivity => this['isActivity'] == 'true' ? true : false;
}