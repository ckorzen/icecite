// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_RECORDMATCHERBASE_H_
#define DBLPMATCHING_RECORDMATCHERBASE_H_

#include <string>
#include <vector>
#include "./Query.h"
#include "./Record.h"

using std::vector;
using std::pair;

// Base class for finding best matching records for given string.
class RecordMatcherBase {
 public:
  // Virtual destructor which does nothing.
  virtual ~RecordMatcherBase() { }

  // Find the (keys of) the best matching records for a given query string.
  virtual void findBestMatchingRecords(const Query& query,
                               vector<pair<int, double> >* recordScores,
                               vector<double>* runTimesInMs) = 0;

  // Read the records and build some internal data structure for fast query
  // matching. The name of the file is <base name>.records (one line per
  // records, two TAB-separated columns per line: key TAB record).
  virtual void readRecordsFromFile(const string& baseName) = 0;

  // Returns the number of documents that contain the given query.
  virtual size_t getNumOfDocuments(const Query& query) = 0;

  // Resolves an id to key.
  virtual void resolveId(int id, Record** record) = 0;

  bool verbose;
};

#endif  // DBLPMATCHING_RECORDMATCHERBASE_H_
