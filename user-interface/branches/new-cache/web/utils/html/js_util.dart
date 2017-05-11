library js_util;

import 'dart:js';
import 'dart:convert';

/// Transforms the given js object into a dart object.
dynamic dartify(JsObject object) {
  // Workaround to put the jsObject into map: Encode the jsObject into JSON 
  // (within JS) and decode it again (within dart).
  return JSON.decode(context['JSON'].callMethod('stringify', [object]));
}