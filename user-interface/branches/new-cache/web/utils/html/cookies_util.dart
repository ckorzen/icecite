library cookies_util;

import 'dart:html';
import 'package:logging/logging.dart';

/// The logger.
Logger LOG = new Logger("cookies-util");

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
  LOG.finer("Created cookie: $cookie");
}
  
/// Reads a cookie.
String readCookie(String name) {
  String nameEQ = name + '=';
  List<String> ca = document.cookie.split(';');
  for (int i = 0; i < ca.length; i++) {
    String c = ca[i].trim();
    if (c.indexOf(nameEQ) == 0) {
      String value = c.substring(nameEQ.length).trim();
      if (value.isNotEmpty) {
        LOG.finer("Readed cookie: $value");
        return value;
      }
    }
  }
  LOG.finer("No cookie found.");
  return null;  
}
  
/// Deletes a cookie.
void deleteCookie(String name) {
  LOG.finer("Deleting cookie $name");
  createCookie(name, '', null);
}