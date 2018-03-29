@MirrorsUsed(targets: 'Topic')
library user_element;

import 'dart:html';
import "dart:mirrors";
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';

import '../models/models.dart';

/// An entry of the library.
@CustomTag('user-element')
class UserElement extends IceciteElement {  
  // Observable properties.
  @published User member;
  @published bool allowRejection = false;
  @published bool displayMailAddress = false;
  @published int numOfCharsToShow = -1;
  @observable String display;
  @observable String shortDisplay;
  
  // Internal properties.
  HtmlElement userElement;
  HtmlElement dropMaskElement;
  
  /// The default constructor.
  UserElement.created() : super.created();
     
  /// This method is called, when the view is wired up.
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/user_element.css"));
        
    this.userElement = get("user");
    this.dropMaskElement = get("user-dropmask");
    this.shortDisplay = createShortDisplay();
    this.display = createLongDisplay(true);
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    this.display = null;
    this.shortDisplay = null;
  }
    
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever an element is dragged over the user.
  void dragOverHandler(event, details, target) => onDraggedOver(event);
     
  /// This method is called, whenever a dragged element leaves the user.
  void dragLeaveHandler(event, details, target) => onDragLeaved(event);
  
  /// This method is called, whenever a dragged element enters the user.
  void dragEnterHandler(event, details, target) => onDragEntered(event);
     
  /// This method is called, whenever a drag ends (outside of the user).
  void dragEndHandler(event, details, target) => onDragEnded(event);
    
  /// This method is called, whenever an element was dropped on the user.
  void dropHandler(event, details, target) => onDropped(event);
    
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// Will unshare.
  void onRejectUserPurpose(event, details, target) => rejectUser();
  
  // ___________________________________________________________________________
  // Handlers methods.
  
  /// This method is called, whenever an element is dragged over the user.
  void onDraggedOver(var event) {
    // This is necessary to allow us to drop.
    event.stopPropagation();
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
  }
  
  /// This method is called, whenever a dragged element leaves the user.
  void onDragLeaved(var event) {
    event.stopPropagation();
    event.preventDefault();
    userElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    // Change the inner html of drag tooltip.
    var tooltip = document.body.querySelector(".drag-tooltip");
    if (tooltip != null) {
      tooltip.innerHtml = "Assign entry to a topic or share it with a user.";
    }
  }
  
  /// This method is called, whenever a dragged element enters the user.
  void onDragEntered(var event) {
    event.stopPropagation();
    event.preventDefault();
    userElement.classes.add('over');
    dropMaskElement.style.display = "block";
    // Change the inner html of drag tooltip.
    var tip = document.body.querySelector(".drag-tooltip");
    if (tip != null) {
      tip.innerHtml = "Share entry with '${createLongDisplay(true)}'"; 
    }
  }
  
  /// This method is called, whenever a drag ends (outside of the user).
  void onDragEnded(var event) {
    event.stopPropagation();
    event.preventDefault();
    userElement.classes.remove('over');
    dropMaskElement.style.display = "none";
  }
  
  /// This method is called, whenever an element was dropped on the user.
  void onDropped(var event) {
    event.stopPropagation();
    event.preventDefault();
    userElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    String id = event.dataTransfer.getData('Text');
    if (id != null && member != null && member.id != null) {
      fire("user-assignment", detail: {'userId': member.id, 'entryId': id});
    }
  }
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Fires a unshare event.
  void rejectUser() {
    fire("unshare", detail: member);
  }
  
  // ___________________________________________________________________________
  // Helpers.
  
  /// Creates a short display.
  String createShortDisplay() {
    String shortDisplay = createLongDisplay(false);
    if (numOfCharsToShow > -1 && shortDisplay.length > numOfCharsToShow) {
      shortDisplay = "${shortDisplay.substring(0, numOfCharsToShow)}...";
    }
    return shortDisplay;
  }
  
  /// Creates a long display.
  String createLongDisplay(bool createForTooltip) {
    if (displayMailAddress || createForTooltip) 
      return "${member.lastName}, ${member.firstName} (${member.email})";
    else
      return "${member.lastName}, ${member.firstName}";  
  }
}