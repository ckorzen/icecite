library location_util;

import 'dart:html';
import 'package:polymer/polymer.dart';
import '../../properties.dart';

/// The locations of Icecite.
class Location {
  final String name;
  const Location._internal(this.name);
  
  static const LIBRARY = const Location._internal(LOCATION_NAME_LIBRARY);
  static const REFERENCES = const Location._internal(LOCATION_NAME_REFERENCES);
  static const FEED = const Location._internal(LOCATION_NAME_FEEDS);
  static const UNKNOWN = const Location._internal(null);
  
  toString() => name;
  
  static Map<String, Location> map = {
    LIBRARY.name: LIBRARY,
    REFERENCES.name: REFERENCES,
    FEED.name: FEED
  };
    
  static Location get(String name) {
    return map[name];
  }
}

/// Class to manage the urls of Icecite.
class LocationUtil extends Observable {  
  /// Returns the url of library.
  static String getLibraryUrl({String entryId: null, String query: null, 
      List<String> tags}) {
    // Keep the q parameter.
    Map params = getUrlParams(window.location.href);
    if (entryId != null && entryId.isNotEmpty) params['id'] = entryId;
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (tags != null && tags.isNotEmpty) params['t'] = listToParam(tags);
    String url = window.location.href.split('?')[0].split('#')[0];
    String urlWithLocation = "$url#${Location.LIBRARY}";
    String paramsStr = createParamsString(params);
    return urlWithLocation + (paramsStr.isNotEmpty ? "?${paramsStr}" : "");
  }
  
//  /// Returns the url of entry.
//  static String getEntryUrl(String entryId, {String query: null}) {
//    Map params = getUrlParams(window.location.href);
//    if (entryId != null && entryId.isNotEmpty) params['id'] = entryId;
//    if (query != null && query.isNotEmpty) 
//      params['q'] = query;
//    else
//      params.remove('q');
//    String url = window.location.href.split('?')[0].split('#')[0];
//    String urlWithLocation = "$url#${Location.REFERENCES}";
//    String paramsStr = createParamsString(params);
//    return urlWithLocation + "?${paramsStr}";
//  }
//  
//  /// Returns the feed url.
//  static String getFeedUrl(String entryId, {String query: null}) {
//    Map params = getUrlParams(window.location.href);
//    if (entryId != null && entryId.isNotEmpty) params['id'] = entryId;
//    if (query != null && query.isNotEmpty) 
//      params['q'] = query;
//    else
//      params.remove('q');
//    String url = window.location.href.split('?')[0].split('#')[0];
//    String urlWithLocation = "$url#${Location.FEED}";
//    String paramsStr = createParamsString(params);
//    return urlWithLocation + "?${paramsStr}";
//  }
  
  /// Adds the query parameter to current location.
  static String addParameter({String searchQuery, List<String> tags}) {
    Map params = getUrlParams(window.location.href);
    if (searchQuery != null && searchQuery.isNotEmpty) params['q'] = searchQuery;
    if (tags != null && tags.isNotEmpty) params['t'] = listToParam(tags);
    String url = window.location.href.split('?')[0];
    String paramsStr = createParamsString(params);
    return "${url}?${paramsStr}";
  }
    
  /// Adds the query paramater to current location.
  static String removeParameter({bool searchQuery: false, bool tags: false}) {
    Map params = getUrlParams(window.location.href);
    if (searchQuery) params.remove('q');
    if (tags) params.remove('t');
    String url = window.location.href.split('?')[0];
    String paramsStr = createParamsString(params);
    return url + (paramsStr.isNotEmpty ? "?${paramsStr}" : "");
  }
  
  /// Creates a string from given parameters.
  static String createParamsString(Map params) {
    StringBuffer sb = new StringBuffer();
    int i = 0;
    for (String key in params.keys) {
      if (i > 0) sb.write("&");
      sb.write("${key}=${params[key]}");
      i++;
    }
    return sb.toString();
  }
  
  /// Extracts the parameters from given url to map.
  static Map getUrlParams(String path) {
    Map params = {};
    if (path != null) {
      List<String> urlParts = path.split("?");
      if (urlParts.length > 1) {
        String paramsStr = urlParts.last; 
        Iterable list = paramsStr.split("&").map((e) => e.split("="));
        list.forEach((piece) => params[piece[0]] = piece[1]); 
      }
    }
    return params;
  }
  
  /// Extracts the location from given url.
  static Location getLocation(String url) {
    if (url != null) {
      int index1 = url.indexOf('#');
      if (index1 > -1) {
        int index2 = url.indexOf('?', index1);
        var name = url.substring(index1 + 1, index2 > -1 ? index2 : url.length);
        return Location.get(name);
      }
    }
    return Location.UNKNOWN;
  }
  
  static String listToParam(List<String> list, {String delimiter: ";"}) {
    if (list == null) return null;
    return list.join(delimiter);
  }
  
  static List<String> paramToList(String paramValue, {String delimiter: ";"}) {
    if (paramValue == null) return null;
    return paramValue.split(delimiter);
  }
}