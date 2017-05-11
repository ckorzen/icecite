library button_element;

import 'package:polymer/polymer.dart';

@CustomTag('button-element')
// Our implemenatation of an input field.
class ButtonElement extends PolymerElement {   
  /// The default constructor.
  ButtonElement.created() : super.created() {
    polymerCreated(); // It's important to call this, see 
    // https://www.dartlang.org/docs/tutorials/polymer-intro/#providing-a-script
  }
  
  @override
  void attached() {
    super.attached();
  }
  
  @override
  void ready() {
    for(var i = 0; i < this.children.length; i++){
      print("children: ${this.children[i]}");
    }
  }
}