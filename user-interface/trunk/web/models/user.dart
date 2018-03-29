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
  
  // ___________________________________________________________________________
  
  /// Returns true, iff the user is invited to the given entry.
  bool isInvited(LibraryEntry entry) {
    if (entry == null) return false;
    if (entry.invitees != null && entry.invitees.contains(id)) return true;
    return false;
  }
  
  /// Returns true, iff the user is disinvited from the given entry.
  bool isDisinvited(LibraryEntry entry) {
    if (entry == null) return false;
    return (entry.disinvitees != null && entry.disinvitees.contains(id));
  }
  
  /// Returns true, if the user is the owner of the given entry.
  bool isOwner(LibraryEntry entry) {
    if (entry == null) return false;
    if (entry.owner == null) return false;
    if (entry.owner == id) return true;
    return false;  
  }
  
  /// Returns true, if the user is the owner or a participant of the entry.
  bool isParticipant(LibraryEntry entry) {
    if (entry == null) return false;
    return (entry.participants != null && entry.participants.contains(id));
  }
  
  /// Returns true, if the user is the owner or a participant of the entry.
  bool isOwnerOrParticipant(LibraryEntry entry) {
    return isOwner(entry) || isParticipant(entry);
  }
  
  /// Returns true, if the user is the owner, a participant, invited or disinvited.
  bool isRelatedTo(LibraryEntry entr) {
    return isOwnerOrParticipant(entr) || isInvited(entr) || isDisinvited(entr);
  }
}