// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <string>
#include "./InvertedIndexRecordMatcher.h"
#include "./RecordMatcherSocket.h"

// _____________________________________________________________________________
int main(int argc, char** argv) {
  std::string baseName;
  int port;

  if (argc == 3) {
    port = atoi(argv[1]);
    baseName = argv[2];
  } else {
    printf("Usage: ./RecordMatcherSocketMain <port> <baseName>");
    exit(1);
  }

  InvertedIndexRecordMatcher invertedIndexRecordMatcher;
  invertedIndexRecordMatcher.readRecordsFromFile(baseName);

  RecordMatcherSocket socket;
  socket.start(port, &invertedIndexRecordMatcher, baseName);
}
