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
  InputElement.created() : super.created();
  
  /// Initializes the view.
  void enteredView() {
    super.enteredView();
    if (this.value != null) {
      // Select the value in textbox.
      this.setSelectionRange(0, this.value.length);
      this.focus();
    }
    // Listen to blur events. TODO: on-blur="{{ blurAction }}" in html-file 
    // doesn't work (event is not triggered). No idea why.
    this.onBlur.listen((e) => blurHandler(e, null, null));
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever a key-pres event occurred.
  void keypressHandler(event, details, target) {
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
  void keyupHandler(event, details, target) {
    if (event.keyCode == Html.KeyCode.ESC) cancel();
    fireEvents();
  }
  
  /// This method is called, whenever a search event occurred.
  void searchHandler(e) {
    fireEvents(); 
  }
  
  /// This method is called, whenever a click-event occurred.
  void clickHandler(event, details, target) {
    // Don't propagate the click event to parent element.
    event.stopPropagation();
  }
  
  /// This method is called, whenever a blur-event occurred.
  void blurHandler(event, details, target) {
    // TODO: On pressing enter, also blur event is fired and commit is fired 
    // twice.
  //    fire('commit');
  }
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Fires a value-update event.
  void fireEvents() {
    if (timer != null) timer.cancel();
    timer = new Timer(new Duration(milliseconds: 300), () {
      if (value.trim().isEmpty) cancel();
      if (this.prevValue != this.value) {
        fire('value-update');
        this.prevValue = this.value;
      }
    });
  }
  
  /// Cancels the update action.
  void cancel() {
    prevValue = '';
    fire('cancel');
  }
}