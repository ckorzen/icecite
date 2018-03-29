library input_element;

import 'dart:html'as Html;
import 'dart:async';
import 'package:polymer/polymer.dart';

@CustomTag('input-element')
// Our implemenatation of an input field.
class InputElement extends Html.InputElement with Polymer, Observable {
  Timer timer;
  String prevValue = "";
  
  /// The default constructor.
  factory InputElement() => new Html.Element.tag('input', 'icecite-input');
   
  /// The default constructor.
  InputElement.created() : super.created() {
    polymerCreated(); // It's important to call this, see 
    // https://www.dartlang.org/docs/tutorials/polymer-intro/#providing-a-script
  }
  
  @override
  void attached() {
    super.attached();
    if (this.value != null) {
      // Select the value in textbox.
      this.setSelectionRange(0, this.value.length);
      this.focus();
    }
    // Listen to blur events. TODO: on-blur="{{ blurAction }}" in html-file 
    // doesn't work (event is not triggered). No idea why.
    this.onBlur.listen((e) => onBlurred(e, null, null));
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever a key-pres event occurred.
  void onKeyPressed(event, details, target) {
    // Listen for enter on keypress but esc on keyup, because
    // IE doesn't fire keyup for enter.
    if (event.keyCode == Html.KeyCode.ENTER) {
      // Don't fire a commit event here, but blur the input field. Otherwise
      // the commit event will be fired twice. Blurring the 
      // field will fire the commit event itself (see blurAction). 
//      this.blur();
      fire('commit');
    }
  }

  /// This method is called, whenever a key-up event occurred.
  void onKeyUpped(event, details, target) {
    if (event.keyCode == Html.KeyCode.ESC) _cancel();
    _fireEvents();
  }
  
  /// This method is called, whenever a search event occurred.
  void onSearched(e) {
    _fireEvents(); 
  }
  
  /// This method is called, whenever a click-event occurred.
  void onClicked(event, details, target) {
    // Don't propagate the click event to parent element.
    event.stopPropagation();
  }
  
  /// This method is called, whenever a blur-event occurred.
  void onBlurred(event, details, target) {
    // TODO: On pressing enter, also blur event is fired and commit is fired 
    // twice.
  //    fire('commit');
  }
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Fires a value-update event.
  void _fireEvents() {
    if (timer != null) timer.cancel();
    timer = new Timer(new Duration(milliseconds: 300), () {
      if (value.trim().isEmpty) _cancel();
      if (this.prevValue != this.value) {
        fire('value-updated');
        this.prevValue = this.value;
      }
    });
  }
  
  /// Cancels the update action.
  void _cancel() {
    prevValue = '';
    fire('cancel');
  }
}