// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_RECORDMATCHERSOCKET_H_
#define DBLPMATCHING_RECORDMATCHERSOCKET_H_

#include <google/dense_hash_map>
#include <string>
#include <vector>
#include <map>
#include "./RecordMatcherBase.h"

using google::dense_hash_map;
using std::string;
using std::endl;
using std::flush;
using std::vector;
using std::map;

class RecordMatcherSocket {
 public:
  RecordMatcherSocket() {
    init();
    printRuntimes = false;
  }

  // Start the server, so that server can handle user's requests
  void start(int port, RecordMatcherBase* recordMatcher,
      const string& baseName);
  bool printRuntimes;
 private:
  // Inits the RecordMatcherSocket.
  void init();

  // Starts the server on given port.
  int startServer(int port);

  // Extracts the parameter (e.g. query by user) from http-request
  void getParameter(const string& http_request,
      dense_hash_map<string, string>* parameter);

  // create the xml-response, shown to user
  void createXMLResponse(const vector<pair<int, double> >& recordScores,
      RecordMatcherBase* recordMatcher, string* response);

  // create the xml-response, shown to user
  void createXMLResponse(size_t numOfHits, string* response);

  string decodeUrl(string& url);

  // xml-encoding for given string
  string xmlEncode(const string& data);

  // Map that maps utf8 hexadecimal values to the unicode codepoints.
  map<string, int> _utf8toUnicodeMap;
};

#endif  // DBLPMATCHING_RECORDMATCHERSOCKET_H_
