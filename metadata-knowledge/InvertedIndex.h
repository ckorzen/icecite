// Copyright 2013, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_INVERTEDINDEX_H_
#define DBLPMATCHING_INVERTEDINDEX_H_

#include <google/dense_hash_map>
#include <string>
#include <vector>
#include "./RecordMatcherUtil.h"
#include "./Record.h"

using google::dense_hash_map;
using std::string;
using std::ifstream;

// Base class for an Inverted Index. Inverted Index has form:
// term1 -> doc1, doc2, doc3, ...
// term2 -> doc3, doc5, ...
// ...
class InvertedIndex {
 public:
  // Default constructor
  InvertedIndex() {
    _invertedIndex.set_empty_key("");
  }

  // public method to build the inverted index. Checks, if serialized file
  // or records-file are given, to deserialize / build the index faster.
  // The given basename specify the files, to read/write from and the given
  // dblpPath specify the path to dblp.xml). Method will will fill a map,
  // that maps id's to records
  void build(const string& baseName);

  // Adds id (identifies according record) for given term to inverted index.
  void add(const string& term, int id);

  // Adds entire list for given term to inverted index.
  void add(const string& term, const vector<int>& list);

  // Serializes the inverted index. (Writes inverted index to file)
  void serialize(const string& baseName);
  FRIEND_TEST(InvertedIndex, serialize);

  // Deserializes the inverted index (Reads inverted index from file, specified
  // by basename)
  void deserialize(const string& baseName);
  FRIEND_TEST(InvertedIndex, deserialize);

  // Returns pointer to the inverted list for given term
  void get(const string& term, vector<int>** list);

  // Check, if invertedIndex is empty
  bool empty();

  // Returns the according record for given id
  void resolveId(int id, Record** record);

  size_t size() {
    return _invertedIndex.size();
  }

 private:
  // Builds inverted index.
  void buildIndex(const string& baseName);
  FRIEND_TEST(InvertedIndex, buildIndex);

  // Reads the records from file, specified by basename
  void readRecordsFile(const string& baseName);
  FRIEND_TEST(InvertedIndex, readRecordsFile);

  // Create a simple file with records from dblp of two columns: key TAB title
  void createRecordsFile(const string& baseName);
  FRIEND_TEST(InvertedIndex, createRecordsFile);

  // The underlying object of inverted index.
  // We map a string (=term) to the id of document
  dense_hash_map<string, vector<int> > _invertedIndex;

  // The records in memory.
  vector<Record> _records;
};

#endif  // DBLPMATCHING_INVERTEDINDEX_H_
