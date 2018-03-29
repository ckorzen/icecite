library menu_element;

import 'dart:html';
import 'icecite_element.dart';
import 'menu_item_element.dart';
import '../models/models.dart';
import 'package:polymer/polymer.dart';

@CustomTag('menu-element')
class MenuElement extends IceciteElement {         
  @published LibraryEntry entry;
  @published Iterable<User> users;
  @observable String newTagValue;
  
  /// The name of download-request event. 
  static const String EVENT_DOWNLOAD_REQUEST = "download-request";
  /// The name of tag-added event.
  static const String EVENT_TAG_ADDED = "tag-added";
  /// The name of user-invited event.
  static const String EVENT_USER_INVITED = "user-invited";
  /// The name of entry-deleted event.
  static const String EVENT_ENTRY_DELETED = "entry-deleted";

  /// The default constructor.
  MenuElement.created() : super.created();
      
  // ___________________________________________________________________________
  
  void onMenuToggleClick(event) => toggleMenuContent(); 
    
  void onDownloadButtonClicked(event) => handleDownloadButtonClicked(event);
  
  void onNewTagCommitted(event) => handleNewTagCommitted(event);
  
  void onShareUserSelected(event) => handleShareUserSelected(event);
  
  void onDeleteButtonClicked(event) => handleDeleteButtonClicked(event);
  
  // ___________________________________________________________________________
  
  void toggleMenuContent() {
    if (!isMenuContentHidden()) {
      hideMenuContent();
    } else {
      displayMenuContent();   
    } 
  }
  
  bool isMenuContentHidden() {
    String display = get("menu-content").style.display;
    return display == null || display.isEmpty || display == "none";
  }
  
  void displayMenuContent() {
    var menuToggle = get("menu-toggle");
    DivElement menuContent = get("menu-content");
        
    // Positionize the menu body.
    var menuToggleBottom = menuToggle.getBoundingClientRect().bottom;
    var menuToggleLeft = menuToggle.getBoundingClientRect().left;
    
    menuContent.style.display = "block";
    menuContent.style.top = "${menuToggleBottom + 7}px";
    menuContent.style.left = "${menuToggleLeft + 7}px";
  }
  
  void hideMenuContent() {
    get("menu-content").style.display = "none";
  }
  
  void handleDownloadButtonClicked(event) {
    retardEvent(event);
    MenuItemElement downloadButton = event.target;
    downloadButton.disable();
    fireDownloadRequestEvent(downloadButton);
  }
   
  void handleNewTagCommitted(event) {
    retardEvent(event);
    fireTagAddedEvent(newTagValue);
  }
   
  void handleShareUserSelected(event) {
    retardEvent(event);
    SelectElement select = event.target;
    fireUserInvitedEvent(select.value);
  }
   
  void handleDeleteButtonClicked(event) {
    retardEvent(event);
    fireLibraryEntryDeletedEvent();
  }
  
  // ___________________________________________________________________________
  
  /// Fires a tag-deleted event.
  void fireDownloadRequestEvent(MenuItemElement button) {
    fire(EVENT_DOWNLOAD_REQUEST, detail: {"entry": entry, "button": button});
  }
  
  /// Fires a tag-added event.
  void fireTagAddedEvent(String tag) {
    fire(EVENT_TAG_ADDED, detail: {'entry': entry, 'tag': tag});
  }
  
  /// Fires a user-invited event.
  void fireUserInvitedEvent(String userId) {
    fire(EVENT_USER_INVITED, detail: {'entry': entry, 'userId': userId});
  }
  
  /// Fires an entry-deleted event.
  void fireLibraryEntryDeletedEvent() {    
    fire(EVENT_ENTRY_DELETED, detail: entry);
  }
}