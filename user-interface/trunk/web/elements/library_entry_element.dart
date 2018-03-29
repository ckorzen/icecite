@MirrorsUsed(targets: 'LibraryEntry')
library library_entry_element;

import 'dart:html' hide Location, Notification, MenuElement;
import 'dart:async';
import 'dart:mirrors';
import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../properties.dart';
import '../models/models.dart';
import '../utils/observable_map.dart';
import '../utils/html/location_util.dart';

/// An entry of the library.
@CustomTag('library-entry-element')
class LibraryEntryElement extends IceciteElement {    
  /// The library entry
  @published LibraryEntry entry;
  /// The injected css style.
  @published String cssStyle;
  /// Boolean, indicating whether the library entry is draggable.
  @published bool draggable;
  /// Boolean, indicating whether the library entry is modifiable.
  @published bool modifiable;
  /// The users.
  @published Map<String, User> users;
  /// Boolean, indicating whether the topics of library entry are rejectable.
  @published bool topicsRejectable;
  /// Boolean, indicating whether the title update form is displayed.
  @observable bool showTitleUpdateForm = false;
  /// Boolean, indicating whether the authors update form is displayed.
  @observable bool showAuthorsUpdateForm = false;
  /// Boolean, indicating whether the venue update form is displayed.
  @observable bool showVenueUpdateForm = false;
  /// Boolean, indicating whether the year update form is displayed.
  @observable bool showYearUpdateForm = false;
  /// Boolean, indicating whether the participants-details are displayed.
  @observable bool showParticipants = false;
  /// Boolean, indicating whether the invitees-details are displayed.
  @observable bool showInvitees = false;
  /// Boolean, indicating whether the disinvitees-details are displayed.
  @observable bool showDisinvitees = false;
  /// Boolean, indicating whether the topic-details are displayed.
  @observable bool showTopics = false;
  /// Boolean indicating whether the blur mask is shown.
  @observable bool showBlurMask = false;
  /// Boolean indicating whether the actions menu is shown.
  @observable bool showActionsMenu = false;
  /// The index of tag, for which the update form is shown.
  @observable int showUpdateTagFormIndex;
  /// The index of tag, for which the tag menu is shown.
  @observable int showTagMenuIndex;
  /// The resolved topics.
  @observable Map<String, LibraryEntry> topics = new ObservableMap();
  /// The resolved participants.
  @observable Map<String, User> participants = new ObservableMap();
  /// The resolved invitees.
  @observable Map<String, User> invitees = new ObservableMap();
  /// The resolved disinvitees.
  @observable Map<String, User> disinvitees = new ObservableMap();
  /// The resolved owner of this entry.
  @observable User owner;
  /// Boolean indicationg whether the verbose mode is turned on or off.
  @observable bool verbose = VERBOSE_MODE; 
  /// The typed tag in add-tag-form.
  @observable String newTagValue; 
  /// The tag in update-tag-form.
  @observable String updateTagValue;
  
  /// The cached original title.
  String prevTitle;
  ///  The cached original authors.
  String prevAuthors;
  /// The cached original venue.
  String prevVenue;
  /// The cached original year.
  String prevYear;
  /// The click timer to decide, if a click belongs to a double click.
  Timer clickTimer;
  /// The click status to decide, if a click belongs to a double click.
  var clickStatus = 1;
  /// The tooltip on dragging.
  HtmlElement dragTooltip = new DivElement()
    ..classes.add("drag-tooltip")
    ..innerHtml = "Assign entry to a topic or share it with a user."
    ..style.display = "none";
  
  /// The name of entry-selected event.
  static const String EVENT_ENTRY_SELECTED = "entry-selected";
  /// The name of entry-updated event.
  static const String EVENT_ENTRY_UPDATED = "entry-updated";
//  /// The name of entry-deleted event.
//  static const String EVENT_ENTRY_DELETED = "entry-deleted";
  /// The name of participant-disinvited event.
  static const String EVENT_PARTICIPANT_DISINVITED = "participant-disinvited";
  /// The name of invitee-disinvited event.
  static const String EVENT_INVITEE_DISINVITED = "invitee-disinvited";
  /// The name of topic-rejected event.
  static const String EVENT_TOPIC_REJECTED = "topic-rejected";
  /// The name of tag-updated event.
  static const String EVENT_TAG_UPDATED = "tag-updated";
  /// The name of tag-deleted event.
  static const String EVENT_TAG_DELETED = "tag-deleted";
//  /// The name of user-invited event.
//  static const String EVENT_USER_INVITED = "user-invited";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  LibraryEntryElement.created() : super.created();
         
  @override
  void attached() {
    super.attached();
    // Resolve the owner of this library entry.
    this.owner = resolveOwner();
    this.users = getUsers();
  }
    
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    this.showTitleUpdateForm = false;
    this.showAuthorsUpdateForm = false;
    this.showVenueUpdateForm = false;
    this.showYearUpdateForm = false;
    this.showParticipants = false;
    this.showInvitees = false;
    this.showDisinvitees = false;
    if (this.participants != null) this.participants.clear();
    if (this.invitees != null) this.invitees.clear();
    if (this.disinvitees != null) this.disinvitees.clear();
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
    
  /// This method is called, whenever a drag action was started for entry.
  void onDragStarted(event) => handleDragStarted(event);
  
  /// This method is called, whenever an entry is dragged.
  void onDragged(event) => handleDragged(event);
  
  /// This method is called, whenever a dragged entry isn't dragged anymore.
  void onDragEnded(event) => handleDragEnded(event);
       
  /// This method is called whenever the activity counter was clicked.
  void onActivityCounterClicked(event) => handleActivityCounterClicked(event);
  
  /// This method is called whenever an entry was clicked.
  void onLibraryEntryClicked(event) => handleLibraryEntryClicked(event);
  
  /// This method is called, whenever the title was double clicked.
  void onTitleDoubleClicked(event) => handleTitleDoubleClicked(event);
  
  /// This method is called, whenever a new title was committed.
  void onTitleCommitted(event) => handleTitleCommitted(event);
 
  /// This method is called, whenever the commit of a new title was cancelled.
  void onTitleCommitCancelled(event) => handleTitleCommitCancelled(event); 
    
  /// This method is called, whenever the authors were double clicked.
  void onAuthorsDoubleClicked(event) => handleAuthorsDoubleClicked(event);
  
  /// This method is called, whenever new authors were committed.
  void onAuthorsCommitted(event) => handleAuthorsCommitted(event);

  /// This method is called, whenever the commit of new authors were cancelled.
  void onAuthorsCommitCancelled(event) => handleAuthorsCommitCancelled(event);

  /// This method is called, whenever the venue was double clicked.
  void onVenueDoubleClicked(event) => handleVenueDoubleClicked(event);
  
  /// This method is called, whenever a new venue was committed.
  void onVenueCommitted(event) => handleVenueCommitted(event);
  
  /// This method is called, whenever the commit of new vanue was cancelled.
  void onVenueCommitCancelled(event) => handleVenueCommitCancelled(event);

  /// This method is called, whenever the year was double clicked.
  void onYearDoubleClicked(event) => handleYearDoubleClicked(event);
  
  /// This method is called, whenever a new year was committed.
  void onYearCommitted(event) => handleYearCommitted(event);
  
  /// This method is called, whenever the commit of new year was cancelled.
  void onYearCommitCancelled(event) => handleYearCommitCancelled(event);
       
  /// This method is called, whenever the topics-info was clicked.
  void onTopicsInfoClicked(event) => handleTopicsInfoClicked(event);
    
  /// This method is called, whenever the reject-topic-button was clicked.
  void onRejectTopicButtonClicked(event, detail, target) => 
      handleRejectTopicButtonClicked(event, target);
      
  /// This method is called, whenever the participants-info was clicked.
  void onParticipantsInfoClicked(event) => handleParticipantsInfoClicked(event);
  
  /// This method is called, whenever the disinvite-button in participant 
  /// details was clicked.
  void onParticipantDisinvited(event, user) => 
      handleParticipantDisinvited(event, user);
  
  /// This method is called, whenever the invitees-info was clicked.
  void onInviteesInfoClicked(event) => handleInviteesInfoClicked(event);
  
  /// This method is called, whenever the disinvite-button in invitees details
  /// was clicked.
  void onInviteeDisinvited(event, user) => handleInviteeDisinvited(event, user);
   
  /// This method is called, whenever the disinvitees-info was clicked.
  void onDisinviteesInfoClicked(event) => handleDisinviteesInfoClicked(event);
  
//  /// This method is called, whenever the delete button was clicked.
//  void onDeleteButtonClicked(event) => handleDeleteButtonClicked(event);
  
  /// This method is called, whenever the blur mask was clicked.
  void onBlurMaskClicked(event) => handleBlurMaskClicked(event);
  
  /// THis method is called, whenever the actions button was clicked.
  void onActionsButtonClicked(event) => handleActionsButtonClicked(event);
  
//  /// This method is called, whenever a new tag was committed.
//  void onNewTagCommitted(event) => handleNewTagCommitted(event);
 
  /// This method is called, whenever a tag was double clicked.
  void onRenameTagButtonClicked(event, detail, target) => 
       handleRenameTagButtonClicked(event, target);
  
  /// This method is called, whenever delete tag button was clicked.
  void onDeleteTagButtonClicked(event, detail, target) => 
      handleDeleteTagButtonClicked(event, target);
  
  /// This method is called, whenever a tag was committed.
  void onTagCommitted(event, detail, target) => 
      handleTagCommitted(event, target);
  
  /// This method is called, whenever a commit of a tag was cancelled.
  void onTagCommitCancelled(event, detail, target) => 
      handleTagCommitCancelled(event, target);
    
//  /// THis method is called, whenever a user was selected for sharing.
//  void onShareUserSelected(event) => handleShareUserSelected(event);
  
  /// This method is called, whenever a menu button of a tag was clicked.
  void onTagMenuButtonClicked(event, detail, target) => 
      handleTagMenuButtonClicked(event, target);
  
//  /// This method is called, whenever the download button was clicked.
//  void onDownloadButtonClicked(event) => handleDownloadButtonClicked(event);
    
  // ___________________________________________________________________________
  // Actions.
    
  /// This method is called whenever, a drag action was started for entry.
  void handleDragStarted(MouseEvent event) {
    // Add class name to entry while dragging.
    get("library-entry").classes.add("dragging");
    // Fill the dataTransfer-object.
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('Text', entry.id); 
    // Add drag tooltip to body.
    document.body.children.add(dragTooltip);
  }
  
  /// This method is called, whenever the entry is dragged.
  void handleDragged(MouseEvent event) {    
    dragTooltip.style.display = "inline-block";
    dragTooltip.style.left = "${event.client.x + 10}px";
    dragTooltip.style.top = "${event.client.y}px";
  }
   
  /// This method is called whenever, a drag action ended for entry.
  void handleDragEnded(MouseEvent event) {
    // Remove class name from entry after dragging.
    get("library-entry").classes.remove("dragging");
    // Remove the drag tooltip.
    dragTooltip.remove();
  }
  
  /// Handles a click on activity counter.
  void handleActivityCounterClicked(Event event) {
    retardEvent(event);
    // TODO: Hide activity counter ?
    // TODO: Handle activity counter clicked.
    // Check for single click and fire entry-selected event.
    checkForSingleClick(() { 
      fireLibraryEntrySelectedEvent(location: Location.FEED);
    });
  }
  
  /// Handles a click on library entry.
  void handleLibraryEntryClicked(Event event) {
    retardEvent(event);
    // Check for single click and fire entry-selected event.
    checkForSingleClick(() { 
      fireLibraryEntrySelectedEvent(location: Location.LIBRARY);
    });
  }
  
  /// Handles a double click on the title.
  void handleTitleDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry.
    if (user == null) return;
    if (user.id != entry.owner) return;
    // Display the update form and cache the current values.
    displayTitleUpdateForm(cacheOriginValues: true);
  }
  
  /// Handles a commit of new title.
  void handleTitleCommitted(Event event) {
    retardEvent(event);
    // Do nothing, if the text wasn't changed.
    if (entry.title == prevTitle) return;
    // Hide the update form.
    hideTitleUpdateForm(resetToOriginValues: false);
    // Fire update event to inform parent elements.
    fireLibraryEntryUpdatedEvent();
  }
  
  /// Handles a cancellation of title update.
  void handleTitleCommitCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideTitleUpdateForm(resetToOriginValues: true);
  }
  
  /// Handles a double click on the authors.
  void handleAuthorsDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry. 
    if (user == null) return;
    if (user.id != entry.owner) return;
    // Display the update form and cache the current values.
    displayAuthorsUpdateForm(cacheOriginValues: true);
  }
  
  /// Handles a commit of new authors.
  void handleAuthorsCommitted(Event event) {
    retardEvent(event);
    // Do nothing, if the authors weren't changed.
    if (entry.authors == prevAuthors) return;
    // Hide the update form.
    hideAuthorsUpdateForm(resetToOriginValues: false);
    // Fire update event to inform parent elements.
    fireLibraryEntryUpdatedEvent();
  }
  
  /// Handles a cancellation of authors update.
  void handleAuthorsCommitCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideAuthorsUpdateForm(resetToOriginValues: true);
  }
  
  /// Handles a double click on the venue.
  void handleVenueDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry. 
    if (user == null) return;
    if (user.id != entry.owner) return;
    // Display the update form and cache the current values.
    displayVenueUpdateForm(cacheOriginValues: true);
  }
  
  /// Handles a commit of new venue.
  void handleVenueCommitted(Event event) {
    retardEvent(event);
    // Do nothing, if the venue wasn't changed.
    if (entry.journal == prevVenue) return;
    // Hide the update form.
    hideVenueUpdateForm(resetToOriginValues: false);
    // Fire update event to inform parent elements.
    fireLibraryEntryUpdatedEvent();
  }
  
  /// Handles a cancellation of venue update.
  void handleVenueCommitCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideVenueUpdateForm(resetToOriginValues: true);
  }
  
  /// Handles a double click on the year.
  void handleYearDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry.
    if (user == null) return;
    if (user.id != entry.owner) return;
    // Display the update form and cache the current values.
    displayYearUpdateForm(cacheOriginValues: true);
  }
  
  /// Handles a commit of new year.
  void handleYearCommitted(Event event) {
    retardEvent(event);
    // Do nothing, if the year wasn't changed.
    if (entry.year == prevYear) return;
    // Hide the update form.
    hideYearUpdateForm(resetToOriginValues: false);
    // Fire update event to inform parent elements.
    fireLibraryEntryUpdatedEvent();
  }
  
  /// Handles a cancellation of year update.
  void handleYearCommitCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideYearUpdateForm(resetToOriginValues: true);
  }
  
  /// Handles a click on topics-info.
  void handleTopicsInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the topics of this entry.
    Map topics = resolveTopics();
    // Display the topics.
    displayTopicDetails(topics);
  }
  
  /// Handles a click on particiapnts info.
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
  
  /// Handles a click on invitees info.
  void handleDisinviteesInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the invitees.
    Map disinvitees = resolveDisinvitees();
    displayDisinviteesDetails(disinvitees);
  }
  
  /// Handles a click on topic-reject
  void handleRejectTopicButtonClicked(Event event, HtmlElement target) {
    retardEvent(event);
    // Fire topic-rejected event to inform parent elements.
    fireTopicRejectedEvent(target.dataset['topicid']);
  }
  
  /// Handles a click on disinvite participant button.
  void handleParticipantDisinvited(Event event, User participant) {
    retardEvent(event);
    // Fire user-disinivited event.
    fireParticipantDisinvitedEvent(participant);
  }
  
  /// Handles a click on disinvite invitee button.
  void handleInviteeDisinvited(Event event, User invitee) {
    retardEvent(event);
    // Fire user-disinivited event.
    fireInviteeDisinvitedEvent(invitee);
  }
    
//  /// Handles a click on delete button.
//  void handleDeleteButtonClicked(Event event) {
//    retardEvent(event);
//    // Fire deleted event to inform parent elements.
//    fireLibraryEntryDeletedEvent();
//  }
  
  /// Handles a click on blur mask.
  void handleBlurMaskClicked(Event event) {
    retardEvent(event);
    // Hide the participant details.
    hideParticipantDetails();
    // Hide the invitees details.
    hideInviteesDetails();
    // Hide the disinvitees details.
    hideDisinviteesDetails();
    // Hide topic details.
    hideTopicDetails();
    // Hide the actions menu.
    hideActionsMenu();
    // Hide the tag menu.
    hideTagMenu();
    // Hide the update tag form.
    hideUpdateTagForm();
  }
  
  /// Handles a click on the actions button.
  void handleActionsButtonClicked(Event event) {
    retardEvent(event);
    displayActionsMenu();
  }
  
//  /// Handles a commit of new tag.
//  void handleNewTagCommitted(Event event) {
//    retardEvent(event);
//    fireTagAddedEvent(newTagValue);
//  }
  
  /// Handles a click on rename tag button.
  void handleRenameTagButtonClicked(Event event, HtmlElement target) {
    retardEvent(event);
    int index = int.parse(target.dataset['tagidx']);
    updateTagValue = entry.tags[index];
    hideTagMenu();
    displayUpdateTagForm(index);
  }
  
  /// Handles a commit of a tag.
  void handleTagCommitted(Event event, InputElement target) {
    retardEvent(event);
    fireTagUpdatedEvent(showUpdateTagFormIndex, target.value);
    hideUpdateTagForm();
  }
  
  /// Handles a commit of a tag.
  void handleTagCommitCancelled(Event event, HtmlElement element) {
    retardEvent(event);
    hideUpdateTagForm();
  }
    
  /// Handles a deletion of tag.
  void handleDeleteTagButtonClicked(Event event, HtmlElement target) {
    retardEvent(event);
    fireTagDeletedEvent(int.parse(target.dataset['tagidx']));
  }
  
//  /// Handles a selcteion of user for sharing.
//  void handleShareUserSelected(Event event) {
//    retardEvent(event);
//    SelectElement select = event.target;
//    fireUserInvitedEvent(select.value);
//  }
  
  /// Handles a click on a tag menu button.
  void handleTagMenuButtonClicked(Event event, HtmlElement target) {
    retardEvent(event);
    displayTagMenu(int.parse(target.dataset['tagidx']));
  }
  
//  /// Handles a click on the download button.
//  void handleDownloadButtonClicked(Event event) {
//    retardEvent(event);
//    MenuItemElement downloadButton = get("download-button");
//    fireDownloadRequestEvent(downloadButton);
//    hideActionsMenu();
//  }
  
  // ___________________________________________________________________________

  /// Fires an entry-selected event.
  void fireLibraryEntrySelectedEvent({Location location: Location.LIBRARY}) {  
    fire(EVENT_ENTRY_SELECTED, detail: {'entry': entry, 'location': location});
  }
  
  /// Fires an entry-updated event.
  void fireLibraryEntryUpdatedEvent() {
    fire(EVENT_ENTRY_UPDATED, detail: entry); 
  }
  
//  /// Fires an entry-deleted event.
//  void fireLibraryEntryDeletedEvent() {    
//    fire(EVENT_ENTRY_DELETED, detail: entry);
//  }
  
//  /// Fires a user-invited event.
//  void fireUserInvitedEvent(String userId) {
//    fire(EVENT_USER_INVITED, detail: {'entry': entry, 'userId': userId});
//  }
  
  /// Fires a participant-disinvited event.
  void fireParticipantDisinvitedEvent(User user) {
    fire(EVENT_PARTICIPANT_DISINVITED, detail: {'entry': entry, 'user': user});
  }
  
  /// Fires a invitee-disinvited event.
  void fireInviteeDisinvitedEvent(User user) {
    fire(EVENT_INVITEE_DISINVITED, detail: {'entry': entry, 'user': user});
  }
  
  /// Fires a topic-rejected event.
  void fireTopicRejectedEvent(String topicId) {
    fire(EVENT_TOPIC_REJECTED, detail: {'entry': entry, 'topicId': topicId});
  }
       
  /// Fires a tag-updated event.
  void fireTagUpdatedEvent(int index, String newTag) {
    fire(EVENT_TAG_UPDATED, detail: {'entry': entry, 'index': index, 'new': newTag});
  }
  
  /// Fires a tag-deleted event.
  void fireTagDeletedEvent(int index) {
    fire(EVENT_TAG_DELETED, detail: {'entry': entry, 'index': index});
  }
    
  // ___________________________________________________________________________
  
  /// Displays the form to update the text.
  void displayTitleUpdateForm({bool cacheOriginValues}) {
    clickTimer.cancel();
    clickStatus = 0;
    if (cacheOriginValues) prevTitle = entry.title;
    showTitleUpdateForm = true;
  }
  
  /// Hides the form to update the text.
  void hideTitleUpdateForm({bool resetToOriginValues}) {
    if (resetToOriginValues) {
      if (prevTitle != null) entry.title = prevTitle;
    }
    showTitleUpdateForm = false;
  }
    
  /// Displays the form to update the authors.
  void displayAuthorsUpdateForm({bool cacheOriginValues}) {
    clickTimer.cancel();
    clickStatus = 0;
    if (cacheOriginValues) prevAuthors = entry.authorsStr;
    showAuthorsUpdateForm = true;
  }
  
  /// Hides the form to update the text.
  void hideAuthorsUpdateForm({bool resetToOriginValues}) {
    if (resetToOriginValues) {
      if (prevAuthors != null) entry.authorsStr = prevAuthors;
    }
    showAuthorsUpdateForm = false;
  }
  
  /// Displays the form to update the venue.
  void displayVenueUpdateForm({bool cacheOriginValues}) {
    clickTimer.cancel();
    clickStatus = 0;
    if (cacheOriginValues) prevVenue = entry.journal;
    showVenueUpdateForm = true;
  }
  
  /// Hides the form to update the venue.
  void hideVenueUpdateForm({bool resetToOriginValues}) {
    if (resetToOriginValues) {
      if (prevVenue != null) entry.journal = prevVenue;
    }
    showVenueUpdateForm = false;
  }
  
  /// Displays the form to update the year.
  void displayYearUpdateForm({bool cacheOriginValues}) {
    clickTimer.cancel();
    clickStatus = 0;
    if (cacheOriginValues) prevYear = entry.year;
    showYearUpdateForm = true;
  }
  
  /// Hides the form to update the year.
  void hideYearUpdateForm({bool resetToOriginValues}) {
    if (resetToOriginValues) {
      if (prevYear != null) entry.year = prevYear;
    }
    showYearUpdateForm = false;
  }
  
  /// Displays the topic details.
  void displayTopicDetails(Map topics) {
    this.topics.addAll(topics); 
    showTopics = true;
    showBlurMask = true;
  }
  
  /// Hides and clears the topic details.
  void hideTopicDetails() {
    if (this.topics != null) this.topics.clear();
    showTopics = false;
    showBlurMask = false;
  }
  
  /// Displays the participant details.
  void displayParticipantDetails(Map participants) {
    this.participants.addAll(participants);
    showParticipants = true;
    showBlurMask = true;
  }
  
  /// Hides the participant details.
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
  
  /// Hides the invitees details.
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
  
  /// Hides the disinvitees details.
  void hideDisinviteesDetails() {
    if (this.disinvitees != null) this.disinvitees.clear();
    showDisinvitees = false;
    showBlurMask = false;
  }
  
  /// Displays the actions menu.
  void displayActionsMenu() {
    showActionsMenu = true;
    showBlurMask = true;
  }
  
  /// Hides the actions menu.
  void hideActionsMenu() {
    showActionsMenu = false;
    showBlurMask = false;
  }
  
  /// Displays the tag menu tag at given index.
  void displayTagMenu(int index) {
    showTagMenuIndex = index;
    showBlurMask = true;
  }
  
  /// Hides the tag menu.
  void hideTagMenu() {
    showTagMenuIndex = null;
    showBlurMask = false;
  }
  
  /// Displays the update tag form.
  void displayUpdateTagForm(int index) {
    showUpdateTagFormIndex = index;
    showBlurMask = true;
  }
  
  /// Hidesthe update tag form.
  void hideUpdateTagForm() {
    showUpdateTagFormIndex = null;
    showBlurMask = false;
  }
  
  // ___________________________________________________________________________
  
  /// Calls the given callback, if click is a single click (and doesn't belong 
  /// to a double click).
  void checkForSingleClick(Function callback) {
    // On double click, also the click event is fired. So distinguish by hand,
    // if a click belongs to a single click or a double click.
    clickStatus = 1;
    clickTimer = new Timer(new Duration(milliseconds: 300), () {
      if (clickStatus == 1) callback();
    });
  }
  
  // ___________________________________________________________________________
  
  /// Resolves the owner of this library entry.
  User resolveOwner() {
    return actions.getUser(entry.owner);
  }
  
  /// Resolves the owner of this library entry.
  Map getUsers() {
    return actions.getUsers();
  }
  
  /// Resolves the topics of this library entry.
  Map resolveTopics() {
    // Send an empty list if topicIds == null to avoid to fetch all topics.
    Iterable topicIds = entry.topicIds != null ? entry.topicIds : [];
    return actions.getTopics(topicIds);
  }
  
  /// Resolves the participants of this library entry.
  Map resolveParticipants() {
    return actions.getUsers(entry.participants);
  }
  
  /// Resolves the invitees of this library entry.
  Map resolveInvitees() {
    return actions.getUsers(entry.invitees);
  }
  
  /// Resolves the disinvitees of this library entry.
  Map resolveDisinvitees() {
    return actions.getUsers(entry.disinvitees);
  }
}