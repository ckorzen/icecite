// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_RECORD_H_
#define DBLPMATCHING_RECORD_H_

#include <string>
#include <vector>

using std::string;
using std::vector;

class Record {
 public:
  void setTitle(const string& recordTitle);

  void setAuthors(const string& recordAuthors);

  string key;
  string authors;
//  vector<string> authorWords;
  string normalizedAuthors;
  string year;
  string title;
//  vector<string> titleWords;
  string normalizedTitle;
  string journal;
  string pages;
  string ee;
  string url;
};

#endif  // DBLPMATCHING_RECORD_H_
