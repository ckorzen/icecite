// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <sys/time.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <google/dense_hash_map>
#include <string>
#include <vector>
#include <sstream>
#include "./RecordMatcherSocket.h"
#include "./InvertedIndexRecordMatcher.h"
#include "./RecordMatcherUtil.h"
#include "./Query.h"

using google::dense_hash_map;
using std::string;
using std::cout;
using std::cerr;
using std::endl;
using std::flush;
using std::stringstream;

// _____________________________________________________________________________
void RecordMatcherSocket::start(int port, RecordMatcherBase* recordMatcher,
    const string& baseName) {
  timeval start, end;
  double timeInMs;
  timeval overallStart, overallEnd;
  double overallTimeInMs;

  cout << "Starting server on port" << port << "..." << flush;
  // Initialize the server
  int socket_server = startServer(port);
  cout << "Done!" << endl;

  int socket_client;
  // Buffer for reading user's request
  char buf[MAX_LINE_LENGTH];

  // listen for socket connections
  listen(socket_server, 5);

  while (true) {
    //    cout << "Waiting for incoming request..." << endl;
    // Accept all incoming requests
    socket_client = accept(socket_server, 0, 0);

    // Check, if request was accepted
    if (socket_client < 0) {
      cerr << "Couldn't accept request" << endl;
      exit(1);
    }
    //    cout << "Request accepted" << endl;

    dense_hash_map<string, string> parameter;
    parameter.set_empty_key("");

    while (read(socket_client, buf, 1024)) {
      gettimeofday(&overallStart, 0);
      gettimeofday(&start, 0);
      // Extract Parameters from request and put them in a map
      getParameter(buf, &parameter);

      // Fetch value for parameter-key "q"
      Query query(&parameter);
      //      if (!parameter["v"].empty()) {
      //        recordMatcher->verbose = (parameter["v"] == "1");
      //      } else {
      //        recordMatcher->verbose = false;
      //      }

      gettimeofday(&end, 0);
      timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
          - start.tv_usec) / 1000.0;

      vector<pair<int, double> > recordScores;
      vector<double> runtimes;
      string response;
      //      cout << "Query: " << quer   y.raw << "isBibEntry: " << query.isBibEntry << endl;
      //      cout << "Verbose: "  << recordMatcher->verbose << endl;
      //      cout << "Essential: " << query.essential << endl;
      if (printRuntimes) {
        cout << "Time needed to initialize parameters and query: " << timeInMs
            << endl;
      }

      gettimeofday(&start, 0);
      dense_hash_map<string, string>::iterator it1 = parameter.find("nt");
      dense_hash_map<string, string>::iterator it2 = parameter.find("na");
      if (it1 != parameter.end() || it2 != parameter.end()) {
        size_t numOfHits = recordMatcher->getNumOfDocuments(query);
        createXMLResponse(numOfHits, &response);
      } else {
        // Process the query: find best matching for query
        //      cout << "+query: " << query.parameters->size() << endl;
        recordMatcher->findBestMatchingRecords(query, &recordScores, &runtimes);
        gettimeofday(&end, 0);
        timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
            - start.tv_usec) / 1000.0;
        if (printRuntimes) {
          cout << "Time needed to find record: " << timeInMs << endl;
        }

        gettimeofday(&start, 0);
        // create the xml-response
        createXMLResponse(recordScores, recordMatcher, &response);
        gettimeofday(&end, 0);
        timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
            - start.tv_usec) / 1000.0;
        if (printRuntimes) {
          cout << "Time needed to create xml response: " << timeInMs << endl;
        }
      }

      gettimeofday(&start, 0);
      // send the response and check, how many bytes were sent
      int bytes = send(socket_client, response.c_str(), response.size(), 0);
      gettimeofday(&end, 0);
      timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
          - start.tv_usec) / 1000.0;
      if (printRuntimes) {
        cout << "Time needed to send the response: " << timeInMs << endl;
      }

      // if all bytes are sent, we can abort reading
      if (response.size() - bytes <= 0) {
        gettimeofday(&overallEnd, 0);
        overallTimeInMs = ((overallEnd.tv_sec - overallStart.tv_sec) * 1000000
            + overallEnd.tv_usec - overallStart.tv_usec) / 1000.0;

        if (printRuntimes) {
          cout << "Overall time needed: " << overallTimeInMs << "ms." << endl;
        }

        break;
      }
    }
    close(socket_client);
  }
}

// _____________________________________________________________________________
int RecordMatcherSocket::startServer(int port) {
  signal(SIGPIPE, SIG_IGN);

  struct sockaddr_in server;
  int socket_server = socket(AF_INET, SOCK_STREAM, 0);

  if (socket_server < 0) {
    cerr << "Couldn't create socket" << endl;
    exit(1);
  }

  // Do some standard settings
  server.sin_family = AF_INET;
  server.sin_addr.s_addr = INADDR_ANY;
  server.sin_port = htons(port);

  // bind socket
  if (bind(socket_server, reinterpret_cast<sockaddr*> (&server),
      sizeof(struct sockaddr_in))) {
    cerr << "bind socket to server_addr" << endl;
    exit(1);
  }

  return socket_server;
}

// _____________________________________________________________________________
void RecordMatcherSocket::createXMLResponse(size_t numOfHits, string* response) {
  stringstream stream;
  stream << "HTTP/1.1 200 OK";
  stream << "\n\n";
  stream << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" << endl;

  stream << "<result hits=\"" << numOfHits << "\">" << endl;
  stream << "</result>";
  stream << "\n";

  *response = stream.str();
}

// _____________________________________________________________________________
void RecordMatcherSocket::createXMLResponse(
    const vector<pair<int, double> >& recordScores,
    RecordMatcherBase* recordMatcher, string* response) {
  stringstream stream;
  stream << "HTTP/1.1 200 OK";
  stream << "\n\n";
  stream << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" << endl;
  // Define xml entities (stolen from dblp.dtd).
  stream << "<!DOCTYPE dblp [" << endl;
  stream << "<!ENTITY uuml    \"&#252;\" >" << endl;
  stream << "<!ENTITY Agrave  \"&#192;\" >" << endl;
  stream << "<!ENTITY Aacute  \"&#193;\" >" << endl;
  stream << "<!ENTITY Acirc   \"&#194;\" >" << endl;
  stream << "<!ENTITY Atilde  \"&#195;\" >" << endl;
  stream << "<!ENTITY Auml    \"&#196;\" >" << endl;
  stream << "<!ENTITY Aring   \"&#197;\" >" << endl;
  stream << "<!ENTITY AElig   \"&#198;\" >" << endl;
  stream << "<!ENTITY Ccedil  \"&#199;\" >" << endl;
  stream << "<!ENTITY Egrave  \"&#200;\" >" << endl;
  stream << "<!ENTITY Eacute  \"&#201;\" >" << endl;
  stream << "<!ENTITY Ecirc   \"&#202;\" >" << endl;
  stream << "<!ENTITY Euml    \"&#203;\" >" << endl;
  stream << "<!ENTITY Igrave  \"&#204;\" >" << endl;
  stream << "<!ENTITY Iacute  \"&#205;\" >" << endl;
  stream << "<!ENTITY Icirc   \"&#206;\" >" << endl;
  stream << "<!ENTITY Iuml    \"&#207;\" >" << endl;
  stream << "<!ENTITY ETH     \"&#208;\" >" << endl;
  stream << "<!ENTITY Ntilde  \"&#209;\" >" << endl;
  stream << "<!ENTITY Ograve  \"&#210;\" >" << endl;
  stream << "<!ENTITY Oacute  \"&#211;\" >" << endl;
  stream << "<!ENTITY Ocirc   \"&#212;\" >" << endl;
  stream << "<!ENTITY Otilde  \"&#213;\" >" << endl;
  stream << "<!ENTITY Ouml    \"&#214;\" >" << endl;
  stream << "<!ENTITY Oslash  \"&#216;\" >" << endl;
  stream << "<!ENTITY Ugrave  \"&#217;\" >" << endl;
  stream << "<!ENTITY Uacute  \"&#218;\" >" << endl;
  stream << "<!ENTITY Ucirc   \"&#219;\" >" << endl;
  stream << "<!ENTITY Uuml    \"&#220;\" >" << endl;
  stream << "<!ENTITY Yacute  \"&#221;\" >" << endl;
  stream << "<!ENTITY THORN   \"&#222;\" >" << endl;
  stream << "<!ENTITY szlig   \"&#223;\" >" << endl;
  stream << "<!ENTITY agrave  \"&#224;\" >" << endl;
  stream << "<!ENTITY aacute  \"&#225;\" >" << endl;
  stream << "<!ENTITY acirc   \"&#226;\" >" << endl;
  stream << "<!ENTITY atilde  \"&#227;\" >" << endl;
  stream << "<!ENTITY auml    \"&#228;\" >" << endl;
  stream << "<!ENTITY aring   \"&#229;\" >" << endl;
  stream << "<!ENTITY aelig   \"&#230;\" >" << endl;
  stream << "<!ENTITY ccedil  \"&#231;\" >" << endl;
  stream << "<!ENTITY egrave  \"&#232;\" >" << endl;
  stream << "<!ENTITY eacute  \"&#233;\" >" << endl;
  stream << "<!ENTITY ecirc   \"&#234;\" >" << endl;
  stream << "<!ENTITY euml    \"&#235;\" >" << endl;
  stream << "<!ENTITY igrave  \"&#236;\" >" << endl;
  stream << "<!ENTITY iacute  \"&#237;\" >" << endl;
  stream << "<!ENTITY icirc   \"&#238;\" >" << endl;
  stream << "<!ENTITY iuml    \"&#239;\" >" << endl;
  stream << "<!ENTITY eth     \"&#240;\" >" << endl;
  stream << "<!ENTITY ntilde  \"&#241;\" >" << endl;
  stream << "<!ENTITY ograve  \"&#242;\" >" << endl;
  stream << "<!ENTITY oacute  \"&#243;\" >" << endl;
  stream << "<!ENTITY ocirc   \"&#244;\" >" << endl;
  stream << "<!ENTITY otilde  \"&#245;\" >" << endl;
  stream << "<!ENTITY ouml    \"&#246;\" >" << endl;
  stream << "<!ENTITY oslash  \"&#248;\" >" << endl;
  stream << "<!ENTITY ugrave  \"&#249;\" >" << endl;
  stream << "<!ENTITY uacute  \"&#250;\" >" << endl;
  stream << "<!ENTITY ucirc   \"&#251;\" >" << endl;
  stream << "<!ENTITY uuml    \"&#252;\" >" << endl;
  stream << "<!ENTITY yacute  \"&#253;\" >" << endl;
  stream << "<!ENTITY thorn   \"&#254;\" >" << endl;
  stream << "<!ENTITY yuml    \"&#255;\" >" << endl;
  stream << "<!ENTITY reg     \"&#174;\" >" << endl;
  stream << "<!ENTITY micro   \"&#181;\" >" << endl;
  stream << "<!ENTITY times   \"&#215;\" >" << endl;
  stream << "]>" << endl;

  stream << "<result hits=\"" << recordScores.size() << "\">" << endl;
  vector<pair<int, double> >::const_iterator it;
  for (it = recordScores.begin(); it != recordScores.end(); it++) {
    Record* record;
    recordMatcher->resolveId(it->first, &record);
    string title = xmlEncode(record->title);
    stream << "<record score=\"";
    stream << it->second;
    stream << "\" key=\"";
    stream << record->key;
    stream << "\" title=\"";
    stream << title;
    stream << "\" authors=\"";
    stream << record->authors;
    stream << "\" year=\"";
    stream << record->year;
    stream << "\" journal=\"";
    stream << record->journal;
    stream << "\" pages=\"";
    stream << record->pages;
    stream << "\" url=\"";
    stream << record->url;
    stream << "\" ee=\"";
    stream << record->ee;
    stream << "\"/>";
    stream << endl;
  }
  stream << "</result>";
  stream << "\n";

  *response = stream.str();
}

// _____________________________________________________________________________
void RecordMatcherSocket::getParameter(const string& http_request,
    dense_hash_map<string, string>* parameter) {
  // example: "http://localhost:9876/?q=some query&r=some other query"
  // http_request = "GET /?q=some%20query&r=some%20other%20query HTTP/1.1 (...)"

  //  cout << "HTTP-Request: " << http_request << endl;

  // find occurrence of "?"
  size_t pos_start_get = http_request.find("?");

  // Continue only if there is a "?" existent
  if (pos_start_get != string::npos) {
    // find second occurence of " "
    size_t pos_end_get = http_request.find("\n", pos_start_get + 1);

    // params = "q=some%20query&r=some%20other%20query HTTP/X.X"
    string params = http_request.substr(pos_start_get + 1,
        pos_end_get - pos_start_get - 10);

    params = decodeUrl(params);

    // in url encoding: " " = "%20"
    // so, we have to replace "%20" with " "
    //    RecordMatcherUtil::replaceAll("%", 3, " ", &params);
    // params = "q=some query&r=some other query"

    vector<string> paramelements;
    RecordMatcherUtil::split(params, "&", &paramelements);

    // paramelements = {"q=some query", "r=some other query"}
    vector<string>::iterator paramsIt;
    for (paramsIt = paramelements.begin(); paramsIt != paramelements.end(); paramsIt++) {
      // split paramelement in key and value
      size_t pos_assign_paramelement = paramsIt->find("=");
      // key = "q" (or "r")
      string key = paramsIt->substr(0, pos_assign_paramelement);
      // value = "some query" (or "some other query")
      string value = paramsIt->substr(pos_assign_paramelement + 1);
      //      cout << "Param: " << key << " : " << value << endl;
      (*parameter)[key] = value;
    }
  }
}

// ____________________________________________________________________________
string RecordMatcherSocket::xmlEncode(const string& data) {
  stringstream ss;

  for (string::const_iterator it = data.begin(); it != data.end(); it++) {
    unsigned char c = (unsigned char) *it;

    switch (c) {
    //      case '&': sRet << "&amp;"; break;
    case '<':
      ss << "&lt;";
      break;
    case '>':
      ss << "&gt;";
      break;
    case '"':
      ss << "&quot;";
      break;
    case '\'':
      ss << "&apos;";
      break;
    default:
      if (c < 32 || c > 127) {
        ss << "&#" << (unsigned int) c << ";";
      } else {
        ss << c;
      }
    }
  }
  return ss.str();
}

// _____________________________________________________________________________
string RecordMatcherSocket::decodeUrl(string& url) {
  string utf8Code;
  string result = "";

  map<string, int>::iterator it;
  for (size_t i = 0; i < url.length(); i++) {
    char ch = url[i];
    if (ch == '%') {
      if (i + 2 >= url.length()) {
        utf8Code.clear();
        break;
      } else {
        // Found a utf8-code.
        utf8Code.append(url.substr(i + 1, 2));
        i += 2;
      }
      // The utf8-code of diacritics starts with "%C3", followed by a further
      // tupel.
      if (utf8Code == "C3") {
        // Proceed, if utf8-code begins with "%C3"
        continue;
      } else {
        it = _utf8toUnicodeMap.find(utf8Code);
        if (it != _utf8toUnicodeMap.end()) {
          ch = static_cast<char> (it->second);
        }
        utf8Code.clear();
      }
    }
    result += ch;
  }
  return result;
}

// _____________________________________________________________________________
void RecordMatcherSocket::init() {
  // Initialize the utf8toUnicodeMap.
  _utf8toUnicodeMap["20"] = 0x0020;
  _utf8toUnicodeMap["C380"] = 0x00C0;
  _utf8toUnicodeMap["C381"] = 0x00C1;
  _utf8toUnicodeMap["C382"] = 0x00C2;
  _utf8toUnicodeMap["C383"] = 0x00C3;
  _utf8toUnicodeMap["C384"] = 0x00C4;
  _utf8toUnicodeMap["C385"] = 0x00C5;
  _utf8toUnicodeMap["C386"] = 0x00C6;
  _utf8toUnicodeMap["C387"] = 0x00C7;
  _utf8toUnicodeMap["C388"] = 0x00C8;
  _utf8toUnicodeMap["C389"] = 0x00C9;
  _utf8toUnicodeMap["C38A"] = 0x00CA;
  _utf8toUnicodeMap["C38B"] = 0x00CB;
  _utf8toUnicodeMap["C38C"] = 0x00CC;
  _utf8toUnicodeMap["C38D"] = 0x00CD;
  _utf8toUnicodeMap["C38E"] = 0x00CE;
  _utf8toUnicodeMap["C38F"] = 0x00CF;
  _utf8toUnicodeMap["C390"] = 0x00D0;
  _utf8toUnicodeMap["C391"] = 0x00D1;
  _utf8toUnicodeMap["C392"] = 0x00D2;
  _utf8toUnicodeMap["C393"] = 0x00D3;
  _utf8toUnicodeMap["C394"] = 0x00D4;
  _utf8toUnicodeMap["C395"] = 0x00D5;
  _utf8toUnicodeMap["C396"] = 0x00D6;
  _utf8toUnicodeMap["C397"] = 0x00D7;
  _utf8toUnicodeMap["C398"] = 0x00D8;
  _utf8toUnicodeMap["C399"] = 0x00D9;
  _utf8toUnicodeMap["C39A"] = 0x00DA;
  _utf8toUnicodeMap["C39B"] = 0x00DB;
  _utf8toUnicodeMap["C39C"] = 0x00DC;
  _utf8toUnicodeMap["C39D"] = 0x00DD;
  _utf8toUnicodeMap["C39E"] = 0x00DE;
  _utf8toUnicodeMap["C39F"] = 0x00DF;
  _utf8toUnicodeMap["C3A0"] = 0x00E0;
  _utf8toUnicodeMap["C3A1"] = 0x00E1;
  _utf8toUnicodeMap["C3A2"] = 0x00E2;
  _utf8toUnicodeMap["C3A3"] = 0x00E3;
  _utf8toUnicodeMap["C3A4"] = 0x00E4;
  _utf8toUnicodeMap["C3A5"] = 0x00E5;
  _utf8toUnicodeMap["C3A6"] = 0x00E6;
  _utf8toUnicodeMap["C3A7"] = 0x00E7;
  _utf8toUnicodeMap["C3A8"] = 0x00E8;
  _utf8toUnicodeMap["C3A9"] = 0x00E9;
  _utf8toUnicodeMap["C3AA"] = 0x00EA;
  _utf8toUnicodeMap["C3AB"] = 0x00EB;
  _utf8toUnicodeMap["C3AC"] = 0x00EC;
  _utf8toUnicodeMap["C3AD"] = 0x00ED;
  _utf8toUnicodeMap["C3AE"] = 0x00EE;
  _utf8toUnicodeMap["C3AF"] = 0x00EF;
  _utf8toUnicodeMap["C3B0"] = 0x00F0;
  _utf8toUnicodeMap["C3B1"] = 0x00F1;
  _utf8toUnicodeMap["C3B2"] = 0x00F2;
  _utf8toUnicodeMap["C3B3"] = 0x00F3;
  _utf8toUnicodeMap["C3B4"] = 0x00F4;
  _utf8toUnicodeMap["C3B5"] = 0x00F5;
  _utf8toUnicodeMap["C3B6"] = 0x00F6;
  _utf8toUnicodeMap["C3B7"] = 0x00F7;
  _utf8toUnicodeMap["C3B8"] = 0x00F8;
  _utf8toUnicodeMap["C3B9"] = 0x00F9;
  _utf8toUnicodeMap["C3BA"] = 0x00FA;
  _utf8toUnicodeMap["C3BB"] = 0x00FB;
  _utf8toUnicodeMap["C3BC"] = 0x00FC;
  _utf8toUnicodeMap["C3BD"] = 0x00FD;
  _utf8toUnicodeMap["C3BE"] = 0x00FE;
  _utf8toUnicodeMap["C3BF"] = 0x00FF;
}
