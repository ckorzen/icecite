@MirrorsUsed(targets: 'LibraryEntry')
library library_entry_element;

import 'dart:html';
import 'dart:async';
import 'dart:mirrors';
import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../models/models.dart';
import '../utils/observable_map.dart';

/// An entry of the library.
@CustomTag('library-entry-element')
class LibraryEntryElement extends IceciteElement {    
  // Observable properties.
  @published LibraryEntry entry;
  @published String cssStyle;
  @published bool draggable;
  @observable bool showUpdateTitleView = false;
  @observable bool showUpdateAuthorsView = false;
  @observable bool showUpdateVenueView = false;
  @observable bool showUpdateYearView = false;
  @observable bool showUsers = false;
  @observable bool showTopics = false;
  @observable Map<String, User> users = new ObservableMap();
  @observable List<LibraryEntry> topics = toObservable([]);
  // Internal properties.
  String prevTitle;
  String prevAuthors;
  String prevVenue;
  String prevYear;
  Timer clickTimer;
  var clickStatus = 1;
  // The tooltip on dragging.
  HtmlElement dragTooltip = new DivElement()
    ..classes.add("drag-tooltip")
    ..innerHtml = "Assign entry to a topic or share it with a user."
    ..style.display = "none";
    
  /// The default constructor.
  LibraryEntryElement.created() : super.created();
       
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/library_entry_element.css"));
  }
  
  // Overrides.
  void resetOnLogout() {
    super.resetOnLogout();
    this.showUpdateTitleView = false;
    this.showUpdateAuthorsView = false;
    this.showUpdateVenueView = false;
    this.showUpdateYearView = false;
    this.showUsers = false;
    if (this.users != null) this.users.clear();
    this.showTopics = false;
    if (this.topics != null) this.topics.clear();
    this.prevTitle = null;
    this.prevAuthors = null;
    this.prevVenue = null;
    this.prevYear = null;
    this.clickTimer = null;
    this.clickStatus = 1;
  }
  
  // ___________________________________________________________________________
  // Handlers.
    
  /// This method is called whenever, a drag action was started for entry.
  void dragStartHandler(event, detail, target) => onDragStarted(event);
  
  /// This method is called, whenever an entry is dragged.
  void dragHandler(event, detail, target) => onDragged(event);
            
  /// This method is called, whenever a dragged entry isn't dragged anymore.
  void dragEndHandler(event, detail, target) => onDragEnded(event);
        
  // ___________________________________________________________________________
  // On-purpose methods.
    
  /// This method is called, whenever an entry is about to change.
  void onUpdatePurpose(event, detail, target) => update();
 
  /// This method is called on a cancel edit entry purpose.
  void onCancelUpdatePurpose(event, detail, target) => cancelUpdate(event); 
    
  /// This method is called on every delete entry purpose.
  void onDeletePurpose(event, detail, target) => delete();
  
  /// This method is called on every select entry purpose.
  void onSelectPurpose(event, detail, target) => select();
  
  /// Define the behavior on double clicking the entry.
  void onDisplayUpdateViewPurpose(e, d, t) => displayUpdateView(t.dataset);
   
  /// This method is called, whenever a topic should be rejected from entry.
  void onRejectTopicPurpose(e, d, t) => rejectTopic(e, t.dataset['topic']);
      
  /// Will display the share details.
  void onDisplayTopicsPurpose(event, details, target) => displayTopics();
  
  /// Will cancel the subscription for given user.
  void onRejectUserPurpose(event, user, target) => rejectUser(user);
  
  /// Will display the details about shares.
  void onDisplayUsersPurpose(event, details, target) => displayUsers();
  
  // ___________________________________________________________________________
  // Actions.
  
  /// This method is called whenever, a drag action was started for entry.
  void onDragStarted(var event) {
    // Add class name to entry while dragging.
    get("library-entry").classes.add("dragging");
    // Fill the dataTransfer-object.
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('Text', entry.id); 
    // Add drag tooltip to body.
    document.body.children.add(dragTooltip);
  }
  
  /// This method is called, whenever the entry is dragged.
  void onDragged(var event) {    
    dragTooltip.style.display = "inline-block";
    dragTooltip.style.left = "${event.client.x + 10}px";
    dragTooltip.style.top = "${event.client.y}px";
  }
   
  /// This method is called whenever, a drag action ended for entry.
  void onDragEnded(var event) {
    // Remove class name from entry after dragging.
    get("library-entry").classes.remove("dragging");
    // Remove the drag tooltip.
    dragTooltip.remove();
  }
  
  // ___________________________________________________________________________
  
  /// Edits the entry.
  void update() {
    // Fire update event, if title was changed.
    if (entry.title != prevTitle ||
       entry.authorsStr != prevAuthors ||
       entry.journal != prevVenue ||
       entry.year != prevYear) {
     fire('edit-entry', detail: entry); 
    }
    hideUpdateView(false);
  }
   
  /// Cancels the edit process of entry.
  void cancelUpdate(Event event) {
    event.stopPropagation();
    event.preventDefault();
    hideUpdateView(true); 
  }

  /// Deletes the entry.
  void delete() {
    fire('delete-entry', detail: entry);
  }
  
  /// Selects the entry
  void select() {
    hideUpdateView(true);
    // On double click, also the click event is fired. So distinguish by hand,
    // if a click belongs to a single click or a double click.
    clickStatus = 1;
    clickTimer = new Timer(new Duration(milliseconds: 300), () {
      if (clickStatus == 1) {
        fire('select-entry', detail: entry);
      }
    });
  }
  
  /// Rejects the given topic from entry.
  void rejectTopic(Event event, String topicId) {
    event.preventDefault;
    event.stopPropagation;
    fire("reject-topic", detail: {'entryId': entry.id, 'topicId': topicId});
  }
  
  /// Displays the share details for the topic element.
  void displayUsers() {
    if (showUsers) users.clear();
    else users.addAll(actions.getUsers(entry.userIds));
    showUsers = !showUsers;
  }
  
  /// Rejects the given user from entry.
  void rejectUser(User user) {
    fire("unshare-entry", detail: {'entry': entry, 'user': user});
  }
  
  /// Displays the topic details.
  void displayTopics() {
    if (showTopics) {
      topics.clear();
    } else {
      // Send an empty list if topicIds == null to avoid to fetch all topics.
      Iterable topicIds = entry.topicIds != null ? entry.topicIds : [];
      topics.addAll(actions.getTopics(topicIds));
    }
    showTopics = !showTopics;
  }
   
  // ___________________________________________________________________________
  // Display methods 
  
  void displayUpdateView(Map dataset) {
    clickTimer.cancel();
    clickStatus = 0;
      
    switch (dataset['type']) {
      case ("title"):
        showUpdateTitleView = true;
        prevTitle = entry.title;
        break;
      case ("authors"):
        showUpdateAuthorsView = true;
        prevAuthors = entry.authorsStr;
        break;
      case ("venue"):
        showUpdateVenueView = true;
        prevVenue = entry.journal;
        break; 
      case ("year"):
        showUpdateYearView = true;
        prevYear = entry.year;
        break;   
    }
  }
  
  /// Hides the edit view.
  void hideUpdateView(bool resetToOriginValues) {
    showUpdateTitleView = false;
    showUpdateAuthorsView = false;
    showUpdateVenueView = false;
    showUpdateYearView = false;
    
    if (resetToOriginValues) {
      if (prevTitle != null) entry.title = prevAuthors;
      if (prevVenue != null) entry.journal = prevVenue;
      if (prevYear != null) entry.year = prevYear;
    }
  }
}