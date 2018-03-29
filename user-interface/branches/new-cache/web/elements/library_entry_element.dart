@MirrorsUsed(targets: 'LibraryEntry')
library library_entry_element;

import 'dart:html' hide Location, Notification, MenuElement, Entry;
import 'dart:async';
import 'dart:mirrors';
import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../properties.dart';
import '../cache/user_cache.dart';
import '../models/models.dart';
import '../utils/request.dart';
import 'package:polymer/polymer.dart';

/// An entry of the library.
@CustomTag('library-entry-element')
class LibraryEntryElement extends IceciteElement {    
  /// The entry
  @published Entry entry;
  /// The users.
  @published List<User> users;
  /// The resolved participants.
  @observable List<User> participants = [];
  /// The resolved invitees.
  @observable List<User> invitees = [];
  /// The resolved disinvitees.
  @observable List<User> disinvitees = [];
  /// Boolean, indicating whether the title update form is displayed.
  @observable bool showTitleForm = false;
  /// Boolean, indicating whether the authors update form is displayed.
  @observable bool showAuthorsForm = false;
  /// Boolean, indicating whether the venue update form is displayed.
  @observable bool showVenueForm = false;
  /// Boolean, indicating whether the year update form is displayed.
  @observable bool showYearForm = false;
  /// Boolean, indicating whether the participants-details are displayed.
  @observable bool showParticipants = false;
  /// Boolean, indicating whether the invitees-details are displayed.
  @observable bool showInvitees = false;
  /// Boolean, indicating whether the disinvitees-details are displayed.
  @observable bool showDisinvitees = false;
  /// Boolean indicating whether the actions menu is shown.
  @observable bool showActionsMenu = false;
  /// The resolved owner of this entry.
  @observable User owner;
  /// Boolean indicationg whether the verbose mode is turned on or off.
  @observable bool verbose = VERBOSE_MODE; 
    
  /// The cached original title.
  String titleFormValue;
  ///  The cached original authors.
  String authorsFormValue;
  /// The cached original venue.
  String venueFormValue;
  /// The cached original year.
  String yearFormValue;
  /// The click timer to decide, if a click belongs to a double click.
  Timer clickTimer;
  /// The click status to decide, if a click belongs to a double click.
  var clickStatus = 1;
      
  DivElement container;
  
  /// The user cache.
  UserCache userCache;
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  LibraryEntryElement.created() : super.created();
         
  @override
  void attached() {
    super.attached();
    this.userCache = new UserCache();
    // Resolve the userId of this library entry.
    this.owner = resolveOwner();
    // Resolve all users.
    this.users = getUsers();
    this.container = get("entry");
  }
      
  @override
  void reset() {
    super.reset();
    this.showTitleForm = false;
    this.showAuthorsForm = false;
    this.showVenueForm = false;
    this.showYearForm = false;
    this.showParticipants = false;
    this.showInvitees = false;
    this.showDisinvitees = false;
    if (this.participants != null) this.participants.clear();
    if (this.invitees != null) this.invitees.clear();
    if (this.disinvitees != null) this.disinvitees.clear();
    this.titleFormValue = null;
    this.authorsFormValue = null;
    this.venueFormValue = null;
    this.yearFormValue = null;
    this.clickTimer = null;
    this.clickStatus = 1;
  }
    
  // ___________________________________________________________________________
  // Handlers.
                 
  /// This method is called whenever an entry was clicked.
  void onEntryClicked(event) => handleEntryClicked(event);
  
  /// This method is called whenever a tag was clicked.
  void onTagClicked(event, detail, target) => handleTagClicked(event, target);
  
  /// This method is called, whenever the title was double clicked.
  void onTitleDoubleClicked(event) => handleTitleDoubleClicked(event);
  
  /// This method is called, whenever a new title was committed.
  void onTitleFormCommitted(event) => handleTitleFormCommitted(event);
 
  /// This method is called, whenever the commit of a new title was cancelled.
  void onTitleFormCancelled(event) => handleTitleFormCancelled(event); 
    
  /// This method is called, whenever the authors were double clicked.
  void onAuthorsDoubleClicked(event) => handleAuthorsDoubleClicked(event);
  
  /// This method is called, whenever new authors were committed.
  void onAuthorsFormCommitted(event) => handleAuthorsFormCommitted(event);

  /// This method is called, whenever the commit of new authors were cancelled.
  void onAuthorsFormCancelled(event) => handleAuthorsFormCancelled(event);

  /// This method is called, whenever the venue was double clicked.
  void onVenueDoubleClicked(event) => handleVenueDoubleClicked(event);
  
  /// This method is called, whenever a new venue was committed.
  void onVenueFormCommitted(event) => handleVenueFormCommitted(event);
  
  /// This method is called, whenever the commit of new vanue was cancelled.
  void onVenueFormCancelled(event) => handleVenueFormCancelled(event);

  /// This method is called, whenever the year was double clicked.
  void onYearDoubleClicked(event) => handleYearDoubleClicked(event);
  
  /// This method is called, whenever a new year was committed.
  void onYearFormCommitted(event) => handleYearFormCommitted(event);
  
  /// This method is called, whenever the commit of new year was cancelled.
  void onYearFormCancelled(event) => handleYearFormCancelled(event);
                 
  /// This method is called, whenever the participants-info was clicked.
  void onParticipantsInfoClicked(event) => handleParticipantsInfoClicked(event);
  
  /// This method is called, whenever the disinvite-button in participant 
  /// details was clicked.
  void onUnshareRequest(evt, data) => handleUnshareRequest(evt, data);
  
  /// This method is called, whenever the invitees-info was clicked.
  void onInviteesInfoClicked(event) => handleInviteesInfoClicked(event);
     
  /// This method is called, whenever the disinvitees-info was clicked.
  void onDisinviteesInfoClicked(event) => handleDisinviteesInfoClicked(event);
 
  /// This method is called, whenever a tag was double clicked.
  void onRemoveTagRequest(e, d, t) => handleRemoveTagRequest(e, t);
        
  /// This method is called, whenever the notification's abort button is clicked
  void onNotificationAbortClick(event) => handleNotificationAbortClick(event);
  
  // ___________________________________________________________________________
  // Actions.
           
  /// Handles a click on library entry.
  void handleEntryClicked(Event event) {
    retardEvent(event);
    // Check for single click and fire entry-selected event.
    checkForSingleClick(() => fireSelectRequest());
  }
  
  /// Handles a click on tag.
  void handleTagClicked(Event event, Element target) {
    retardEvent(event); 
    // Fire select tag request.
    if (entry.tags == null || entry.tags.isEmpty) return;
    int tagIndex = int.parse(target.dataset['tagidx']);
    if (tagIndex == null) return;
    if (tagIndex < 0) return;
    if (tagIndex > entry.tags.length - 1) return;
    fireSelectTagRequest(entry.tags[tagIndex]);
  }
  
  /// Handles a double click on the title.
  void handleTitleDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry.
    if (user == null) return;
    if (!user.isOwner(entry)) return;
    // Display the update form and cache the current values.
    displayTitleForm();
  }
  
  /// Handles a commit of new title.
  void handleTitleFormCommitted(Event event) {
    retardEvent(event);
    if (entry.title != titleFormValue) {
      fireUpdateRequest({'title': titleFormValue});
    }
    hideTitleForm();
  }
  
  /// Handles a cancellation of title update.
  void handleTitleFormCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideTitleForm();
  }
  
  /// Handles a double click on the authors.
  void handleAuthorsDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry. 
    if (user == null) return;
    if (!user.isOwner(entry)) return;
    // Display the update form and cache the current values.
    displayAuthorsForm();
  }
  
  /// Handles a commit of new authors.
  void handleAuthorsFormCommitted(Event event) {
    retardEvent(event);
    if (entry.authors.join(", ") != authorsFormValue) {
      fireUpdateRequest({'authors': toAuthorsList(authorsFormValue)});
    }
    // Hide the update form.
    hideAuthorsForm();
  }
  
  /// Handles a cancellation of authors update.
  void handleAuthorsFormCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideAuthorsForm();
  }
  
  /// Handles a double click on the venue.
  void handleVenueDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry. 
    if (user == null) return;
    if (!user.isOwner(entry)) return;
    // Display the update form and cache the current values.
    displayVenueForm();
  }
  
  /// Handles a commit of new venue.
  void handleVenueFormCommitted(Event event) {
    retardEvent(event);
    // Do nothing, if the venue wasn't changed.
    if (entry.journal != venueFormValue) {
      fireUpdateRequest({'journal': venueFormValue});
    }
    // Hide the update form.
    hideVenueForm();
  }
  
  /// Handles a cancellation of venue update.
  void handleVenueFormCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideVenueForm();
  }
  
  /// Handles a double click on the year.
  void handleYearDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the owner of entry.
    if (user == null) return;
    if (!user.isOwner(entry)) return;
    // Display the update form and cache the current values.
    displayYearForm();
  }
  
  /// Handles a commit of new year.
  void handleYearFormCommitted(Event event) {
    retardEvent(event);
    // Do nothing, if the year wasn't changed.
    if (entry.year != yearFormValue) {
      fireUpdateRequest({'year': yearFormValue});
    }
    // Hide the update form.
    hideYearForm();
  }
  
  /// Handles a cancellation of year update.
  void handleYearFormCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideYearForm();
  }
    
  /// Handles a click on particiapnts info.
  void handleParticipantsInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the participants.
    displayParticipantDetails(resolveParticipants());
  }
    
  /// Handles a click on invitees info.
  void handleInviteesInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the invitees.
    displayInviteesDetails(resolveInvitees());
  }
  
  /// Handles a click on invitees info.
  void handleDisinviteesInfoClicked(Event event) {
    retardEvent(event);
    // Resolve the invitees.
    displayDisinviteesDetails(resolveDisinvitees());
  }
    
  /// Handles a click on disinvite participant button.
  void handleUnshareRequest(Event event, User participant) {
    retardEvent(event);
    // Fire user-disinivited event.
    fireUnshareRequest(participant);
  }
              
  /// Handles a click on delete tag button.
  void handleRemoveTagRequest(Event event, HtmlElement target) {
    retardEvent(event);
    int index = int.parse(target.dataset['tagidx']);
    fireDeleteTagRequest(index);
  }
     
  /// Handles a click on delete tag button.
  void handleNotificationAbortClick(Event event) {
    if (entry == null) return;
    if (entry.notification == null) return;
    if (entry.notification.onAbort == null) return;
    entry.notification.onAbort(event);
  }
  
  // ___________________________________________________________________________

  /// Fires an entry-selected event.
  void fireSelectRequest() {  
    fire(IceciteRequest.SELECT_ENTRY, detail: entry);
  }
  
  /// Fires an entry-updated event.
  void fireUpdateRequest(Map data) {
    fire(IceciteRequest.UPDATE_ENTRY, detail: {'entry': entry, 'data': data}); 
  }
      
  /// Fires a invitee-disinvited event.
  void fireUnshareRequest(User user) {
    fire(IceciteRequest.UNSHARE_ENTRY, detail: {'entry': entry, 'user': user});
  }
           
  /// Fires a tag-deleted event.
  void fireDeleteTagRequest(int index) {
    fire(IceciteRequest.DELETE_TAG, detail: {'entry': entry, 'index': index});
  }
  
  /// Fires a tag-deleted event.
  void fireSelectTagRequest(String tag) {
    fire(IceciteRequest.SELECT_TAG, detail: tag);
  }
    
  // ___________________________________________________________________________
  
  /// Displays the form to update the text.
  void displayTitleForm() {
    clickTimer.cancel();
    clickStatus = 0;
    titleFormValue = entry.title;
    showTitleForm = true;
  }
  
  /// Hides the form to update the text.
  void hideTitleForm() {
    showTitleForm = false;
  }
    
  /// Displays the form to update the authors.
  void displayAuthorsForm() {
    clickTimer.cancel();
    clickStatus = 0;
    authorsFormValue = entry.authors.join(", ");
    showAuthorsForm = true;
  }
  
  /// Hides the form to update the text.
  void hideAuthorsForm() {
    showAuthorsForm = false;
  }
  
  /// Displays the form to update the venue.
  void displayVenueForm() {
    clickTimer.cancel();
    clickStatus = 0;
    venueFormValue = entry.journal;
    showVenueForm = true;
  }
  
  /// Hides the form to update the venue.
  void hideVenueForm() {
    showVenueForm = false;
  }
  
  /// Displays the form to update the year.
  void displayYearForm() {
    clickTimer.cancel();
    clickStatus = 0;
    yearFormValue = entry.year;
    showYearForm = true;
  }
  
  /// Hides the form to update the year.
  void hideYearForm() {
    showYearForm = false;
  }
    
  /// Displays the participant details.
  void displayParticipantDetails(List participants) {
    this.participants.addAll(participants);
    showParticipants = true;
  }
  
  /// Hides the participant details.
  void hideParticipantDetails() {
    if (this.participants != null) this.participants.clear();
    showParticipants = false;
  }
  
  /// Displays the invitees details.
  void displayInviteesDetails(List invitees) {
    this.invitees.addAll(invitees);
    showInvitees = true;
  }
  
  /// Hides the invitees details.
  void hideInviteesDetails() {
    if (this.invitees != null) this.invitees.clear();
    showInvitees = false;
  }
  
  /// Displays the disinvitees details.
  void displayDisinviteesDetails(List disinvitees) {
    this.disinvitees.addAll(disinvitees);
    showDisinvitees = true;;
  }
  
  /// Hides the disinvitees details.
  void hideDisinviteesDetails() {
    if (this.disinvitees != null) this.disinvitees.clear();
    showDisinvitees = false;
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
  
  /// Sets the authors string.
  List<String> toAuthorsList(String authorsStr) {
    if (authorsStr == null) return null;
    List authors = [];
    List<String> splitted = authorsStr.split(new RegExp("[,;]"));
    splitted.forEach((split) => authors.add(split.trim()));
    return authors;
  }
  
  // ___________________________________________________________________________
  
  /// Resolves the owner of this library entry.
  User resolveOwner() {
    return userCache.getUser(entry.userId);
  }
  
  /// Resolves the owner of this library entry.
  List<User> getUsers() {
    return userCache.getUsers(); // TODO: Use auth.users
  }
    
  /// Resolves the participants of this library entry.
  List<User> resolveParticipants() {
    return userCache.getUsers(entry.participants);
  }
  
  /// Resolves the invitees of this library entry.
  List<User> resolveInvitees() {
    return userCache.getUsers(entry.invitees);
  }
  
  /// Resolves the disinvitees of this library entry.
  List<User> resolveDisinvitees() {
    return userCache.getUsers(entry.disinvitees);
  }
}