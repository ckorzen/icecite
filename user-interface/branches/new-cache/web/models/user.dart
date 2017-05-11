part of models;

/// An entry of the library.
class User extends Pouchable {      
  /// The constructor.
  User(String id) : super(PouchableType.USER) {
    this['_id'] = id;
  }
      
  /// Creates a user from map.
  User.fromData(Map data) : super.fromData(PouchableType.USER, data);
  
  /// Creates a search entry from json.
  User.fromJson(String json) : super.fromJson(PouchableType.USER, json);
  
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
  
  /// Returns the full name.
  get fullName => "$firstName $lastName";
  
  /// Returns the full info.
  get fullInfo => "$fullName (${email.substring(0,5)})";
  
  // ___________________________________________________________________________
    
  /// Returns true, if the user is the owner of the given entry.
  bool isOwner(Entry entry) {
    if (entry == null) return false;
    if (entry.userId == null) return false;
    return (entry.userId == this.id);  
  }
  
  bool operator== (User other) {
    if (other == null) return false;
    return this.id == other.id;
  }
  
  Future persist() {
    return new Future.value();
  }
}

class UserRole {
  /// The userRole.
  final String _role;
  
  /// The internal constructor.
  const UserRole._internal(this._role);
  
  /// The role owner.
  static const OWNER = const UserRole._internal('owner');
  
  /// The role particiapnt.
  static const PARTICIPANT = const UserRole._internal('participant');
  
  /// The role invitee.
  static const INVITEE = const UserRole._internal('invitee');
  
  /// The role disinvitee.
  static const DISINVITEE = const UserRole._internal('disinvitee');
  
  /// The role alien.
  static const ALIEN = const UserRole._internal('alien');
  
  /// Returns a string representation of this role.
  String toString() => '$_role';
}