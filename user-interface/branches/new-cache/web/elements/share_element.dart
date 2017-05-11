library search_element;

import 'dart:html' hide Entry;
import 'icecite_element.dart';
import '../utils/request.dart';
import '../utils/html/logging_util.dart' as logging;
import '../models/models.dart';
import '../cache/user_cache.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('share-element')
/// Our implementation of an share-element.
class ShareElement extends IceciteElement {   
  Logger LOG = logging.get("share-element");
  
  @published Entry entry;
  @observable User owner;
  @observable List<User> users;
  @observable bool showShareWithDetails = false;
  @observable bool showParticipantsDetails = false;
  @observable bool showInviteesDetails = false;
  @observable bool showDisinviteesDetails = false;
  @observable List<User> participants = toObservable([]);
  @observable List<User> invitees = toObservable([]);
  @observable List<User> disinvitees = toObservable([]);
  @observable int selectedUserIndex = 0;  
  @observable int sumParticipantsInvitees = 0;
  
  /// The user cache.
  UserCache userCache;
  /// The share details element.
  Element shareDetailsElement;
  /// The selected user for sharing.
  List<User> selectedUserForSharing = [];
  
  /// The constructor.
  ShareElement.created() : super.created();
  
  @override
  void attached() {
    super.attached();
    this.userCache = new UserCache();
    this.owner = resolveOwner();
    this.users = resolveUsers();
    this.participants.addAll(resolveParticipants());
    this.invitees.addAll(resolveInvitees());
    this.disinvitees.addAll(resolveDisinvitees());
    this.sumParticipantsInvitees = participants.length + invitees.length;
    this.shareDetailsElement = get("share-details");
    
    hideShareDetails();
    
    /// Listen for changes on participants, invitees and disinvitees.
    entry.changes.listen((list) {
      list.forEach((ChangeRecord change) {
        if (change is PropertyChangeRecord) {
          if (change.name == #participants) {
            this.participants.clear();
            this.participants.addAll(resolveParticipants());
            this.sumParticipantsInvitees = participants.length + invitees.length;
          }
          if (change.name == #invitees) {
            this.invitees.clear();
            this.invitees.addAll(resolveInvitees());
            this.sumParticipantsInvitees = participants.length + invitees.length;
          }
          if (change.name == #disinvitees) {
            this.disinvitees.clear();
            this.disinvitees.addAll(resolveDisinvitees()); 
          }
        }
      });
    });
  }
  
  // ___________________________________________________________________________
  
  /// This method is called, whenever the share info button was clicked.
  void onShareInfoClick(event, data, target) => handleShareInfoClick(event);
  
  /// This method is called, whenever the mouse entered the share with area.
  void onShareWithMouseEnter(event) => handleShareWithMouseEnter();
  
  /// This method is called, whenever the mouse leaves the share with area.
  void onShareWithMouseLeave(event) => handleShareWithMouseLeave();
  
  /// This method is called, whenever the mouse entered the participants info.
  void onParticipantsInfoMouseEnter(evt) => handleParticipantsInfoMouseEnter();
  
  /// This method is called, whenever the mouse entered the invitees info.
  void onInviteesInfoMouseEnter(evt) => handleInviteesInfoMouseEnter();

  /// This method is called, whenever the mouse entered the disinvitees info.
  void onDisinviteesInfoMouseEnter(evt) => handleDisinviteesInfoMouseEnter();
  
  /// This method is called, whenever the mouse entered the participants info.
  void onParticipantsInfoMouseLeave(evt) => handleParticipantsInfoMouseLeave();
  
  /// This method is called, whenever the mouse entered the invitees info.
  void onInviteesInfoMouseLeave(evt) => handleInviteesInfoMouseLeave();
  
  /// This method is called, whenever the mouse entered the disinvitees info.
  void onDisinviteesInfoMouseLeave(evt) => handleDisinviteesInfoMouseLeave();
    
  /// This method is called, whenever a remove participant button was clicked.
  void onRemoveParticipantClick(event) => handleRemoveParticipantClick(event);
  
  /// This method is called, whenever a remove invitee button was clicked.
  void onRemoveInviteeClick(event) => handleRemoveInviteeClick(event);
  
  void onShareUserCheckboxMousedown(evt) => handleShareUserCheckboxMousedown(evt);
  
  void onShareUserCheckboxClick(event) => handleShareUserCheckboxClick(event);
  
  void onShareUserCommitButtonMousedown(event) => handleShareUserCommitButtonMousedown(event);
  
  void onShareUserCommitButtonClick(event) => handleShareUserCommitButtonClick(event);
  
  void onShareDetailsBlur(event) {
    hideShareDetails();
  }
        
  // ___________________________________________________________________________
  
  /// Handles a click on share info.
  void handleShareInfoClick(event) {
    displayShareDetails();
    shareDetailsElement.focus();
  }
  
  /// Handles a mouse enter on "share with".
  void handleShareWithMouseEnter() {
    displayShareWithDetails();
  }
  
  /// Handles a mouse enter on invitees info.
  void handleInviteesInfoMouseEnter() {
    displayInviteesDetails();
  }
  
  /// Handles a mouse enter on disinvitees info.
  void handleDisinviteesInfoMouseEnter() {
    displayDisinviteesDetails();
  }
  
  /// Handles a mouse enter on participants info.
  void handleParticipantsInfoMouseEnter() {
    displayParticipantsDetails();
  }
  
  /// Handles a mouse leave on "share with".
  void handleShareWithMouseLeave() {
    hideShareWithDetails();
  }
  
  /// Handles a mouse leave on invitees info.
  void handleInviteesInfoMouseLeave() {
    hideInviteesDetails();
  }
  
  /// Handles a mouse leave on disinvitees info.
  void handleDisinviteesInfoMouseLeave() {
    hideDisinviteesDetails();
  }
  
  /// Handles a mouse leave on participants info.
  void handleParticipantsInfoMouseLeave() {
    hideParticipantsDetails();
  }
    
  /// Handles a click on remove participant button.
  void handleRemoveParticipantClick(event) {
    Element element = event.target;
    if (element == null) return;
    
    int participantIndex = int.parse(element.dataset['participant-idx']);
    if (participantIndex < 0) return;
    if (participantIndex > participants.length - 1) return;
    
    fireUnshareRequest(participants.removeAt(participantIndex));
    if (participants.isEmpty) hideParticipantsDetails();
  }
  
  /// Handles a click on remove invitee button.
  void handleRemoveInviteeClick(event) {
    Element element = event.target;
    if (element == null) return;
        
    int inviteeIndex = int.parse(element.dataset['invitee-idx']);
    if (inviteeIndex < 0) return;
    if (inviteeIndex > invitees.length - 1) return;
        
    fireUnshareRequest(invitees.removeAt(inviteeIndex));
    if (invitees.isEmpty) hideInviteesDetails();
  }
  
  void handleShareUserCheckboxMousedown(event) {
    /// Need to reatrd the event, such that the share details aren't blurred.
    retardEvent(event);
  }
  
  void handleShareUserCommitButtonMousedown(event) {
    /// Need to reatrd the event, such that the share details aren't blurred.
    retardEvent(event);
  }
  
  void handleShareUserCheckboxClick(Event event) {
    CheckboxInputElement checkbox = event.target;
    if (checkbox == null) return;
    int index = int.parse(checkbox.dataset['useridx']);
    if (index < 0) return;
    if (index > users.length - 1) return;
    
    User user = users[index];
    if (user == null) return;
    
    if (checkbox.checked) {
      selectedUserForSharing.add(user);
    } else {
      selectedUserForSharing.remove(user);
    }
    
    print(selectedUserForSharing);
  }
  
  void handleShareUserCommitButtonClick(event) {
    retardEvent(event);
    
    if (selectedUserForSharing.isNotEmpty) {
      fireShareRequest(selectedUserForSharing);
    }
    selectedUserForSharing.clear();
    hideShareWithDetails();
  }
  
  // ___________________________________________________________________________
  
  /// Displays the share details.
  void toggleShareDetails() {
    if (isShareDetailsHidden()) {
      displayShareDetails();
    } else {
      hideShareDetails();
    }
  }
  
  /// Displays the share details.
  void displayShareDetails() {
    this.shareDetailsElement.style.display = "block";
    
    Element shareInfo = get("share-info");
            
    shareDetailsElement.classes.remove("above");
    shareDetailsElement.classes.remove("below");
    shareDetailsElement.style.display = "block";
               
    // Positionize the menu body. Check, if the content fits below the 
    // menu toggle. Otherwise, positionize it above the toggle.
    var windowHeight = window.innerHeight;
    var menuToggleBottom = shareInfo.getBoundingClientRect().bottom;
    var menuContentHeight = shareDetailsElement.getBoundingClientRect().height;
    var menuContentBottom = menuToggleBottom + menuContentHeight;
        
    if (menuContentBottom < windowHeight) {
      // The menu fits below the menu toggle.
      shareDetailsElement.classes.add("below");
    } else {
      // The menu doesn't fit below the menu toggle. Positionize it above the 
      // toggle.
      shareDetailsElement.classes.add("above");
    }          
  }
  
  /// Hides the share details.
  void hideShareDetails() {
    this.shareDetailsElement.style.display = "none";
  }
  
  /// Hides the share details.
  bool isShareDetailsHidden() {
    return this.shareDetailsElement.style.display == "none";
  }
  
  // ___________________________________________________________________________
  
  /// Displays the "share with" details.
  void toggleShareWithDetails() {
    this.showShareWithDetails = !this.showShareWithDetails;
  }
  
  /// Displays the "share with" details.
  void displayShareWithDetails() {
    this.showShareWithDetails = true;
  }
  
  /// Hides the "share with" details.
  void hideShareWithDetails() {
    this.showShareWithDetails = false;
  }
  
  /// Displays the participants details.
  void toggleParticipantsDetails() {
    this.showParticipantsDetails = !this.showParticipantsDetails;
  }
  
  /// Displays the participants details.
  void displayParticipantsDetails() {
    this.showParticipantsDetails = true;
  }
  
  /// Hides the participants details.
  void hideParticipantsDetails() {
    this.showParticipantsDetails = false;
  }
  
  /// Displays the invitees details.
  void toggleInviteesDetails() {
    this.showInviteesDetails = !this.showInviteesDetails;
  }
  
  /// Displays the invitees details.
  void displayInviteesDetails() {
    this.showInviteesDetails = true;
  }
  
  /// Hides the invitees details.
  void hideInviteesDetails() {
    this.showInviteesDetails = false;
  }
  
  /// Displays the disinvitees details.
  void toggleDisinviteesDetails() {
    this.showDisinviteesDetails = !this.showDisinviteesDetails;
  }
  
  /// Displays the disinvitees details.
  void displayDisinviteesDetails() {
    this.showDisinviteesDetails = true;
  }
  
  /// Hides the disinvitees details.
  void hideDisinviteesDetails() {
    this.showDisinviteesDetails = false;
  }
  
  // ___________________________________________________________________________
  
  /// Resolves the owner of this library entry.
  User resolveOwner() {
    return userCache.getUser(entry.userId);
  }
  
  /// Resolves all registered users.
  List<User> resolveUsers() {
    return userCache.getUsers(); // TODO: Use auth.users
  }
  
  /// Resolves the participants of this library entry.
  List<User> resolveParticipants() {
    return userCache.getUsers(entry.participants != null ? entry.participants : []);
  }
  
  /// Resolves the invitees of this library entry.
  List<User> resolveInvitees() {
    return userCache.getUsers(entry.invitees != null ? entry.invitees : []);
  }
  
  /// Resolves the disinvitees of this library entry.
  List<User> resolveDisinvitees() {
    return userCache.getUsers(entry.disinvitees != null ? entry.disinvitees : []);
  }
  
  // ___________________________________________________________________________
  
  /// Fires a user-invited event.
  void fireShareRequest(List<User> users) {
    fire(IceciteRequest.SHARE_ENTRY, detail: {'entry': entry, 'users': users});
  } 
  
  /// Fires a user-invited event.
  void fireUnshareRequest(User user) {
    fire(IceciteRequest.UNSHARE_ENTRY, detail: {'entry': entry, 'user': user});
  } 
}