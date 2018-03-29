// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <gtest/gtest.h>
#include <stdio.h>
#include <string>
#include <vector>
#include <fstream>
#include "./InvertedIndex.h"

using std::ifstream;
using std::string;
using std::getline;
using std::vector;
using std::stringstream;

// Splits a given string on given delimiter.
void split(const string &s, char delim, vector<string> &elems) {
  stringstream ss(s);
  string item;
  while (getline(ss, item, delim)) {
    elems.push_back(item);
  }
}

// Test constructor of InvertedIndex.
TEST(InvertedIndex, InvertedIndex) {
  InvertedIndex index;

  ASSERT_TRUE(index.empty());
}

// Test InvertedIndex::createRecordsFile.
TEST(InvertedIndex, createRecordsFile) {
  InvertedIndex index;

  // Remove eventually existing records file.
  remove("data/dblp.test.records");

  index.createRecordsFile("data/dblp.test");

  // Open created records-file
  ifstream recordsFile("data/dblp.test.records");

  ASSERT_TRUE(recordsFile.is_open());

  string line;
  getline(recordsFile, line);
  vector<string> elems1;
  split(line, '\t', elems1);
  ASSERT_EQ(elems1.size(), 4);
  ASSERT_EQ(elems1[0], "persons/Codd71a");
  ASSERT_EQ(elems1[1], "E. F. Codd ");
  ASSERT_EQ(elems1[2], "1971");
  ASSERT_EQ(elems1[3], "Further Normalization of the Data Base Relational Model.");

  getline(recordsFile, line);
  vector<string> elems2;
  split(line, '\t', elems2);
  ASSERT_EQ(elems2.size(), 4);
  ASSERT_EQ(elems2[0], "persons/Hall74");
  ASSERT_EQ(elems2[1], "Patrick A. V. Hall ");
  ASSERT_EQ(elems2[2], "1974");
  ASSERT_EQ(elems2[3], "Common Subexpression Identification in General Algebraic Systems.");

  getline(recordsFile, line);
  vector<string> elems3;
  split(line, '\t', elems3);
  ASSERT_EQ(elems3.size(), 4);
  ASSERT_EQ(elems3[0], "persons/Tresch96");
  ASSERT_EQ(elems3[1], "Markus Tresch ");
  ASSERT_EQ(elems3[2], "1996");
  ASSERT_EQ(elems3[3], "Principles of Distributed Object Database Languages.");

  getline(recordsFile, line);
  vector<string> elems4;
  split(line, '\t', elems4);
  ASSERT_EQ(elems4.size(), 4);
  ASSERT_EQ(elems4[0], "persons/CoddD74");
  ASSERT_EQ(elems4[1], "E. F. Codd C. J. Date ");
  ASSERT_EQ(elems4[2], "1974");
  ASSERT_EQ(elems4[3], "Interactive Support for Non-Programmers: The Relational and Network Approaches.");

  ASSERT_FALSE(getline(recordsFile, line));
}

// Test InvertedIndex::readRecordsFile.
TEST(InvertedIndex, readRecordsFile) {
  InvertedIndex index;
  index.readRecordsFile("data/dblp.test");

  ASSERT_EQ(index._records.size(), 4);

  ASSERT_EQ(index._records[0].key, "persons/Codd71a");
  ASSERT_EQ(index._records[0].authors, "E. F. Codd ");
  ASSERT_EQ(index._records[0].year, "1971");
  ASSERT_EQ(index._records[0].title, "Further Normalization of the Data Base Relational Model.");

  ASSERT_EQ(index._records[1].key, "persons/Hall74");
  ASSERT_EQ(index._records[1].authors, "Patrick A. V. Hall ");
  ASSERT_EQ(index._records[1].year, "1974");
  ASSERT_EQ(index._records[1].title, "Common Subexpression Identification in General Algebraic Systems.");

  ASSERT_EQ(index._records[2].key, "persons/Tresch96");
  ASSERT_EQ(index._records[2].authors, "Markus Tresch ");
  ASSERT_EQ(index._records[2].year, "1996");
  ASSERT_EQ(index._records[2].title, "Principles of Distributed Object Database Languages.");

  ASSERT_EQ(index._records[3].key, "persons/CoddD74");
  ASSERT_EQ(index._records[3].authors, "E. F. Codd C. J. Date ");
  ASSERT_EQ(index._records[3].year, "1974");
  ASSERT_EQ(index._records[3].title, "Interactive Support for Non-Programmers: The Relational and Network Approaches.");
}

// Test InvertedIndex::deserialize.
TEST(InvertedIndex, deserialize) {
  ifstream serializedIndex("data/dblp.test.index");
  InvertedIndex index;

  // Check, if a serialized index exists.
  if (!serializedIndex.is_open()) {
    index.build("data/dblp.test");
  }

  // Create fresh instance of InvertedIndex with uninitialized member variables.
  InvertedIndex index2;
  index2.deserialize("data/dblp.test");
}

// Test InvertedIndex::buildIndex.
TEST(InvertedIndex, buildIndex) {
  InvertedIndex index;
  index.readRecordsFile("data/dblp.test");
  index.buildIndex("data/dblp.test");

  ASSERT_EQ(index._invertedIndex.size(), 31);

  //  non  3
  ASSERT_EQ(index._invertedIndex["non"].size(), 1);
  ASSERT_EQ(index._invertedIndex["non"][0], 3);

  //  realtional  0 3
  ASSERT_EQ(index._invertedIndex["relational"].size(), 2);
  ASSERT_EQ(index._invertedIndex["relational"][0], 0);
  ASSERT_EQ(index._invertedIndex["relational"][1], 3);

  //  data  0
  ASSERT_EQ(index._invertedIndex["data"].size(), 1);
  ASSERT_EQ(index._invertedIndex["data"][0], 0);

  //  approaches  3
  ASSERT_EQ(index._invertedIndex["approaches"].size(), 1);
  ASSERT_EQ(index._invertedIndex["approaches"][0], 3);

  //  codd  0 3
  ASSERT_EQ(index._invertedIndex["codd"].size(), 2);
  ASSERT_EQ(index._invertedIndex["codd"][0], 0);
  ASSERT_EQ(index._invertedIndex["codd"][1], 3);

  //  tresch  2
  ASSERT_EQ(index._invertedIndex["tresch"].size(), 1);
  ASSERT_EQ(index._invertedIndex["tresch"][0], 2);

  //  normalization  0
  ASSERT_EQ(index._invertedIndex["normalization"].size(), 1);
  ASSERT_EQ(index._invertedIndex["normalization"][0], 0);

  //  general  0
  ASSERT_EQ(index._invertedIndex["general"].size(), 1);
  ASSERT_EQ(index._invertedIndex["general"][0], 1);

  //  1996  2
  ASSERT_EQ(index._invertedIndex["1996"].size(), 1);
  ASSERT_EQ(index._invertedIndex["1996"][0], 2);

  //  1974  1 3
  ASSERT_EQ(index._invertedIndex["1974"].size(), 2);
  ASSERT_EQ(index._invertedIndex["1974"][0], 1);
  ASSERT_EQ(index._invertedIndex["1974"][1], 3);

  //  distributed 2
  ASSERT_EQ(index._invertedIndex["distributed"].size(), 1);
  ASSERT_EQ(index._invertedIndex["distributed"][0], 2);

  //  patrick 1
  ASSERT_EQ(index._invertedIndex["patrick"].size(), 1);
  ASSERT_EQ(index._invertedIndex["patrick"][0], 1);

  //  common  1
  ASSERT_EQ(index._invertedIndex["common"].size(), 1);
  ASSERT_EQ(index._invertedIndex["common"][0], 1);

  //  database  2
  ASSERT_EQ(index._invertedIndex["database"].size(), 1);
  ASSERT_EQ(index._invertedIndex["database"][0], 2);

  //  network 3
  ASSERT_EQ(index._invertedIndex["network"].size(), 1);
  ASSERT_EQ(index._invertedIndex["network"][0], 3);

  //  principles  2
  ASSERT_EQ(index._invertedIndex["principles"].size(), 1);
  ASSERT_EQ(index._invertedIndex["principles"][0], 2);

  //  programmers 3
  ASSERT_EQ(index._invertedIndex["programmers"].size(), 1);
  ASSERT_EQ(index._invertedIndex["programmers"][0], 3);

  //  support 3
  ASSERT_EQ(index._invertedIndex["support"].size(), 1);
  ASSERT_EQ(index._invertedIndex["support"][0], 3);

  //  1971  0
  ASSERT_EQ(index._invertedIndex["1971"].size(), 1);
  ASSERT_EQ(index._invertedIndex["1971"][0], 0);

  //  algebraic 1
  ASSERT_EQ(index._invertedIndex["algebraic"].size(), 1);
  ASSERT_EQ(index._invertedIndex["algebraic"][0], 1);

  //  interactive 3
  ASSERT_EQ(index._invertedIndex["interactive"].size(), 1);
  ASSERT_EQ(index._invertedIndex["interactive"][0], 3);

  //  hall  1
  ASSERT_EQ(index._invertedIndex["hall"].size(), 1);
  ASSERT_EQ(index._invertedIndex["hall"][0], 1);

  //  markus  2
  ASSERT_EQ(index._invertedIndex["markus"].size(), 1);
  ASSERT_EQ(index._invertedIndex["markus"][0], 2);

  //  base  0
  ASSERT_EQ(index._invertedIndex["base"].size(), 1);
  ASSERT_EQ(index._invertedIndex["base"][0], 0);

  //  languages 2
  ASSERT_EQ(index._invertedIndex["languages"].size(), 1);
  ASSERT_EQ(index._invertedIndex["languages"][0], 2);

  //  model 0
  ASSERT_EQ(index._invertedIndex["model"].size(), 1);
  ASSERT_EQ(index._invertedIndex["model"][0], 0);

  //  identification  1
  ASSERT_EQ(index._invertedIndex["identification"].size(), 1);
  ASSERT_EQ(index._invertedIndex["identification"][0], 1);

  //  subexpression 1
  ASSERT_EQ(index._invertedIndex["subexpression"].size(), 1);
  ASSERT_EQ(index._invertedIndex["subexpression"][0], 1);

  //  systems 1
  ASSERT_EQ(index._invertedIndex["systems"].size(), 1);
  ASSERT_EQ(index._invertedIndex["systems"][0], 1);

  //  date  3
  ASSERT_EQ(index._invertedIndex["date"].size(), 1);
  ASSERT_EQ(index._invertedIndex["date"][0], 3);

  //  for  3
  ASSERT_EQ(index._invertedIndex["for"].size(), 1);
  ASSERT_EQ(index._invertedIndex["for"][0], 3);
}

// Test InvertedIndex::serialize.
TEST(InvertedIndex, serialize) {
  InvertedIndex index;
  index.add("author", 0);
  index.add("author", 2);
  index.add("author", 5);
  index.add("date", 1);
  index.add("date", 3);
  index.add("test", 6);

  index.serialize("data/dblp.test2");

  ifstream serializedIndex("data/dblp.test2.index");
  string line;

  // Test if there is a index file.
  ASSERT_TRUE(serializedIndex.is_open());

  // Test for an entry for the term "test"
  getline(serializedIndex, line);
  vector<string> elems1;
  split(line, '\t', elems1);
  ASSERT_EQ(elems1.size(), 2);
  ASSERT_EQ(elems1[0], "test");
  ASSERT_EQ(elems1[1], "6");

  // Test for an entry for the term "author"
  getline(serializedIndex, line);
  vector<string> elems2;
  split(line, '\t', elems2);
  ASSERT_EQ(elems2.size(), 2);
  ASSERT_EQ(elems2[0], "author");
  ASSERT_EQ(elems2[1], "0 2 5");

  // Test for an entry for the term "date"
  getline(serializedIndex, line);
  vector<string> elems3;
  split(line, '\t', elems3);
  ASSERT_EQ(elems3.size(), 2);
  ASSERT_EQ(elems3[0], "date");
  ASSERT_EQ(elems3[1], "1 3");

  // test if there are no more lines.
  ASSERT_FALSE(getline(serializedIndex, line));
}
