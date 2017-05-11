// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <string>
#include "./InvertedIndexRecordMatcher.h"
#include "./ReferencesMatcherEvaluator.h"
#include "./TitleMatcherEvaluator.h"
#include "./RecordMatcherSocket.h"

using std::string;

// _____________________________________________________________________________
int main(int argc, char** argv) {
  string dblpFileName;
  string baseName;
  string type;
  int verbose;

  if (argc == 4) {
    type = string(argv[1]);
    baseName = string(argv[2]);
    verbose = atoi(argv[3]);
  } else {
    printf("Usage: ./RecordMatcherEvaluator <type> <baseName> <verbose: 0|1>\n");
    exit(1);
  }

  //  RecordMatcherSocket::connect();
  InvertedIndexRecordMatcher invertedIndexRecordMatcher;
  invertedIndexRecordMatcher.readRecordsFromFile(baseName);
  invertedIndexRecordMatcher.verbose = verbose > 0 ? true : false;

  if (type.find("titles.dblp") == 0 || type.find("titles.medline") == 0) {
    TitleMatcherEvaluator evaluator;
    evaluator.evaluate(&invertedIndexRecordMatcher, type);
  } else {
    ReferencesMatcherEvaluator evaluator;
    evaluator.evaluate(&invertedIndexRecordMatcher, type);
  }
}
