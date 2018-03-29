#ifndef RECORDMATCHERUTIL2_H_
#define RECORDMATCHERUTIL2_H_

#include <gtest/gtest.h>
#include <string>
#include <vector>
#include <utility>
#include "./RecordMatcherBase.h"
#include "./InvertedIndex.h"
#include "./Record.h"
#include "./Query.h"

using std::vector;
using std::string;
using std::pair;

// name of file, containing stopwords
const std::string stopWordsFileName2 = "stopwords";
// The stopwords as vector
static vector<string> _stopWords2;

class RecordMatcherUtil2 {
public:
//  static void mergeAndSortByOccurrences(InvertedIndex* invertedIndex,
//      const Query& query, const vector<vector<int>*>& inputLists, size_t k,
//      vector<pair<int, double> >* resultList);

  // Prepare a string array for given string to our needs, that means:
  // * Split the string in its words
  // * Transform the chars of words to lowercase
  // * Remove leading and trailing punctuation in of every word
  // * Remove the stopwords
  static void normalize(const string& input, vector<string>* target);

  // k-way merge.
  static void merge(const vector<vector<int>* >& inputLists,
      vector<pair<int, int> >* resultLists);

  // Intersect two lists.
  static void intersect(const vector<pair<int, int> >& list1,
      const vector<pair<int, int> >& list2, vector<pair<int, int> >* result);

  // Intersect three lists.
  static void intersect(const vector<pair<int, int> >& list1,
      const vector<pair<int, int> >& list2, const vector<pair<int, int> >& list3,
      vector<pair<int, int> >* result);

private:
  // Check, if given word is a stopword
  FRIEND_TEST(RecordMatcherUtil2, isStopWord);
  static bool isStopWord(const string& word);

  // Read all stopwords from given file
  static void readStopWordsFromFile();
};

#endif /* RECORDMATCHERUTIL2_H_ */
