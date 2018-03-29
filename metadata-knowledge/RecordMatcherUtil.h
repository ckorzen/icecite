// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#ifndef DBLPMATCHING_RECORDMATCHERUTIL_H_
#define DBLPMATCHING_RECORDMATCHERUTIL_H_

#include <gtest/gtest.h>
#include <string>
#include <vector>
#include <utility>
#include <map>
#include "./RecordMatcherBase.h"
#include "./InvertedIndex.h"
#include "./Record.h"
#include "./Query.h"

using std::vector;
using std::string;
using std::pair;
using std::map;

// name of file, containing stopwords
const std::string stopWordsFileName = "stopwords";
// Maximal possible length for a line to parse
const int MAX_LINE_LENGTH = 4096;
const int MAX_LINE_LENGTH_INDEX = 2000000;
// Minimal length, a word must have for adding it to inverted index
const size_t MIN_WORD_LENGTH_INDEX = 2;
// The stopwords as vector
static vector<string> _stopWords;
static const char specialChars[] = {'!', '\"', '$', '%', '&', '/', '(',
  ')', '=', '?', '^', '{', '[', ']', '}', '\\', '*', '+', '~', '\'', '#',
  ';', ',', ':', '.', '-', '_', '@', '<', '>', '|', ' ', '\n', '\t'}; // NOLINT
//// Maximal possible length for a line to parse
// const int MAX_LINE_LENGTH = 4096;
// Minimal length, a word must have for adding it to inverted index
// const int MIN_WORD_LENGTH_INDEX = 2;
// Possible doctypes
const std::string doctypes[] = {"<article", "<inproceedings", "<book",
                                "<phdthesis", "<mastersthesis",
                                "<incollection", "<medline",
                                "<pubmed-not-medline", "<oldmedline" }; // NOLINT
// Take <NUM_CANDIDATES>-best matching to find the best matching
const int NUM_CANDIDATES = 50;

// E.g. if = 0.5, edit distance between record and query have to be
// <= 0.5 * query-length to consider the record as candidate for match
const double MAX_DISTANCE_FACTOR = 0.5;

const double MINIMAL_WORD_COVERING = 0.7;

const std::string FILE_EXTENSION_XML = ".xml";
const std::string FILE_EXTENSION_QRELS = ".qrels";
const std::string FILE_EXTENSION_INDEX = ".index";
const std::string FILE_EXTENSION_RECORDS = ".records";
const std::string FILE_EXTENSION_EVALUATION = ".evaluation";

const double MIN_TITLE_SCORE = 0.55;
const double MIN_AUTHOR_SCORE = 0.5;


// Helper class for helpful functions for finding Best Matching for given query
class RecordMatcherUtil {
 public:
  static string decodeHtml(const string& input);

  // Prepare a string array for given string to our needs, that means:
  // * Split the string in its words
  // * Transform the chars of words to lowercase
  // * Remove leading and trailing punctuation in of every word
  // * Remove the stopwords
  static void normalize(const string& input, vector<string>* output);

  static void sortAndUniq(vector<string>* input);

  static void toString(const vector<string>& input, string* output);

  // Merge lists sets with occurences and sort the merged list by this
  // occurences.
  // Returns a map<int1, int2> where int1 is the key, and int2 the number
  // of occurences.
  // Example: {1,2,3}, {2,3,4} and {3,4,5} get merged to a map
  // {1->1, 2->2, 3->3, 4->2, 5->1}
  // 4->2 means, that number "4" was found 2 times in all sets.
  // 3->3 means, that number "3" was found 3 times in all sets, and so on
  static void mergeAndSortByOccurrences(const vector<vector<int>* >& lists,
      size_t k, vector<int>* target);

  static void mergeAndSortByOccurrencesNew(const vector<vector<int>* >& lists,
        size_t k, vector<int>* target);

  // Compute the local alignment-score between the 2 given strings
  // (via Smith-Waterman)
  static double localAlignment(const string& string1,
      const string& string2, int pos_begin);

  // Compute the local alignment-score between the 2 given strings
  // (via Smith-Waterman)
  static double levensthein(const string& string1,
        const string& string2);

  // Compute the word covering of given set of words to a given string
  // E.g.: query = "The sun is shining"; candidateWords = {sun, moon, the}
  // Word-Covering is 2/3, because: candidateWords contains 3 words and 2 of
  // them appear in query.
  static double computeWordCovering(const string& query,
      const vector<string>& candidateWords, int* indexOfLastAuthor);

  // Splits the given string at given separator ans stores the resulting sub-
  // strings to results
  static void split(const string& str, const string& separator,
      vector<string>* results);

  // Replaces all occurrences of "toRemove" by "toInsert" in "stringToTransform"
  static void replaceAll(const string& toRemove, int length,
      const string& toInsert, string* stringToTransform);

 private:
  // Check, if given word is a stopword
  FRIEND_TEST(RecordMatcherUtil, isStopWord);
  static bool isStopWord(const string& word);

  // Read all stopwords from given file
  static void readStopWordsFromFile();

  static bool isNumber(const string& s);

  static void makeDiacriticsToBasicMap();
  static void makeHtmlEntitiesToCharMap();
};

class ComparePairs {
 public:
  bool operator()(const pair<int, int>& x, const pair<int, int>& y) const {
    if (x.first != y.first) {
      return (x.first > y.first);
    } else {
      return (x.second > y.second);
    }
  }
};

class CompareListsBySize {
 public:
  bool operator()(vector<int>* x, vector<int>* y) const {
    return (x->size() > y->size());
  }
};

#endif  // DBLPMATCHING_RECORDMATCHERUTIL_H_
