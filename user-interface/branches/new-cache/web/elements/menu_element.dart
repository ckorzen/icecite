library menu_element;

import 'dart:html' hide Notification, Entry;
import 'icecite_element.dart';
import 'menu_item_element.dart';
import '../models/models.dart';
import '../utils/request.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('menu-element')
class MenuElement extends IceciteElement {   
  @published Entry entry;
  @published Iterable<User> users;
  @observable String newTagsValue;
  @observable String pdfUrlValue;
  
  Logger LOG = logging.get("menu-element");
  
  /// The menu content is focusesd on displaying it. On blurring, the menu 
  /// content will be hid. Because the menu content is losing focus on clicking
  /// a textbox in menuContent, we introduce a flag, that is set on mousedown
  /// on menuContent (mousedown is fired before blur). This flag indicates, 
  /// whether an element of the menu content was clicked. On blurring, this
  /// flag is checked. If true, the menu content won't be hid. Otherswise, it
  /// will be hid. 
  bool isMenuContentActive = false;
  
  /// The default constructor.
  MenuElement.created() : super.created();
  
  // ___________________________________________________________________________
  
  void onMenuToggleClick(event) => handleMenuToggleClick();
  
  void onMenuContentMousedown() => handleMenuContentMousedown();
  
  void onMenuContentMouseup() => handleMenuContentMouseup();
  
  void onMenuContentBlur(event) => handleMenuContentBlur(event);
    
  void onDownloadButtonClicked(event) => handleDownloadButtonClicked(event);
  
  void onNewTagCommitted(event) => handleNewTagCommitted(event);
    
  void onRepeatStrippingButtonClick() => handleRepeatStrippingButtonClick();
  
  void onDeleteButtonClick(event) => handleDeleteButtonClick(event);
  
  void onAddPdfUrlRequest(event) => handleAddPdfUrlRequest(event);
    
  void onAddPdfUrlInputBlur(event) => handleAddPdfUrlInputBlur(event);
        
  void onAddTagInputBlur(event) => handleAddTagInputBlur(event);
    
  // ___________________________________________________________________________
  
  /// Handles a click on menu toggle.
  void handleMenuToggleClick() {
    displayMenuContent();
    get("menu-content").focus();
  }
  
  /// Handles a click on menu toggle.
  void handleMenuContentBlur(event) {
    if (!isMenuContentActive) hideMenuContent();
  }
  
  void handleAddPdfUrlInputBlur(event) {
    /// Need to retard the event, such that the share details aren't blurred.
    if (!isMenuContentActive) hideMenuContent();
  }
      
  void handleAddTagInputBlur(event) {
    /// Need to retard the event, such that the share details aren't blurred.
    if (!isMenuContentActive) hideMenuContent();
  }
  
  void handleMenuContentMousedown() {
    /// Need to retard the event, such that the share details aren't blurred.
    this.isMenuContentActive = true;
  }
   
  void handleMenuContentMouseup() {
    /// Need to retard the event, such that the share details aren't blurred.
    this.isMenuContentActive = false;
  }
  
  void handleDownloadButtonClicked(event) {
    LOG.finest("Download button clicked for entry $entry.");
    retardEvent(event);
    MenuItemElement downloadButton = event.target;
    downloadButton.disable();
    fireImportRequest(downloadButton);
  }
    
  void handleNewTagCommitted(event) {
    LOG.finest("New tags committed for entry $entry: $newTagsValue");
    retardEvent(event);
    fireNewTagsRequest(newTagsValue);
    hideMenuContent();
    this.newTagsValue = null;
  }
      
  void handleRepeatStrippingButtonClick() {
    LOG.finest("Repeat stripping request for entry $entry.");
    fireRepeatStrippingRequest();
    hideMenuContent();
  }
  
  void handleDeleteButtonClick(event) {
    LOG.finest("Delete button clicked for entry $entry.");
    retardEvent(event);
    fireDeleteRequest();
    hideMenuContent();
  }
   
  void handleAddPdfUrlRequest(event) {
    LOG.finest("Add pdf url request: $pdfUrlValue.");
    retardEvent(event);
    fireAddPdfUrlRequest(pdfUrlValue);
    hideMenuContent();
    pdfUrlValue = null;
  }
      
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
    Element menuToggle = get("menu-toggle");
    DivElement menuContent = get("menu-content");
        
    menuContent.classes.remove("above");
    menuContent.classes.remove("below");
    
    menuContent.style.display = "block";
            
    // Positionize the menu body. Check, if the content fits below the 
    // menu toggle. Otherwise, positionize it above the toggle.
    var windowHeight = window.innerHeight;
    var menuToggleBottom = menuToggle.getBoundingClientRect().bottom;
    var menuContentHeight = menuContent.getBoundingClientRect().height;
    var menuContentBottom = menuToggleBottom + menuContentHeight;
    
    if (menuContentBottom < windowHeight) {
      // The menu fits below the menu toggle.
      menuContent.classes.add("below");
    } else {
      // The menu doesn't fit below the menu toggle. Positionize it above the 
      // toggle.
      menuContent.classes.add("above");
    }          
  }
  
  void hideMenuContent() {
    get("menu-content").style.display = "none";
  }
  
  // ___________________________________________________________________________
  // Fire methods.
  
  /// Fires a tag-deleted event.
  void fireImportRequest(MenuItemElement button) {
    fire(IceciteRequest.IMPORT_ENTRY, detail: entry);
  }
  
  /// Fires a tag-added event.
  void fireNewTagsRequest(String tag) {
    fire(IceciteRequest.NEW_TAGS, detail: {'entry': entry, 'tag': tag});
  }
    
  /// Fires an repeat-stripping request.
  void fireRepeatStrippingRequest() {    
    fire(IceciteRequest.REPEAT_STRIPPING, detail: entry);
  }
  
  /// Fires an entry-deleted event.
  void fireDeleteRequest() {    
    fire(IceciteRequest.DELETE_ENTRY, detail: entry);
  }
  
  /// Fires an add-pdf-url request.
  void fireAddPdfUrlRequest(String url) {    
    fire(IceciteRequest.ADD_PDF_URL, detail: {'entry': entry, 'url': url});
  }
}