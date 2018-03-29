library upload_element;

import 'dart:html' hide Notification;
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';

/// The uploader of Icecite.
@CustomTag('upload-element')
class UploadElement extends IceciteElement {
  // Observable variables.
  @observable bool showUploadDropDownMenu = false;
  
  // Internal variables.
  FileUploadInputElement uploader;
  HtmlElement uploaderWrapper;
  HtmlElement uploadElement;
  HtmlElement dropMaskElement;
  
  /// The default constructor.
  UploadElement.created() : super.created();
   
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/upload_element.css"));
  }
  
  void revealedHandler() {
    super.revealedHandler();
    this.uploadElement = get("upload");
    this.dropMaskElement = get("upload-dropmask");
    this.uploaderWrapper = get("uploader-wrapper");
    this.uploader = createNewFileUploadInputElement();
    this.uploaderWrapper.children.clear();
    this.uploaderWrapper.children.add(uploader);
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    this.showUploadDropDownMenu = false;
  }
  
  // ___________________________________________________________________________
  // Handlers.
    
  /// This method is called, whenever a file is dragged over the upload.
  void dragOverHandler(event, details, target) => onDraggedOver(event);
  
  /// This method is called, whenever a drag ends (outside of the upload).
  void dragEndHandler(event, details, target) => onDragEnded(event);
    
  /// This method is called, whenever a file is dragged over the upload.
  void dragEnterHandler(event, details, target) => onDragEntered(event);
  
  /// This method is called, whenever a dragged file leaves the upload area.
  void dragLeaveHandler(event, details, target) => onDragLeaved(event);
    
  /// This method is called, whenever a file is dropped into the upload area.
  void dropHandler(event, details, target) => onDropped(event);
     
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// This method is called, whenever files were uploaded.
  void onSelectPurpose(event, details, target) {
    // We don't want to show the original input form, but a single button.
    // For that, we have to listen to click events to the button and to forward
    // them to the the form.
    if (uploader != null) uploader.click();
  }
    
  /// This method is called, whenever a url was typed into input in dropdown.
  void onUploadViaUrlPurpose(e, d, target) => uploadViaUrl(target.value);
  
  /// This method is called, whenever the dropdown button is clicked.
  void onDropdownPurpose(event, details, target) => displayDropDown();
  
  // ___________________________________________________________________________
  // Handler methods. 
  
  /// This method is called, whenever a file is dragged over the upload.
  void onDraggedOver(var event) {
    event.stopPropagation();
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
  }
  
  /// This method is called, whenever a drag ends (outside of the upload).
  void onDragEnded(var event) {  
    event.stopPropagation();
    event.preventDefault();
    uploadElement.classes.remove('over');
    dropMaskElement.style.display = "none";
  }
  
  /// This method is called, whenever a file is dragged over the upload.
  void onDragEntered(var event) {
    event.stopPropagation();
    event.preventDefault();
    uploadElement.classes.add('over');
    dropMaskElement.style.display = "block";
  }
  
  /// This method is called, whenever a dragged file leaves the upload area.
  void onDragLeaved(var event) {
    event.stopPropagation();
    event.preventDefault();
    uploadElement.classes.remove('over');
    dropMaskElement.style.display = "none";
  }
  
  /// This method is called, whenever a file is dropped into the upload area.
  void onDropped(var event) {
    event.stopPropagation();
    event.preventDefault();
    uploadElement.classes.remove('over');
    dropMaskElement.style.display = "none";
    DataTransferItemList list = event.dataTransfer.items;
    if (list != null && list.length > 0) {
      DataTransferItem item = list[0];
      if (item != null && item.kind == 'string') {
        item.getAsString().then((url) => uploadViaUrl(url));
      }
    }
  }
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Uploads the given files.
  void upload() {
    if (uploader != null) fire('files', detail: uploader.files);
    this.uploader = createNewFileUploadInputElement();
    this.uploaderWrapper.children.clear();
    this.uploaderWrapper.children.add(this.uploader);
  }
  
  /// Uploads the file, given by url.
  void uploadViaUrl(String url) {
    if (url == null || url.trim().isEmpty) return;
    if (!url.endsWith(".pdf")) {
      info("Given url isn't a valid pdf url");
      return;
    }
    showUploadDropDownMenu = false;
    fire("upload-via-url", detail: url);
  }
  
  /// Changes the display state of dropdown menu.
  void displayDropDown() {
    showUploadDropDownMenu = !showUploadDropDownMenu;
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
}