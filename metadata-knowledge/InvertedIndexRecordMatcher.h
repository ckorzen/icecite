// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_INVERTEDINDEXRECORDMATCHER_H_
#define DBLPMATCHING_INVERTEDINDEXRECORDMATCHER_H_

#include <gtest/gtest.h>
#include <string>
#include <vector>
#include <utility>
#include <map>
#include "./RecordMatcherBase.h"
#include "./InvertedIndex.h"
#include "./RecordMatcherUtil.h"
#include "./RecordMatcherUtil2.h"
#include "./Record.h"
#include "./Query.h"

using std::vector;
using std::string;
using std::pair;


// Simple record matcher that compares the query to each record via a scoring
// function and returns the record with the highest score.
class InvertedIndexRecordMatcher : public RecordMatcherBase {
public:
  InvertedIndexRecordMatcher() {
    verbose = false;
    printRuntimes = false;
  }

  // Find the (key of) the best matching record for the given query string.
  void findBestMatchingRecords(const Query& query,
      vector<pair<int, double> >* recordScores, vector<double>* runTimesInMs);

  // Read records from file and store them in invertedIndex.
  void readRecordsFromFile(const string& baseName);

  // Returns the number of documents that contain the given query.
  size_t getNumOfDocuments(const Query& query);

  // Resolves an id to key.
  void resolveId(int id, Record** record);

  bool verbose;
  bool printRuntimes;
 private:
  // Find top-k candidates for given words (clean words from query)
  void findCandidates(const Query& cleanQueryWords, vector<pair<int, int> >*
      candidates);

  // Scores the given candidates for given query
  void evaluateCandidates(const Query& query, const vector<pair<int, int> >&
      candidates, vector<pair<int, double> >* scores);

  // Determine the matching(s) with best scores
  void findCandidatesWithBestScoring(const Query& query,
      const vector<pair<int, double> >& scores,
      vector<pair<int, double> >* recordScores);

  // Instead of sortFunc, use sortFunctor. A functor can be used in place
  // of a function in many places, and it can carry state (like a reference
  // to the data it needs).
  struct sortFunctor {
    InvertedIndex* invertedIndex;
    sortFunctor(InvertedIndex* index) : invertedIndex(index) { }
    bool operator()(const pair<int, double>& pair1,
        const pair<int, double>& pair2) {
//      if (pair1.second == pair2.second) {
//        Record* record1;
//        Record* record2;
//        vector<string> titleWords1;
//        vector<string> titleWords2;
//
//        invertedIndex->resolveId(pair1.first, &record1);
//        invertedIndex->resolveId(pair2.first, &record2);
//
//        RecordMatcherUtil::normalize(record1->title, &titleWords1);
//        RecordMatcherUtil::normalize(record2->title, &titleWords2);
//
//        return titleWords1.size() < titleWords2.size();
//      }
      return (pair1.second > pair2.second);
    }
  };

  InvertedIndex _invertedIndex;
};

#endif  // DBLPMATCHING_INVERTEDINDEXRECORDMATCHER_H_
