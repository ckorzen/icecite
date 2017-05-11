library tag_element;

import 'dart:html';
import 'icecite_element.dart';
import '../utils/request.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('tag-element')
/// Our implementation of an tag-element.
class TagElement extends IceciteElement {   
  Logger LOG = logging.get("tag-element");
  
  @published String name;
  @published bool removable = false;
  @observable int maxNameLength = 10;
  
  /// The constructor.
  TagElement.created() : super.created();
  
  // ___________________________________________________________________________
  
  /// This method is called, whenever the remove tag button is clicked.
  void onRemoveTagButtonClick(event) => handleRemoveTagButtonClick();
  
  // ___________________________________________________________________________
  
  /// Handles a click on remove tag button.
  void handleRemoveTagButtonClick() {
    fireRemoveTagRequest();
  }
  
  // ___________________________________________________________________________
  
  /// Fires a remove tag request.
  void fireRemoveTagRequest() {
    fire(IceciteRequest.DELETE_TAG, detail: name);
  }
  
}