// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include "./RecordMatcherUtil.h"
#include "./Record.h"

void Record::setTitle(const string& recordTitle) {
  title = recordTitle;

//  RecordMatcherUtil::normalize(title, &titleWords);
//  RecordMatcherUtil::toString(titleWords,  &normalizedTitle);
//  RecordMatcherUtil::sortAndUniq(&titleWords);
}

void Record::setAuthors(const string& recordAuthors) {
  authors = recordAuthors;

//  RecordMatcherUtil::split(authors, "$", &authorWords);
//  RecordMatcherUtil::toString(authorWords,  &normalizedAuthors);
//  RecordMatcherUtil::sortAndUniq(&authorWords);
}
