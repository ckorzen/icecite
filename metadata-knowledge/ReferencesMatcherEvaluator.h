// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_REFERENCESMATCHEREVALUATOR_H_
#define DBLPMATCHING_REFERENCESMATCHEREVALUATOR_H_

#include <string>
#include <utility>
#include <vector>
#include "./RecordMatcherBase.h"

using std::string;
using std::pair;
using std::vector;

// Class for evaluating various record matching algorithms.
class ReferencesMatcherEvaluator {
 public:
  // Evaluate given algorithm on given queries against given ground truth.
  // Queries + ground truth are given in file <base name>.qrels
  // (one line per query with two TAB-separated columns:
  // query TAB record key). Write result to file <base name>.evaluation
  // (one line per query with TAB-separated columns:
  // [YES or NO] TAB query).
  void evaluate(RecordMatcherBase* recordMatcher, const string& type);

 private:
  // Read file with given name to read the ground truth
  void readGroundTruth(const string& baseName);

  // Object for the ground truth
  vector<pair<string, string> > _groundTruth;
};

#endif  // DBLPMATCHING_REFERENCESMATCHEREVALUATOR_H_
