import 'dart:html';


/// Returns true, if the first argument is a child of second argument.
bool isChildOf(Element child, Element parent) {    
  if (child != null) {
    if (child == parent) return true;
    var node = child.parentNode;
    while (node != null) {
      if (node == parent) {
        return true;
      }
      node = node.parentNode;
    }
  }
  return false;
}