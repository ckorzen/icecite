@MirrorsUsed(symbols: '*')
part of models;

/// An abstract entry.
abstract class Entry extends Pouchable with Observable {  
  @observable bool selected = false;
  // On unpeek, there is a css transition on background-color defined. The
  // transition takes place between the states isPeeked and wasPeeked. It 
  // guarantees, that the transition doesn't take place on other state chnages,
  // eg. on hovering or selecting an entry. If isPeeked is set to false, the 
  // property wasPeeked is also set to false after a while.  
  @observable bool isPeeked = false;
  @observable bool wasPeeked = false;
  
  Logger LOG = logging.get("entry");
  
  /// The default constructor.
  Entry(PouchableType type, {User user}) : super(type) {
    if (user != null) this['userId'] = user.id;
  }
  
  /// Creates an entry from Map.
  Entry.fromData(PouchableType type, Map map) : super.fromData(type, map);
  
  /// Creates an entry from Json.
  Entry.fromJson(PouchableType type, String json) : super.fromJson(type, json);
      
  // _________________________________________________________________________
  // Setters.
  
  /// Sets the title.
  set title(value) => enqueue({'title': value});
          
  /// Sets the external key.
  set externalKey(value) => enqueue({'externalKey': value});
   
  /// Sets the journal.
  set journal(value) => enqueue({'journal': value});
    
  /// Sets the year.
  set year(value) => enqueue({'year': value});
    
  /// Sets the url.
  set url(value) => enqueue({'url': value});
    
  /// Sets the ee.
  set ee(value) => enqueue({'ee': value});
    
  /// Sets the raw.
  set raw(value) => enqueue({'raw': value});
        
  /// Sets the authors.
  set authors(value) => enqueue({'authors': value});  
    
  /// Sets the authors string.
  set authorsStr(String authorsStr) {
    if (authorsStr == null) {
      data.remove('authors');
    } else {
      List authors = [];
      List<String> splitted = authorsStr.split(new RegExp("[,;]"));
      splitted.forEach((split) => authors.add(split.trim()));
      this.authors = authors;
    }
  }
  
  /// Sets the tags.
  set tags(value) => enqueue({'tags': value}); 
    
  /// Sets the participants.
  set participants(value) => enqueue({'participants': value}); 
  
  /// Sets the invitees.
  set invitees(value) => enqueue({'invitees': value});
  
  /// Sets the disinvitees.
  set disinvitees(value) => enqueue({'disinvitees': value});
     
  // ___________________________________________________________________________
  // Getters.
    
  /// Returns the title.
  get title => this['title'];
    
  /// Returns the authors.
  get authors => toObservable(this['authors']);
        
  /// Returns the external key.
  get externalKey => this['externalKey'];
    
  /// Returns the journal.
  get journal => this['journal'];
    
  /// Returns the year.
  get year => this['year'];
    
  /// Returns the url.
  get url => this['url'];
    
  /// Returns the ee.
  get ee => this['ee'];
    
  /// Returns the raw.
  get raw => this['raw'];
  
  /// Returns the tags.
  get tags => toObservable(this['tags']);
    
  /// Returns the participators.
  get participants => toObservable(this['participants']); 
  
  /// Returns the invitees.
  get invitees => toObservable(this['invitees']);
  
  /// Returns the disinvitees.
  get disinvitees => toObservable(this['disinvitees']);
  
  // ___________________________________________________________________________
  // TODO: Work with PouchableType.
  
  bool get isLibraryEntry => this.type == 'library-entry';
  
  bool get isReferenceEntry => this.type == 'reference-entry';
  
  bool get isSearchEntry => this.type == 'search-entry';
    
  int get numParticipants => participants != null ? participants.length : 0;
  
  int get numInvitees => invitees != null ? invitees.length : 0;
  
  int get numDisinvitees => disinvitees != null ? disinvitees.length : 0;
  
  bool get hasParticipants => numParticipants > 0;
  
  bool get hasInvitees => numInvitees > 0;
  
  bool get hasDisinvitees => numDisinvitees > 0;
    
  UserRole getUserRole(User user) {
    if (hasOwner(user)) return UserRole.OWNER;
    if (hasParticipant(user)) return UserRole.PARTICIPANT;
    if (hasInvitee(user)) return UserRole.INVITEE;
    if (hasDisinvitee(user)) return UserRole.DISINVITEE;
    return UserRole.ALIEN;
  }
  
  bool hasOwner(User user) {
    if (user == null) return false;
    return this.userId == user.id;
  }
  
  bool hasParticipant(User user) {
    if (!hasParticipants) return false;
    if (user == null) return false;
    return this.participants.contains(user.id);
  }
  
  bool hasInvitee(User user) {
    if (!hasInvitees) return false;
    if (user == null) return false;
    return this.invitees.contains(user.id);
  }
  
  bool hasDisinvitee(User user) {
    if (!hasDisinvitees) return false;
    if (user == null) return false;
    return this.disinvitees.contains(user.id);
  }
  
  /// Peeks this entry.
  void peek() {
    this.wasPeeked = true;
    this.isPeeked = true;
  }
  
  /// Unpeeks this entry.
  void unpeek() {
    this.isPeeked = false;
      new Timer(new Duration(seconds: 2), () {
      this.wasPeeked = false;
    });
  }
     
  // ___________________________________________________________________________
  
  bool get hasTags => (tags != null && tags.isNotEmpty);
  
  void addTags(List<String> tags) {
    LOG.finer("Add tags: $tags");
    List<String> newTags = this.tags != null ? new List.from(this.tags) : [];
    newTags.addAll(tags);
    this.tags = newTags; 
  }
  
  void addTag(String tag) {
    LOG.finer("Add tag: $tag");
    List<String> newTags = this.tags != null ? new List.from(this.tags) : [];
    newTags.add(tag);
    this.tags = newTags;
  }
  
  void updateTag(int index, String tag) {
    LOG.finer("Update tag: $tag");
    if (this.tags == null) return;
    List<String> newTags = new List.from(this.tags);
    if (index < 0 || index > newTags.length - 1) return;
    newTags[index] = tag;
    this.tags = newTags;
  }
  
  void deleteTag(int index) {
    LOG.finer("Delete tag: $index");
    if (this.tags == null) return;
    List<String> tags = new List.from(this.tags);
    if (index < 0 || index > tags.length - 1) return;
    String tag = tags.removeAt(index);
    if (tag != null) {
      this.tags = tags;  
    }
  }
  
  // __________
  
  /// Adds the given user to invitees.
  void addParticipant(User user) {
    if (user == null) return;
    if (hasParticipant(user)) return;
    if (hasOwner(user)) return;
    if (hasDisinvitee(user)) return;
    
    LOG.finer("Add participant: $user");
    
    List participants = this.participants != null ? new List.from(this.participants) : [];
    participants.add(user.id);
    this.participants = participants; 
  }
  
  /// Deletes the given user from participants. 
  void deleteParticipant(User user) {
    if (user == null) return;
    if (!hasParticipant(user)) return;
    
    LOG.finer("Delete participant: $user");
    
    List participants = new List.from(this.participants);
    if (participants.remove(user.id)) {
      this.participants = participants; 
    }
  }
  
  // ___________
  
  /// Adds the given user to invitees.
  void addInvitee(User user) {
    if (user == null) return;
    if (hasInvitee(user)) return;
    if (hasParticipant(user)) return;
    if (hasOwner(user)) return;
    
    LOG.finer("Add invitee: $user");
    
    List invitees = this.invitees != null ? new List.from(this.invitees) : [];
    invitees.add(user.id);
    this.invitees = invitees; 
  }
  
  /// Deletes the given user from invitees.
  void deleteInvitee(User user) {
    if (user == null) return;
    if (!this.hasInvitee(user)) return;
    
    LOG.finer("Delete invitee: $user");
    
    List invitees = new List.from(this.invitees);
    if (invitees.remove(user.id)) {
      this.invitees = invitees; 
    }
  }
  
  // ___________
  
  /// Adds the given user to disinvitees.
  void addDisinvitee(User user) {
    if (user == null) return;
    if (this.hasDisinvitee(user)) return;
    if (this.hasOwner(user)) return;
    
    LOG.finer("Add disinvitee: $user");
    
    List disinvitees = this.disinvitees != null ? new List.from(this.disinvitees) : [];
    disinvitees.add(user.id);
    this.disinvitees = disinvitees; 
  }
  
  /// Deletes the given user from disinvitees.
  void deleteDisinvitee(User user) {
    if (user == null) return;
    if (!this.hasDisinvitee(user)) return; 
    
    LOG.finer("Delete disinvitee: $user");
    
    List disinvitees = new List.from(this.disinvitees);
    if (disinvitees.remove(user.id)) {
      this.disinvitees = disinvitees; 
    }
  }
  
  // ___________
  
  /// Shares this entry with given user.
  void share(List<User> users) {
    if (users == null) return;
    
    for (User user in users) {
      if (hasOwner(user)) continue;
      if (hasParticipant(user)) continue;
      
      LOG.finer("Sharing with user: $user.");
      
      addInvitee(user);
      deleteDisinvitee(user);
    }
  }
  
  /// Unsubscribes the given user from this entry.
  void unshare(User user) {
    if (hasOwner(user)) return;
            
    LOG.finer("Unsharing user: $user.");
    
    if (hasParticipant(user)) {
      addDisinvitee(user);
    } else {
      deleteDisinvitee(user);
    }
    deleteParticipant(user);
    deleteInvitee(user);
  }
}