library search_util;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import '../../properties.dart' as prop;
import '../../models/models.dart';

/// Searches the databases.
Future<List> search(String searchQuery) {
  Completer completer = new Completer();
  String query = _prepareSearchQuery(searchQuery);
  String url = prop.SEARCH_URL(query);
    
  if (searchQuery == null || searchQuery.isEmpty) {
    return new Future.value([]);
  }
    
  HttpRequest request = new HttpRequest();
  request.open('GET', url, async: true);
  request.timeout = 30000;
  request.onLoad.listen((e) {
    // Note: file:// URIs have status of 0.
    if ((request.status >= 200 && request.status < 300) ||
        request.status == 0 || request.status == 304) {
      completer.complete(_toEntries(request.responseText));
    } else {
      completer.completeError(e);
    }
  });
  request.onTimeout.listen((e) => completer.completeError("timeout"));
  request.onError.listen((e) => completer.completeError);
  request.send();
  return completer.future;
}
  
/// Prepares the search query, i.e. appends "*" to each word.
String _prepareSearchQuery(String searchTerm) {
  if (searchTerm != null && searchTerm.trim().isNotEmpty) {
    StringBuffer buffer = new StringBuffer();
    List<String> words = searchTerm.split(" ");
    for (int i = 0; i < words.length; i++) {
      String word = words[i].trim().toLowerCase();
      if (word.isNotEmpty) {
        if (buffer.length > 0) buffer.write(" ");
        buffer.write("$word*");}
    }
    return Uri.encodeQueryComponent(buffer.toString());
  }
  return null;
}
  
/// Transforms the response of digital library to list of entries.
List<LibraryEntry> _toEntries(String res) {
  List entries = [];
  Map map = JSON.decode(res);
  Map result = map != null ? map['result'] : null;
  Map hitsWrapper = result != null ? result['hits'] : null;
  var hits = hitsWrapper != null ? hitsWrapper['hit'] : null;
  if (hits != null) {
    // Transform the hits to list, if it consists of a single element.
    if (!(hits is Iterable)) hits = [hits];
    for (var hit in hits) {
      if (hit != null && hit is Map) {
        Map extract = {};
        var content = hit['title'];
        if (content != null && content is Map) {
          // Extract the title and ee.
          var titleWrapper = content['dblp:title'];
          if (titleWrapper != null && titleWrapper is Map) {
            extract['ee'] = titleWrapper['@ee'];
            extract['title'] = titleWrapper['text'];
          }
          // Extract the authors.
          var authors = content['dblp:authors'];
          // Extract the authors. Could be a string (if only one author).
          if (authors != null && authors is Map) {
            var author = authors['dblp:author'];
            extract['authors'] = (author is List) ? author : [author];    
          }
          // Extract the venue.
          var venueWrapper = content['dblp:venue'];
          if (venueWrapper != null && venueWrapper is Map) {
            extract['journal'] = venueWrapper['text'];
          }
          // Extract the year.
          var year = content['dblp:year'];
          if (year != null) {
            extract['year'] = year.toString();
          }
        }
        // Extract the url.
        var url = hit['url'];
        if (url != null && url is String) {
          extract['url'] = url;
          // Extract the key from url.
          int index = url.indexOf("bibtex");
          if (index > -1) {
            extract['key'] = url.substring(index + 7);
          }
        }
        entries.add(new LibraryEntry.fromMap(extract));
      }
    }
  }  
  return entries;
}
  
/// Returns true, if the given library entry matches the search filter.
bool filterLibraryEntryByQuery(LibraryEntry entr, String query) {
  if (query == null) return true;
  String term = query.trim().toLowerCase();
  if (term.isEmpty) return true;
  if (entr == null) return false;
  if (entr.title != null && entr.title.toLowerCase().contains(term))
    return true;
  if (entr.authorsStr != null && entr.authorsStr.toLowerCase().contains(term)) 
    return true;
  if (entr.raw != null && entr.raw.toLowerCase().contains(term)) 
    return true;
  return false;      
}  

/// Returns true, if the given library entry matches the search filter.
bool filterFeedEntryByQuery(FeedEntry entry, String query) {
  if (query == null) return true;
  String term = query.trim().toLowerCase();
  if (term.isEmpty) return true;
  if (entry == null) return false;
  if (entry.data != null && entry.data.toLowerCase().contains(term))
    return true;
  return false;      
} 
  
/// Returns true, if the given library entry matches the given topic selection.
bool filterByTopics(LibraryEntry entr, List<String> topicIds) {
  if (topicIds == null || topicIds.isEmpty) return true;
  if (entr == null) return false;
  if (entr.topicIds == null) return false;
  // TODO: Do it more efficiently.
  for (String topicId in topicIds) {
    if (entr.topicIds.contains(topicId)) return true;
  }
  return false;      
}  

/// Returns true, if the given library entry matches the search filter.
bool filterUserByQuery(User user, String filter) {
  if (filter == null) return true;
  String term = filter.trim().toLowerCase();
  if (term.isEmpty) return true;
  if (user == null) return false;
  if (user.lastName != null && user.lastName.toLowerCase().contains(term))
    return true;
  if (user.firstName != null && user.firstName.toLowerCase().contains(term)) 
    return true;
  return false;      
}