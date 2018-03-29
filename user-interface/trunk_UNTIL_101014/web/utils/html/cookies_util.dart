library cookies_util;

import 'dart:html';

/// Creates a cookie.
void createCookie(String name, String value, int days) {
  String expires;
  if (days != null)  {
    DateTime now = new DateTime.now();
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(
        now.millisecond + days * 24 * 60 * 60 * 1000);
    expires = '; expires=' + date.toString();    
  } else {
    DateTime then = new DateTime.fromMillisecondsSinceEpoch(0);
    expires = '; expires=' + then.toString();
  }
  var cookie = name + '=' + value + expires + '; path=/';
  document.cookie = name + '=' + value + expires + '; path=/';
}
  
/// Reads a cookie.
String readCookie(String name) {
  String nameEQ = name + '=';
  List<String> ca = document.cookie.split(';');
  for (int i = 0; i < ca.length; i++) {
    String c = ca[i].trim();
    if (c.indexOf(nameEQ) == 0) {
      String value = c.substring(nameEQ.length).trim();
      if (value.isNotEmpty) return value; 
    }
  }
  return null;  
}
  
/// Deletes a cookie.
void deleteCookie(String name) {
  createCookie(name, '', null);
}