part of models;

/// An entry of the library.
class LibraryEntry extends Pouchable {    
  /// The constructor.
  LibraryEntry(String brand, String title, User user) : super() {
    this.title = title;
    this.brand = brand;
    List users = userIds != null ? userIds : [];
    userIds = users..add(user.id);
  }
  
  /// Creates a pouchable from map.
  LibraryEntry.fromMap(Map map) : super.fromMap(map);
  
  /// Clones the given entry without id and rev.
  LibraryEntry.twin(LibraryEntry other, String brand) : super.clone(other) {
    this.id = null;
    this.rev = null;
    this.brand = brand;
  }
   
  // ___________________________________________________________________________
  // Setters.
  
  /// Sets the title.
  set title(value) => this['title'] = value;
  
  /// Sets the attachments.
  set attachments(value) => this['_attachments'] = stringify(value);
    
  /// Sets the external key.
  set externalKey(value) => this['externalKey'] = value;
  
  /// Sets the journal.
  set journal(value) => this['journal'] = value;
  
  /// Sets the year.
  set year(value) => this['year'] = value;
  
  /// Sets the url.
  set url(value) => this['url'] = value;
  
  /// Sets the ee.
  set ee(value) => this['ee'] = value;
  
  /// Sets the raw.
  set raw(value) => this['raw'] = value;
  
  /// Sets the id of citing entry.
  set citingEntryId(value) => this['citingEntryId'] = value;
  
  /// Sets the position of bibliography.
  set positionInBibliography(value) => this['positionInBibliography'] = value;  
  
  /// Sets the authors.
  set authors(value) => this['authors'] = value;  
  
  /// Sets the authors string.
  set authorsStr(String authorsStr) {
    if (authorsStr != null) {
      List authors = [];
      List<String> splitted = authorsStr.split(new RegExp("[,;]"));
      splitted.forEach((split) => authors.add(split.trim()));
      this['authors'] = authors;
    } else {
      map.remove('authors');
    }
  }
  
  /// Sets the topicId.
  set topicIds(value) => this['assignmentIds'] = value; 
  
  /// Sets the userIds.
  set userIds(value) => this['userIds'] = value; 
  
  /// Sets the former userIds.
  set formerUserIds(value) => this['formerUserIds'] = value;
    
  // ___________________________________________________________________________
  // Getters.
  
  /// Returns the attachments.
  get attachments => this['_attachments'];
  
  /// Returns the title.
  get title => this['title'];
  
  /// Returns the authors.
  get authors => this['authors'];
  
  /// Returns the authors as string.
  get authorsStr {
    if (authors != null && authors.length > 0) {
      var sb = new StringBuffer();
      for (int i = 0; i < authors.length; i++) {
        String author = authors[i];
        sb.write(author);
        if (i < authors.length - 1) sb.write(", ");
      }
      return sb.toString();
    }
  }
  
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
  
  /// Returns the id of citing entry id.
  get citingEntryId => this['citingEntryId'];
  
  /// Returns the position in bibliography.
  get positionInBibliography => this['positionInBibliography'];
  
  /// Returns the properties.
  get properties => map.keys; 
  
  /// Returns the topicId.
  get topicIds => this['assignmentIds']; 
           
  /// Returns the userIds.
  get userIds => this['userIds'];
  
  /// Returns the former userIds.
  get formerUserIds => this['formerUserIds'];
  
  // ___________________________________________________________________________ 
  // Helpers. 
  
  /// Returns true, if this library entry is a reference.
  bool isReference() => citingEntryId != null;
  
  /// Returns true, if this library entry is a member of library.
  bool isMemberOfLibrary() => attachments != null;
}