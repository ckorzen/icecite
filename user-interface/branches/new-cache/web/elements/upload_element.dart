library upload_element;

import 'dart:html' hide Notification;
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';

/// The uploader of Icecite.
@CustomTag('upload-element')
class UploadElement extends IceciteElement {
  @observable String url;  
  
  // Internal variables.
  FileUploadInputElement uploader;
  HtmlElement uploaderWrapper;
  HtmlElement uploadElement;
  HtmlElement dropMaskElement;
  
  /// The dropdown is focusesd on displaying it. On blurring, the dropdown 
  /// will be hid. Because the dropdown is losing focus on clicking
  /// a textbox in dropdown, we introduce a flag, that is set on mousedown
  /// on dropdown (mousedown is fired before blur). This flag indicates, 
  /// whether an element of the dropdown was clicked. On blurring, this
  /// flag is checked. If true, the dropdown won't be hid. Otherwise, it
  /// will be hid. 
  bool isDropdownActive = false;
  
  // The name of "files-upload" event
  static const String UPLOAD_FILES_REQUEST = "upload-files-request";
  // The name of "url-upload" event
  static const String UPLOAD_URL_REQUEST = "upload-url-request";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  UploadElement.created() : super.created();
       
  @override
  void reset() {
    super.reset();
    hideUploadDropdownMenu();
  }
    
  // ___________________________________________________________________________
  // Handlers.
    
  /// This method is called, whenever the view was revealed.
  void onRevealed() => handleRevealed();
  
  /// This method is called, whenever a file is dragged over the upload.
  void onDraggedOver(event) => handleDraggedOver(event);
  
  /// This method is called, whenever a drag ends (outside of the upload).
  void onDragEnded(event) => handleDragEnded(event);
    
  /// This method is called, whenever a file is dragged over the upload.
  void onDragEntered(event) => handleDragEntered(event);
  
  /// This method is called, whenever a dragged file leaves the upload area.
  void onDragLeaved(event) => handleDragLeaved(event);
    
//  /// This method is called, whenever a file is dropped into the upload area.
//  void onDropped(event) => handleDropped(event);
       
  /// This method is called, whenever files were uploaded.
  void onUploadButtonClicked(event) => handleUploadButtonClicked(event);
       
  /// This method is called, whenever a url was committed.
  void onUrlCommitted(event, detail, target) => handleUrlCommitted(event);
  
  /// This method is called, whenever a commit of new url was cancelled.
  void onUrlCommitCancelled(event) => handleUrlCommitCancelled(event);
  
  /// This method is called, whenever the dropdown button is clicked.
  void onShowDropdownButtonClicked(event) => 
      handleShowDropdownMenuButtonClicked(event);
  
  void onCloseDropdownButtonClicked(event) => 
      handleCloseDropdownMenuButtonClicked(event);
  
  void onDropdownMousedown(event) => handleDropdownMousedown(event);
  
  void onDropdownMouseup(event) => handleDropdownMouseup(event);
  
  void onDropdownBlur(event) => handleDropdownBlur(event);
  
  void onDropdownInputBlur(event) => handleDropdownInputBlur(event);
  
  // ___________________________________________________________________________
  // Private actions. 
  
  /// Reveals the element of this view.
  void handleRevealed() {
    this.uploadElement = get("upload");
    this.dropMaskElement = get("upload-dropmask");
    this.uploaderWrapper = get("uploader-wrapper");
    this.uploader = createNewFileUploadInputElement();
    if (this.uploaderWrapper != null) {
      this.uploaderWrapper.children.clear();
      this.uploaderWrapper.children.add(uploader);
    }
  }
  
  /// This method is called, whenever a file is dragged over the upload.
  void handleDraggedOver(MouseEvent event) {
    retardEvent(event);
    event.dataTransfer.dropEffect = 'copy';
  }
  
  /// This method is called, whenever a drag ends (outside of the upload).
  void handleDragEnded(MouseEvent event) {  
    retardEvent(event);
    uploadElement.classes.remove('over');
    dropMaskElement.style.display = "none";
  }
  
  /// This method is called, whenever a file is dragged over the upload.
  void handleDragEntered(MouseEvent event) {
    retardEvent(event);
    uploadElement.classes.add('over');
    dropMaskElement.style.display = "block";
  }
  
  /// This method is called, whenever a dragged file leaves the upload area.
  void handleDragLeaved(var event) {
    retardEvent(event);
    uploadElement.classes.remove('over');
    dropMaskElement.style.display = "none";
  }
  
//  /// This method is called, whenever a file is dropped into the upload area.
//  void handleDropped(var event) {
//    retardEvent(event);
//    uploadElement.classes.remove('over');
//    dropMaskElement.style.display = "none";
//    DataTransferItemList list = event.dataTransfer.items;
//    if (list != null && list.length > 0) {
//      DataTransferItem item = list[0];
//      if (item != null && item.kind == 'string') {
//        item.getAsString().then((url) => handleUrlCommitted(null, url));
//      }
//    }
//  }
  
  /// Handles a click on upload button. 
  void handleUploadButtonClicked(Event event) {
    retardEvent(event);
    // We don't want to show the original input form, but a single button.
    // For that, we have to listen to click events to the button and to forward
    // them to the the form.
    simulateUploaderClick();
  }
  
  /// Handles an url commit. 
  void handleUrlCommitted(Event event) {
    retardEvent(event);
    if (url == null || url.trim().isEmpty) return;
    if (!url.endsWith(".pdf")) return;
    // Hide the dropdown.
    hideUploadDropdownMenu();
    // Fire "url-upload" event.
    fireUrlUploadEvent(url);
    url = null;
  }
  
  /// Handles a cancellation of url update. 
  void handleUrlCommitCancelled(Event event) {
    retardEvent(event);
    // Hide the dropdown.
    hideUploadDropdownMenu();
  }
  
  /// Handles a click on close dropdown button.
  void handleCloseDropdownMenuButtonClicked(Event event) {
    retardEvent(event);
    // Hide the dropdown.
    hideUploadDropdownMenu();
  }
  
  /// Handles a click on show dropdown button. 
  void handleShowDropdownMenuButtonClicked(Event event) {
    // Show the dropdown, if it is hidden and hide it otherwise.
    displayUploadDropdownMenu();
    get("dropdown").focus();
  }
   
  void handleDropdownMouseup(event) {
    this.isDropdownActive = false;
  }
    
  void handleDropdownMousedown(event) {
    this.isDropdownActive = true;
  }
    
  void handleDropdownBlur(event) {
    if (!isDropdownActive) hideUploadDropdownMenu();
  }
    
  void handleDropdownInputBlur(event) {
    if (!isDropdownActive) hideUploadDropdownMenu();
  }
  
  // ___________________________________________________________________________
  
  /// Simulates an uploader click.
  void simulateUploaderClick() {
    if (uploader != null) uploader.click();
  }
    
  /// Uploads the given files.
  void upload() {
    if (uploader != null) fireFilesUploadEvent(uploader.files);
    this.uploader = createNewFileUploadInputElement();
    this.uploaderWrapper.children.clear();
    this.uploaderWrapper.children.add(this.uploader);
  }
   
  void toggleUploadDropdownMenu() {
    if (isUploadDropdownMenuHidden()) displayUploadDropdownMenu();
    else hideUploadDropdownMenu();
  }
  
  /// displays the dropdown menu.
  void displayUploadDropdownMenu() {
    get("dropdown").style.display = "block";      
  }
  
  /// Hides the dropdown menu.
  void hideUploadDropdownMenu() {
    get("dropdown").style.display = "none";
  }
    
  /// Hides the dropdown menu.
  bool isUploadDropdownMenuHidden() {
    return get("dropdown").style.display == "none";
  }
  
  // ___________________________________________________________________________
  // Helpers.
  
  /// Creates a new file upload input element.
  FileUploadInputElement createNewFileUploadInputElement() {
    FileUploadInputElement uploader = new FileUploadInputElement();
    uploader.classes.add("upload-input");
    uploader.onChange.listen((e) => upload());
    uploader.multiple = true;
    return uploader;
  }
  
  // ___________________________________________________________________________
  
  /// Fires a "files-upload" event.
  void fireFilesUploadEvent(List<File> files) {
    fire(UPLOAD_FILES_REQUEST, detail: files);
  }
  
  /// Fires a "url-upload" event.
  void fireUrlUploadEvent(String url) {
    fire(UPLOAD_URL_REQUEST, detail: url);
  }
}