@MirrorsUsed(targets: 'User,LibraryEntry')
library user_element;

import 'dart:html';
import "dart:mirrors";
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';

import '../models/models.dart';

/// An entry of the library.
@CustomTag('user-element')
class UserElement extends IceciteElement {  
  /// The user to show (called 'member' to avoid conflicts with superior 'user').
  @published User member;
  /// Boolean indicating, whether the disinvitation feature is activated. 
  @published bool allowDisinvitation = false;
  /// Boolean indicating, whether the mail address should be displayed.
  @published bool displayMailAddress = false;
  /// The number of chars to show of each username. 
  /// '-1' means: show complete username.
  @published int numOfCharsToShow = -1;
  /// The complete string (username) to show. 
  @observable String display;
  /// The shortened string (username) to show.
  @observable String shortDisplay;
  
  /// The element wrapping the user.
  HtmlElement userElement;
  /// The element wrapping the dropmask.
  HtmlElement dropMaskElement;
  
  /// The name of "user-invited" event.
  static const String EVENT_USER_INVITED = "user-invited";
  /// The name of "user-disinvited" event.
  static const String EVENT_USER_DISINVITED = "user-disinvited";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  UserElement.created() : super.created();
     
  @override
  void attached() {
    super.attached();       
    this.userElement = get("user");
    this.dropMaskElement = get("user-dropmask");
    this.shortDisplay = createShortDisplay();
    this.display = createLongDisplay(createForTooltip: true);
  }
  
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    this.display = null;
    this.shortDisplay = null;
  }
    
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever an element is dragged over the user.
  void onDraggedOver(event, details, target) => handleDraggedOver(event);
     
  /// This method is called, whenever a dragged element leaves the user.
  void onDragLeaved(event, details, target) => handleDragLeaved(event);
  
  /// This method is called, whenever a dragged element enters the user.
  void onDragEntered(event, details, target) => handleDragEntered(event);
     
  /// This method is called, whenever a drag ends (outside of the user).
  void onDragEnded(event, details, target) => handleDragEnded(event);
    
  /// This method is called, whenever an element was dropped on the user.
  void onDropped(event, details, target) => handleDropped(event);
      
  /// This method is called, whenever a particiaptn was rejected.
  void onDisinviteButtonClicked(event) => handleDisinviteButtonClicked(event);
  
  // ___________________________________________________________________________
  // Private actions.
  
  /// This method is called, whenever an element is dragged over the user.
  void handleDraggedOver(MouseEvent event) {
    retardEvent(event);
    event.dataTransfer.dropEffect = 'move';
  }
  
  /// This method is called, whenever a dragged element leaves the user.
  void handleDragLeaved(MouseEvent event) {
    retardEvent(event);
    userElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Change the inner html of drag tooltip.
    var tooltip = document.body.querySelector(".drag-tooltip");
    if (tooltip != null) {
      tooltip.innerHtml = "Assign entry to a topic or share it with a user.";
    }
  }
  
  /// This method is called, whenever a dragged element enters the user.
  void handleDragEntered(MouseEvent event) {
    retardEvent(event);
    userElement.classes.add('over');
    dropMaskElement.style.display = "block";
    // Change the inner html of drag tooltip.
    var tip = document.body.querySelector(".drag-tooltip");
    if (tip != null) {
      String display = createLongDisplay(createForTooltip: true);
      tip.innerHtml = "Share entry with '${display}'"; 
    }
  }
  
  /// This method is called, whenever a drag ends (outside of the user).
  void handleDragEnded(MouseEvent event) {
    retardEvent(event);
    userElement.classes.remove('over');
    dropMaskElement.style.display = "none";
  }
  
  /// This method is called, whenever an element was dropped on the user.
  void handleDropped(MouseEvent event) {
    retardEvent(event);
    userElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    String entryId = event.dataTransfer.getData('Text');
    fireUserInvitedEvent(entryId, member.id);
  }
    
  /// Handles a click on disinvite button.
  void handleDisinviteButtonClicked(Event event) {
    retardEvent(event);
    // fire 'user-disinvited' event.
    fireUserDisinvitedEvent();
  }
    // ___________________________________________________________________________
  // Helpers.
  
  /// Creates a short display.
  String createShortDisplay() {
    String shortDisplay = createLongDisplay(createForTooltip: false);
    if (numOfCharsToShow > -1 && shortDisplay.length > numOfCharsToShow) {
      shortDisplay = "${shortDisplay.substring(0, numOfCharsToShow)}...";
    }
    return shortDisplay;
  }
  
  /// Creates a long display.
  String createLongDisplay({bool createForTooltip}) {
    if (displayMailAddress || createForTooltip) 
      return "${member.lastName}, ${member.firstName} (${member.email})";
    else
      return "${member.lastName}, ${member.firstName}";  
  }
  
  // ___________________________________________________________________________
  
  /// Fires a 'user-invited' event.
  void fireUserInvitedEvent(String entryId, String userId) {
    fire(EVENT_USER_INVITED, detail: {'userId': userId, 'entryId': entryId});
  }
  
  /// Fires a 'user-disinvited' event.
  void fireUserDisinvitedEvent() {
    fire(EVENT_USER_DISINVITED, detail: member);
  }
}