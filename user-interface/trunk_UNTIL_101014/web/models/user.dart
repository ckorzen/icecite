part of models;

/// An entry of the library.
class User extends Pouchable {      
  /// The constructor.
  User(String id) {
    this.id = id;
  }
  
  /// The constructor.
  User.fromMap(Map map) : super.fromMap(map);
  
  /// The constructor.
  User.fromJson(String json) : super.fromJson(json);
      
  // ___________________________________________________________________________
  // Setters.
  
  /// Sets the first name.
  set firstName(value) => this['firstName'] = value;
  
  /// Sets the last name.
  set lastName(value) => this['lastName'] = value;
  
  /// Sets the email.
  set email(value) => this['email'] = value;
  
  // ___________________________________________________________________________
  // Getters.
   
  /// Returns the first name.
  get firstName => this['firstName'];
  
  /// Returns the last name.
  get lastName => this['lastName'];
    
  /// Returns the email.
  get email => this['email'];
}