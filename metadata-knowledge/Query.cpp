// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <algorithm>
#include <vector>
#include <string>
#include "./RecordMatcherUtil.h"
#include "./Query.h"

using std::string;

Query::Query() {
}

Query::Query(dense_hash_map<string, string>* parameters) {
  init(parameters);
}

void Query::init(dense_hash_map<string, string>* parameters) {
  this->parameters = parameters;
//  this->raw = content;
//
//  RecordMatcherUtil::normalize(raw, &essentials);
//  RecordMatcherUtil::toString(essentials,  &normalized);
//  RecordMatcherUtil::sortAndUniq(&essentials);

//  std::cout << "Query raw: " << raw << std::endl;
//  std::cout << "Query normalized: " << normalized << std::endl;
//  std::cout << "Query essentials: " << essentials << std::endl;

//  this->isBibEntry = isBibEntry;
//  this->type = type;
}
