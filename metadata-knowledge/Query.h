// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_QUERY_H_
#define DBLPMATCHING_QUERY_H_

#include <string>
#include <vector>
#include <google/dense_hash_map>

using google::dense_hash_map;
using std::string;
using std::vector;

class Query {
 public:
  Query();
  Query(dense_hash_map<string, string>* parameters);

  void init(dense_hash_map<string, string>* parameters);

  dense_hash_map<string, string>* parameters;
//  string type;
//  string raw;
//  vector<string> essentials;
//  string normalized;
};

#endif  // DBLPMATCHING_QUERY_H_
