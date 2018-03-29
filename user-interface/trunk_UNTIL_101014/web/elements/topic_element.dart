@MirrorsUsed(targets: 'Topic')
library topic_element;

import 'dart:html';
import "dart:mirrors";
import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../utils/observable_map.dart';
import '../models/models.dart';

/// An entry of the library.
@CustomTag('topic-element')
class TopicElement extends IceciteElement {
  // Observable properties.
  @published LibraryEntry topic;
  @observable bool showUpdateView = false;
  @observable bool showUsers = false;
  @observable Map<String, User> users = new ObservableMap();
  
  // Internal properties.
  String prevTitle;
  HtmlElement topicElement;
  HtmlElement dropMaskElement;
  HtmlElement dragTooltip = new DivElement()
    ..classes.add("drag-tooltip")
    ..innerHtml = "Assign entry to a topic or share it with a user."
    ..style.display = "none";
    
  /// The default constructor.
  TopicElement.created() : super.created();
     
  /// This method is called, when the view is wired up.
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/topic_element.css"));
        
    if (topic.title == null || topic.title.isEmpty) displayUpdateView();
    this.topicElement = get("topic");
    this.dropMaskElement = get("topic-dropmask");
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    this.showUpdateView = false;
    this.showUsers = false;
    if (this.users != null) users.clear();
    this.prevTitle = null;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever a topic is dragged.
  void dragStartHandler(event, detail, target) => onDragStarted(event);
   
  /// This method is called, whenever an entry is dragged.
  void dragHandler(event, detail, target) => onDragged(event);
    
  /// This method is called, whenever a dragged element enters the topic.
  void dragEnterHandler(event, details, target) => onDragEntered(event);
      
  /// This method is called, whenever an element is dragged over the topic.
  void dragOverHandler(event, details, target) => onDraggedOver(event);
  
  /// This method is called, whenever a dragged element leaves the topic.
  void dragLeaveHandler(event, details, target) => onDragLeaved(event);
       
  /// This method is called, whenever a drag ends (outside of the topic).
  void dragEndHandler(event, details, target) => onDragEnded(event);
   
  /// This method is called, whenever an element was dropped on the topic.
  void dropHandler(event, details, target) {
    onDropped(event); 
  }
  
  /// This method is called, whenever the checkbox was clicked.
  void checkBoxClickedHandler(e, d, t) => onCheckboxClicked(t.checked);
  
  // ___________________________________________________________________________
  // On-purpose methods.
    
  /// Will enter into edit view.
  void onDisplayUpdateViewPurpose(event, detail, target) => displayUpdateView();
  
  /// Will edit a topic.
  void onUpdatePurpose(event, details, target) => update();
  
  /// Will cancel the edit of a topic.
  void onCancelUpdatePurpose(event, details, target) => cancelUpdate();
  
  /// Will delete a topic.
  void onDeletePurpose(event, details, target) => delete();
  
  /// Will display the share details.
  void onDisplayUsersPurpose(event, details, target) => displayUsers();
  
  /// Will cancel the subscription for given user.
  void onRejectUserPurpose(event, user, target) => rejectUser(user);
  
  // ___________________________________________________________________________
  // Handler methods.

  /// This method is called, whenever an element is dragged over the topic.
  void onDraggedOver(var event) {
    event.stopPropagation();
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
  }
  
  /// This method is called, whenever a dragged element leaves the topic.
  void onDragLeaved(var event) {
    event.stopPropagation();
    event.preventDefault();
    topicElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Change the inner html of drag tooltip.
    var tooltip = document.body.querySelector(".drag-tooltip");
    if (tooltip != null) {
      tooltip.innerHtml = "Assign entry to a topic or share it with a user.";
    }
  }
  
  /// This method is called, whenever a dragged element enters the topic.
  void onDragEntered(var event) {
    event.stopPropagation();
    event.preventDefault();
    topicElement.classes.add('over');
    dropMaskElement.style.display = "block";
    // Change the inner html of drag tooltip.
    var tip = document.body.querySelector(".drag-tooltip");
    if (tip != null) tip.innerHtml = "Assign entry to topic '${topic.title}'";
  }
    
  /// This method is called whenever, a drag action ended for entry.
  void onDragEnded(var event) {
    event.stopPropagation();
    event.preventDefault();
    topicElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Remove class name from entry after dragging.
    get("topic").classes.remove("dragging");
    // Remove the drag tooltip.
    dragTooltip.remove();
  }
  
  /// This method is called whenever, a drag action was started for topic.
  void onDragStarted(var event) {
    // Add class name to entry while dragging.
    get("topic").classes.add("dragging");
    // Fill the dataTransfer-object.
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('Text', topic.id);
    // Add drag tooltip to body.
    document.body.children.add(dragTooltip);
  }
  
  /// This method is called, whenever a topic is dragged.
  void onDragged(var event) {
    dragTooltip.style.top = "${event.client.y}px";
    dragTooltip.style.left = "${event.client.x + 10}px";
    dragTooltip.style.display = "inline-block";
  }
          
  /// This method is called, whenever an element was dropped on the topic.
  void onDropped(var event) {
    topicElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Remove class name from entry after dragging.
    get("topic").classes.remove("dragging");
    // Remove the drag tooltip.
    dragTooltip.remove();
    String id = event.dataTransfer.getData('Text');
    if (id != null && topic != null && topic.id != null) {
      fire("topic-assignment", detail: {'topicId': topic.id, 'entryId': id});
    }
  }
  
  /// This method is called, whenever the checkbox was clicked.
  void onCheckboxClicked(bool checked) {
    if (checked) {
      topicElement.classes.add("selected");
      fire("topic-selected", detail: topic);
    } else {
      topicElement.classes.remove("selected");
      fire("topic-unselected", detail: topic);
    }
  }
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Edits the topic.
  void update() {
    fire("edit-topic", detail: topic);
    hideUpdateView();
  }

  /// Cancels the edit of topic.
  void cancelUpdate() {
    topic.title = prevTitle;
    hideUpdateView();
  }
  
  /// Deletes the topic.
  void delete() {
    fire("delete-topic", detail: topic);
  }
  
  /// Displays the share details for the topic element.
  void displayUsers() {
    if (showUsers) users.clear();
    else users.addAll(actions.getUsers(topic.userIds));
    showUsers = !showUsers;
  }
    
  /// Unshares.
  void rejectUser(User user) {
    fire("unshare-topic", detail: {'topic': topic, 'user': user});
  }
  
  // ___________________________________________________________________________
  // Display methods.
  
  /// Enters into edit view.
  void displayUpdateView() {
    showUpdateView = true;
    prevTitle = topic.title;
  }
  
  /// Exits from edit view.
  void hideUpdateView() {
    showUpdateView = false;
  }
}