/*
 * RecordMatcherUtil2.cpp
 *
 *  Created on: Mar 11, 2013
 *      Author: korzen
 */

#include <google/dense_hash_map>
#include <stdio.h>
#include <errno.h>
#include <sys/time.h>
#include <algorithm>
#include <string>
#include <vector>
#include <utility>
#include <cctype>
#include <map>
#include <queue>
#include <limits>
#include "./InvertedIndex.h"
#include "./RecordMatcherUtil2.h"

using std::cout;
using std::endl;
using std::vector;
using std::priority_queue;
using std::pair;
using std::make_pair;
using std::sort;
using std::unique;
using std::string;
using std::min;

bool printRuntimes = false;

// Redefine comparison on our PQ items, so that the smallest element becomes the
// largest.
class Compare {
public:
  bool operator()(const pair<int, int>& x, const pair<int, int>& y) {
    return x.first > y.first;
  }
};

//// _____________________________________________________________________________
//void RecordMatcherUtil2::mergeAndSortByOccurrences(
//    // TODO: Split this method!
//    InvertedIndex* invertedIndex, const Query& query,
//    const vector<vector<int>*>& inputLists, size_t k,
//    vector<pair<int, double> >* resultList) {
//
//  timeval start, end;
//  timeval start1, end1;
//  double times1;
//  timeval start2, end2;
//  double times2;
//  timeval start3, end3;
//  double times3;
//  double timeInMs1;
//  double timeInMs2;
//
//  assert(resultList != NULL);
//  assert(resultList->size() == 0);
//
//  // The positions in the inputs lists.
//  vector<size_t> positions(inputLists.size(), 0);
//
//  // The current list elements in a priority queue.
//  priority_queue<pair<int, int> , vector<pair<int, int> > , ComparePairs> pq;
//  //  PriorityQueue<int, int> pq;
//  // The occurences of list elements in a priority queue.
//  priority_queue<pair<double, int> , vector<pair<double, int> > > pq2;
//  //  PriorityQueue<int, int> pq2;
//
//  // Initially, put the first element from each (non-empty) list.
//  for (size_t i = 0; i < inputLists.size(); i++) {
//    if (inputLists.size() > 0 && inputLists[i]->size() > 0) {
//      pq.push(pair<int, int> ((*inputLists[i])[0], i));
//    }
//  }
//  int x = 0;
//  gettimeofday(&start, 0);
//  // Iterate over the input lists, at each writing out the currently smallest
//  // element and advancing by one in the respective list.
//  while (pq.size() > 0) {
//    x++;
//    gettimeofday(&start1, 0);
//    // Get the current result element.
//    int curr = pq.top().first;
//    int i = pq.top().second;
//    pq.pop();
//
//    int occ = 1;
//    // Advance by one in the list where that element came from and if there is
//    // still an element left in that list, add it to the pq.
//    positions[i]++;
//    if (positions[i] < inputLists[i]->size()) {
//      pq.push(pair<int, int> ((*inputLists[i])[positions[i]], i));
//    }
//
//    // Count the elements with the same value
//    while (pq.size() > 0 && pq.top().first == curr) {
//      occ++;
//      // Get the next result element.
//      int j = pq.top().second;
//      pq.pop();
//      // Advance by one in the list where that element came from and if there is
//      // still an element left in that list, add it to the pq.
//      positions[j]++;
//      if (positions[j] < inputLists[j]->size()) {
//        pq.push(pair<int, int> ((*inputLists[j])[positions[j]], j));
//      }
//    }
//    gettimeofday(&end1, 0);
//    times1 += ((end1.tv_sec - start1.tv_sec) * 1000000 + end1.tv_usec
//        - start1.tv_usec) / 1000.0;
//
//    // TODO: Move the following computations to InvertedIndexRecordMatcher.
//    // Add the element with its occurrence in lists to second priority queue
//    // to get the most common elements. Because the pq is min-based, invert the
//    // occurrence.
//    gettimeofday(&start2, 0);
//    Record* record;
//    invertedIndex->resolveId(curr, &record);
//    // Add a bonus to the score to prefer records with fewer words.
//    double bonus = 0;
//    double malus = 0;
//    // TODO: Take into account, that a query can now contain various types.
//    //    if (query.type == "a") {
//    bonus = 1 - (double) record->authorWords.size() / 1000;
//    //      cout << "***" << record->key << "***" << endl;
//    //      cout << "actualNumOfLists: " << actualNumOfLists << endl;
//    //      cout << "authorWords: " << record->authorWords.size() << endl;
//    malus = 1 - ((double) std::min(inputLists.size(),
//        record->authorWords.size()) / std::max(inputLists.size(),
//        record->authorWords.size()));
//    //    } else if (query.type == "t") {
//    //      bonus = 1 - (double) record->titleWords.size() / 1000;
//    //    }
//
//    double first = occ + bonus - malus;
//    pq2.push(pair<double, int> (first, curr));
//    gettimeofday(&end2, 0);
//    times2 += ((end2.tv_sec - start2.tv_sec) * 1000000 + end2.tv_usec
//        - start2.tv_usec) / 1000.0;
//  }
//  gettimeofday(&end, 0);
//  timeInMs1 = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
//      - start.tv_usec) / 1000.0;
//
//  // Adjust k, if k is too large
//  k = pq2.size() <= k ? pq2.size() : k;
//
//  gettimeofday(&start3, 0);
//  // Fetch the top-k from occurrence-queue
//  for (size_t i = 0; i < k; i++) {
//    resultList->push_back(pair<int, double> (pq2.top().second, pq2.top().first));
//    pq2.pop();
//  }
//  gettimeofday(&end3, 0);
//  timeInMs2 = ((end3.tv_sec - start3.tv_sec) * 1000000 + end3.tv_usec
//      - start3.tv_usec) / 1000.0;
//  if (printRuntimes) {
//    cout << "      Time needed to fill pq: " << times1 << endl;
//    cout << "      Time needed to fill pq2: " << times2 << endl;
//    cout << "      Time needed to fill both pqs: " << timeInMs1 << endl;
//    cout << "      Time needed to fetch top-k: " << timeInMs2 << endl;
//    cout << "      NUM: " << x << endl;
//  }
//}

// ____________________________________________________________________________
void RecordMatcherUtil2::normalize(const string& input, vector<string>* target) {
  string abc =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890" // NOLINT
        "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"; // NOLINT
  string text;
  text.resize(input.size());

  // Transform the string to lower cases : ABCDefgH -> abcdefgh
  std::transform(input.begin(), input.end(), text.begin(), ::tolower);
  // Split the text on every special character.
  size_t pos = text.find_first_not_of(abc);
  size_t initialPos = 0;

  //  while (pos != string::npos) {
  //    string term = text.substr(initialPos, pos - initialPos);
  //    // Add word to target, if now the size of substring is > 2 and isn't
  //    // a stopword
  //    if (term.size() > MIN_WORD_LENGTH_INDEX && !isStopWord(term)) {
  //      target->push_back(term);
  //    }
  //    initialPos = pos + 1;
  //    pos = text.find_first_not_of(abc, initialPos);
  //  }
  //
  //
  //  pos = text.length();
  //
  //  // Don't forget to process the last term
  //  string term = text.substr(initialPos, pos - initialPos);
  //  //  cout << "(" << initialPos << "," << (pos - initialPos) << ")" << " -> " << term << endl;
  //  // Add word to target, if now the size of substring is > 2 and isn't
  //  // a stopword
  //  if (term.size() > MIN_WORD_LENGTH_INDEX && !isStopWord(term)) {
  //    //    cout << " -> ADD " << endl;
  //    target->push_back(term);
  //  }
  size_t i = 0;
  size_t j = 0;
  string part;
  while (i < text.length() && j < text.length()) {
    i = text.find_first_of(abc, j);
    {
      if (i != std::string::npos) {
        j = text.find_first_not_of(abc, i);
        part = text.substr(i, j - i);
        if (!part.empty()) {
          target->push_back(part);
        }
      }
    }
  }
  // Remove all duplicates.
  sort(target->begin(), target->end());
  target->erase(unique(target->begin(), target->end()), target->end());
}

// _____________________________________________________________________________
void RecordMatcherUtil2::readStopWordsFromFile() {
  // Open file, containg the stopwords
  FILE *stopWordsFile;
  stopWordsFile = fopen(stopWordsFileName2.c_str(), "r");
  char line[MAX_LINE_LENGTH];

  if (stopWordsFile == NULL) {
    perror("fopen failed");
    exit( errno);
  }

  // Read the file line by line. Each line contains a stopword.
  while (fgets(line, MAX_LINE_LENGTH, stopWordsFile) != NULL) {
    string lineAsString = line;
    // Find end of line
    size_t pos1 = lineAsString.find('\n');
    // Fetch stopword from line
    // TODO(korzen): Pointer
    _stopWords2.push_back(lineAsString.substr(0, pos1 - 1));
  }
  fclose(stopWordsFile);
}

// _____________________________________________________________________________
bool RecordMatcherUtil2::isStopWord(const string& word) {
  // Check, if file, containing the stopwords is already parsed
  if (_stopWords2.empty()) {
    readStopWordsFromFile();
  }

  // Return the result of a binary search after the given word.
  return (std::binary_search(_stopWords2.begin(), _stopWords2.end(), word));
}

// _____________________________________________________________________________
void RecordMatcherUtil2::merge(const vector<vector<int>*>& inputLists,
    vector<pair<int, int> >* resultLists) {
  assert(resultLists != NULL);
  assert(resultLists->size() == 0);

  // The positions in the input lists.
  vector<size_t> positions(inputLists.size(), 0);

  // The current list elements in a priority queue.
  priority_queue<pair<int, int> , vector<pair<int, int> > , Compare> pq;

  // Initially, put the first elements in a priority queue.
  for (size_t i = 0; i < inputLists.size(); i++) {
    if (inputLists[i]->size() > 0) {
      pq.push(make_pair((*inputLists[i])[0], i));
    }
  }
  // Iterate over the input lists, at each writing out the currently smallest
  // element, and advancing by one in the respective list.
  while (pq.size() > 0) {
    // Get the next result element and remove it from the pq.
    int element = pq.top().first;
    int occ = 0;

    // Count the occurrences of nextResultElement
    while (pq.size() > 0 && element == pq.top().first) {
      occ++;
      int i = pq.top().second;
      pq.pop();
      // Advance by one in the list where that element came from, and if there
      // is still an element left in that list, add it to the pq.
      positions[i]++;
      if (inputLists[i]->size() > positions[i]) {
        pq.push(make_pair((*inputLists[i])[positions[i]], i));
      }
    }

    resultLists->push_back(make_pair(element, occ));
  }
}

// _____________________________________________________________________________
void RecordMatcherUtil2::intersect(const vector<pair<int, int> >& list1,
    const vector<pair<int, int> >& list2, vector<pair<int, int> >* result) {
  assert(result != NULL);
  assert(result->empty());

  int i = 0;
  int j = 0;
  while (i < list1.size() && j < list2.size()) {
    while (i < list1.size() && list1[i].first < list2[j].first) {
      i++;
    }
    while (j < list2.size() && list1[i].first > list2[j].first) {
      j++;
    }
    if (list1[i].first == list2[j].first) {
      result->push_back(
          make_pair(list1[i].first, list1[i].second + list2[j].second));
      i++;
      j++;
    }
  }
}

// _____________________________________________________________________________
void RecordMatcherUtil2::intersect(const vector<pair<int, int> >& list1,
    const vector<pair<int, int> >& list2, const vector<pair<int, int> >& list3,
    vector<pair<int, int> >* result) {
  assert(result != NULL);
  assert(result->empty());
  int i = 0;
  int j = 0;
  int k = 0;
  while (i < list1.size() && j < list2.size() && k < list3.size()) {
    while (i < list1.size() && (list1[i].first < list2[j].first
        || list1[i].first < list3[k].first)) {
      i++;
    }
    while (j < list2.size() && (list2[j].first < list1[i].first
        || list2[j].first < list3[k].first)) {
      j++;
    }
    while (k < list3.size() && (list3[k].first < list1[i].first
        || list3[k].first < list2[j].first)) {
      k++;
    }
    if (list1[i].first == list2[j].first && list2[j].first == list3[k].first) {
      result->push_back(
          make_pair(list1[i].first, list1[i].second + list2[j].second + list3[k].second));
      i++;
      j++;
      k++;
    }
  }
}
