@MirrorsUsed(targets: 'Topic')
library topic_element;

import 'dart:html';
import "dart:mirrors";
import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../utils/observable_map.dart';
import '../models/models.dart';

/// An topic.
@CustomTag('topic-element')
class TopicElement extends IceciteElement {
  /// The topic.
  @published LibraryEntry topic;
  /// Boolean indicating, whether the topic is draggable.
  @published bool draggable;
  /// Boolean indicating, whether the update form is displayed.
  @observable bool showUpdateForm = false;
  /// Boolean indicating, whether the participant-details are displayed.
  @observable bool showParticipants = false;
  /// Boolean indicating, whether the invitees-details are displayed.
  @observable bool showInvitees = false;
  /// Boolean indicating, whether the disinvitees-details are displayed.
  @observable bool showDisinvitees = false;
  /// Boolean indicating whether the blur mask is shown.
  @observable bool showBlurMask = false;
  /// The resolved participants of this topic.
  @observable Map<String, User> participants = new ObservableMap();
  /// The resolved invitees of this topic.
  @observable Map<String, User> invitees = new ObservableMap();
  /// The resolved disinvitees of this topic.
  @observable Map<String, User> disinvitees = new ObservableMap();
  /// The resolved owner of this topic.
  @observable User owner;
  
  /// The cached original title.
  String prevTitle;
  /// The element wrapping the topic.
  HtmlElement topicElement;
  /// The element wrapping the dropMask.
  HtmlElement dropMaskElement;
  /// The tooltip on dragging.
  HtmlElement dragTooltip = new DivElement()
    ..classes.add("drag-tooltip")
    ..innerHtml = "Assign entry to a topic or share it with a user."
    ..style.display = "none";
    
  /// The name of topic-selected event.
  static const String EVENT_TOPIC_SELECTED = "topic-selected";
  /// The name of topic-unselected event.
  static const String EVENT_TOPIC_UNSELECTED = "topic-unselected";
  /// The name of topic-updated event.
  static const String EVENT_TOPIC_UPDATED = "topic-updated";
  /// The name of topic-deleted event.
  static const String EVENT_TOPIC_DELETED = "topic-deleted";
  /// The name of participant-disinvited event.
  static const String EVENT_PARTICIPANT_DISINVITED = "participant-disinvited";
  /// The name of invitee-disinvited event.
  static const String EVENT_INVITEE_DISINVITED = "invitee-disinvited";
  /// The name of entry-assigned event.
  static const String EVENT_ENTRY_ASSIGNED = "entry-assigned";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  TopicElement.created() : super.created();
     
  @override
  void attached() {
    super.attached();      
    this.topicElement = get("topic");
    this.dropMaskElement = get("topic-dropmask");
    // Resolve the owner of this topic.
    this.owner = actions.getUser(topic.owner);
    if (topic.title == null || topic.title.isEmpty) 
      displayUpdateForm();
  }
  
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    this.showUpdateForm = false;
    this.showParticipants = false;
    this.showInvitees = false;
    this.showDisinvitees = false;
    if (this.participants != null) participants.clear();
    if (this.invitees != null) invitees.clear();
    if (this.disinvitees != null) disinvitees.clear();
    this.prevTitle = null;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever a drag of a topic has started.
  void onDragStarted(event) => handleDragStarted(event);
   
  /// This method is called, whenever an entry is dragged.
  void onDragged(event) => handleDragged(event);
    
  /// This method is called, whenever a dragged element enters the topic.
  void onDragEntered(event) => handleDragEntered(event);
      
  /// This method is called, whenever an element is dragged over the topic.
  void onDraggedOver(event) => handleDraggedOver(event);
  
  /// This method is called, whenever a dragged element leaves the topic.
  void onDragLeaved(event) => handleDragLeaved(event);
       
  /// This method is called, whenever a drag ends (outside of the topic).
  void onDragEnded(event) => handleDragEnded(event);
   
  /// This method is called, whenever an element was dropped on the topic.
  void onDropped(event) => handleDropped(event); 
  
  /// This method is called, whenever the checkbox was clicked.
  void onCheckBoxClicked(event, detail, target) => 
      handleCheckboxClicked(event, target);
    
  /// This method is called, whenever the title was double-clicked.
  void onTitleDoubleClicked(event) => handleTitleDoubleClicked(event);
  
  /// This method is called, whenever a title was committed.
  void onTitleCommitted(event) => handleTitleCommitted(event);
  
  /// This method is called, whenever the checkbox was cancelled.
  void onTitleCommitCancelled(event) => handleTitleCommitCancelled(event);
  
  /// This method is called, whenever the deleteButton was clicked.
  void onDeleteButtonClicked(event) => handleDeleteButtonClicked(event);
  
  /// This method is called, whenever the participant info was clicked.
  void onParticipantsInfoClicked(event) => handleParticipantsInfoClicked(event);
  
  /// This method is called, whenever the invitees info was clicked.
  void onInviteesInfoClicked(event) => handleInviteesInfoClicked(event);
  
  /// This method is called, whenever the disinvitees info was clicked.
  void onDisinviteesInfoClicked(event) => handleDisinviteesInfoClicked(event);
  
  /// This method is called, whenever a participant was rejected.
  void onParticipantDisinvited(event, user) => 
      handleParticipantDisinvited(event, user);
  
  /// This method is called, whenever a invitee was rejected.
  void onInviteeDisinvited(event, user) => handleInviteeDisinvited(event, user);
  
  /// This method is called, whenever the blur mask was clicked.
  void onBlurMaskClicked(event) => handleBlurMaskClicked(event);
  
  // ___________________________________________________________________________
  // Private actions.

  /// Handles a drag over event.
  void handleDraggedOver(MouseEvent event) {
    retardEvent(event);
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
  }
  
  /// Handles a drag leaved event.
  void handleDragLeaved(MouseEvent event) {
    retardEvent(event);
    topicElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Change the inner html of drag tooltip.
    var tooltip = document.body.querySelector(".drag-tooltip");
    if (tooltip != null) {
      tooltip.innerHtml = "Assign entry to a topic or share it with a user.";
    }
  }
  
  /// Handles a drag enter event.
  void handleDragEntered(var event) {
    retardEvent(event);
    topicElement.classes.add('over');
    dropMaskElement.style.display = "block";
    // Change the inner html of drag tooltip.
    var tip = document.body.querySelector(".drag-tooltip");
    if (tip != null) tip.innerHtml = "Assign entry to topic '${topic.title}'";
  }
    
  /// Handles a drag end event.
  void handleDragEnded(var event) {
    retardEvent(event);
    topicElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Remove class name from entry after dragging.
    get("topic").classes.remove("dragging");
    // Remove the drag tooltip.
    dragTooltip.remove();
  }
  
  /// Handles a drag start event.
  void handleDragStarted(var event) {
    // Add class name to entry while dragging.
    get("topic").classes.add("dragging");
    // Fill the dataTransfer-object.
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('Text', topic.id);
    // Add drag tooltip to body.
    document.body.children.add(dragTooltip);
  }
  
  /// Handles a drag event.
  void handleDragged(var event) {
    dragTooltip.style.top = "${event.client.y}px";
    dragTooltip.style.left = "${event.client.x + 10}px";
    dragTooltip.style.display = "inline-block";
  }
          
  /// Handles a drop over event.
  void handleDropped(var event) {
    topicElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Remove class name from entry after dragging.
    get("topic").classes.remove("dragging");
    // Remove the drag tooltip.
    dragTooltip.remove();
    String entryId = event.dataTransfer.getData('Text');
    if (entryId != null) fireLibraryEntryAssignedEvent(entryId);
  }
    
  /// Handles a double click on the title.
  void handleTitleDoubleClicked(Event event) {
    retardEvent(event);
    if (user != owner) return;
    // Display the update form.
    displayUpdateForm(cacheOriginValues: true);
  }
  
  /// Selects the topic, if the checkbox is checked and unselects it otherwise.
  void handleCheckboxClicked(Event event, InputElement target) {
    topic.selected = target.checked;
    if (topic.selected) {
      fireTopicSelectedEvent();
    } else {
      fireTopicUnselectedEvent();
    }
  }
    
  /// Handles a commit of a new title
  void handleTitleCommitted(Event event) {
    retardEvent(event);
    hideUpdateForm(resetToOriginValues: false);
    fireTopicUpdatedEvent();
  }
  
  /// Handles a cancellation of title update.
  void handleTitleCommitCancelled(Event event) {
    retardEvent(event);
    // Hide the update form.
    hideUpdateForm(resetToOriginValues: true);
  }
  
  /// Fires a "delete-topic" event.
  void handleDeleteButtonClicked(Event event) {
    retardEvent(event);
    fireTopicDeletedEvent();
  }
    
  /// Handles a click on participants info.
  void handleParticipantsInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the participants.
    Map participants = resolveParticipants();
    displayParticipantDetails(participants);
  }
     
  /// Handles a click on invitees info.
  void handleInviteesInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the invitees.
    Map invitees = resolveInvitees();
    displayInviteesDetails(invitees);
  }
  
  /// Handles a click on disinvitees info.
  void handleDisinviteesInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the disinvitees.
    Map disinvitees = resolveDisinvitees();
    displayDisinviteesDetails(invitees);
  }
  
  /// Fires an "participant-disinvited" event.
  void handleParticipantDisinvited(Event event, User participant) {
    retardEvent(event);
    fireParticipantDisinvitedEvent(participant);
  }
  
  /// Fires an "invitees-disinvited" event.
  void handleInviteeDisinvited(Event event, User invitee) {
    retardEvent(event);
    fireInviteeDisinvitedEvent(invitee);
  }
  
  /// Handles a click on blur mask.
  void handleBlurMaskClicked(Event event) {
    retardEvent(event);
    // Hide the participant details.
    hideParticipantDetails();
    // Hide the invitees details.
    hideInviteesDetails();
    // Hide the disinvitees details.
    hideDisinviteesDetails();
  }
  
  // ___________________________________________________________________________
  
  /// Displays the update form.
  void displayUpdateForm({bool cacheOriginValues: true}) {
    if (cacheOriginValues) prevTitle = topic.title;
    showUpdateForm = true;
  }
  
  /// Hides the update form.
  void hideUpdateForm({bool resetToOriginValues}) {
    if (resetToOriginValues) {
      if (prevTitle != null) topic.title = prevTitle;
    }
    showUpdateForm = false;
  }
  
  /// Displays the participant details.
  void displayParticipantDetails(Map participants) {
    this.participants.addAll(participants);
    showParticipants = true;
    showBlurMask = true;
  }
   
  /// Displays the participant details.
  void hideParticipantDetails() {
    if (this.participants != null) this.participants.clear();
    showParticipants = false;
    showBlurMask = false;
  }
  
  /// Displays the invitees details.
  void displayInviteesDetails(Map invitees) {
    this.invitees.addAll(invitees);
    showInvitees = true;
    showBlurMask = true;
  }
   
  /// Displays the invitees details.
  void hideInviteesDetails() {
    if (this.invitees != null) this.invitees.clear();
    showInvitees = false;
    showBlurMask = false;
  }
  
  /// Displays the disinvitees details.
  void displayDisinviteesDetails(Map disinvitees) {
    this.disinvitees.addAll(disinvitees);
    showDisinvitees = true;
    showBlurMask = true;
  }
   
  /// Displays the disinvitees details.
  void hideDisinviteesDetails() {
    if (this.disinvitees != null) this.disinvitees.clear();
    showDisinvitees = false;
    showBlurMask = false;
  }
    
  // ___________________________________________________________________________
  
  /// Fires a "entry-assigned" event.
  void fireLibraryEntryAssignedEvent(String entryId) {
    fire(EVENT_ENTRY_ASSIGNED, detail: {'topicId': topic.id, 'entryId': entryId});
  }
  
  /// Fires a "topic-selected" event.
  void fireTopicSelectedEvent() {
    fire(EVENT_TOPIC_SELECTED, detail: topic);
  }
  
  /// Fires a "topic-unselected" event.
  void fireTopicUnselectedEvent() {
    fire(EVENT_TOPIC_UNSELECTED, detail: topic);
  }
    
  /// Fires a "topic-updated" event.
  void fireTopicUpdatedEvent() {
    fire(EVENT_TOPIC_UPDATED, detail: topic);
  }
  
  /// Fires a "topic-deleted" event.
  void fireTopicDeletedEvent() {
    fire(EVENT_TOPIC_DELETED, detail: topic);
  }
  
  /// Fires a "participant-disinvited" event.
  void fireParticipantDisinvitedEvent(User participant) {
    fire(EVENT_PARTICIPANT_DISINVITED, detail: {'topic': topic, 'user': participant});
  }
  
  /// Fires a "invitee-disinvited" event.
  void fireInviteeDisinvitedEvent(User invitee) {
    fire(EVENT_INVITEE_DISINVITED, detail: {'topic': topic, 'user': invitee});
  }
  
  // ___________________________________________________________________________
  
  /// Resolves the participants of this topic.
  Map resolveParticipants() {
    return actions.getUsers(topic.participants);
  }
  
  /// Resolves the invitees of this topic.
  Map resolveInvitees() {
    return actions.getUsers(topic.invitees);
  }
  
  /// Resolves the disinvitees of this topic.
  Map resolveDisinvitees() {
    return actions.getUsers(topic.disinvitees);
  }
}