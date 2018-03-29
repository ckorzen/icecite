part of models;

/// A pdf annotation.
class PdfAnnotation extends Pouchable {
  /// Creates a new annot.
  PdfAnnotation() : super() {
    this.brand = "annot";
  }
  
  /// Creates a pouchable from map.
  PdfAnnotation.fromMap(Map map) : super.fromMap(map);
  
  // ___________________________________________________________________________
  // Setters.
    
  /// Sets the entryId.
  set entryId(value) => this["entryId"] = value;
    
  /// Sets the ref type.
  set type(value) => this['type'] = value;
  
  /// Sets the creation date.
  set created(value) => this['creationDate'] = value;
    
  /// Sets the modify date.
  set modified(value) => this['modDate'] = value;
  
  /// Sets the page.
  set page(value) => this['page'] = value;
    
  /// Sets the author.
  set author(value) => this['author'] = value;
  
  /// Sets the subject.
  set subject(value) => this['subject'] = value;
  
  /// Sets the contents.
  set contents(value) => this['contents'] = value;
  
  /// Sets the stroke color.
  set strokeColor(value) => this['strokeColor'] = value;
  
  /// Sets the opacity.
  set opacity(value) => this['opacity'] = value;
  
  /// Sets the in reply to.
  set inReplyTo(value) => this['inReplyTo'] = value;
  
  /// Sets the ref type.
  set refType(value) => this['refType'] = value;
  
  /// Sets the rect.
  set rect(value) => this['rect'] = value;
  
  /// Sets the popupRect.
  set popupRect(value) => this['popupRect'] = value;
  
  /// Sets the popupOpen.
  set popupOpen(value) => this['popupOpen'] = value;
  
  /// Sets the point.
  set point(value) => this['point'] = value;
  
  /// Sets the quads.
  set quads(value) => this['quads'] = value;
  
  /// Sets the noteIcon.
  set noteIcon(value) => this['noteIcon'] = value;
  
  // ___________________________________________________________________________
  // Getters.
    
  /// Returns the entryId.
  get entryId => this["entryId"];
  
  /// Returns the type.
  get type => this['type'];
  
  /// Returns the creation date.
  get created => this['creationDate'];
  
  /// Returns the modify date.
  get modified => this['modDate'];
  
  /// Returns the page.
  get page => this['page'];
    
  /// Returns the author.
  get author => this['author'];
  
  /// Returns the subject.
  get subject => this['subject'];
  
  /// Returns the contents.
  get contents => this['contents'];
  
  /// Returns the stroke color.
  get strokeColor => this['strokeColor'];
  
  /// Returns the opacity.
  get opacity => this['opacity'];
  
  /// Returns the in reply to.
  get inReplyTo => this['inReplyTo'];
  
  /// Returns the ref type.
  get refType => this['refType'];
  
  /// Returns the rect.
  get rect => this['rect'];
  
  /// Returns the popupRect.
  get popupRect => this['popupRect'];
  
  /// Returns the popupOpen.
  get popupOpen => this['popupOpen'];
  
  /// Returns the point.
  get point => this['point'];
  
  /// Returns the quads.
  get quads => this['quads'];
  
  /// Returns the note icon.
  get noteIcon => this['noteIcon'];
  
  // ___________________________________________________________________________
  
  /// Returns the annot as string.
  String toString() => 
      "${id}\t${type}\t${page}\t${created}\t${modified}\t${author}\t"
      "${subject}\t${contents}\t${strokeColor}\t${opacity}\t${inReplyTo}\t"
      "${refType}\t${rect}\t${popupRect}\t${popupOpen}\t"
      "${point != null && point.isNotEmpty ? point : quads}\t${noteIcon}";
}