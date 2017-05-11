// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

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
#include "./RecordMatcherUtil.h"

using google::dense_hash_map;
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
using std::map;

static map<int, int> _diacriticsToBasicMap;
static map<string, int> _htmlEntitiesToCharMap;

// _____________________________________________________________________________
string RecordMatcherUtil::decodeHtml(const string& input) {
  if (_htmlEntitiesToCharMap.empty()) {
    makeHtmlEntitiesToCharMap();
  }

  string output = "";
  map<string, int>::iterator it;
  for (size_t i = 0; i < input.length(); i++) {
    char ch = input[i];
    // Resolve all html entitites. An example of a html entity: &aacute;
    // Hence, search for '&' and ';' to locate html entities.
    if (ch == '&') {
      size_t posSemicolon = input.find(';', i);
      if (posSemicolon != string::npos) {;
        // Extract the html entity;
        string htmlEntity = input.substr(i + 1, posSemicolon - i - 1);
        // Check, if the extracted html entity is a valid one (if it is contained in the map).
        map<string, int>::iterator it = _htmlEntitiesToCharMap.find(htmlEntity);
        if (it != _htmlEntitiesToCharMap.end()) {
          ch = static_cast<char> (it->second);
          i += posSemicolon - i;
        }
      }
    }
    output += ch;
  }
  return output;
}

// _____________________________________________________________________________
void createCleanString(const string& queryString, string* cleanString) {
  // -> normalize
  // -> toString
}

// _____________________________________________________________________________
void createString(const vector<string>& words, string* output) {
  // -> toString
}

// ____________________________________________________________________________
void normalizeOLD(const string& input, vector<string>* target) {
  // -> normalize
  // -> sortAndUniq
}

// _____________________________________________________________________________
void RecordMatcherUtil::normalize(const string& input, vector<string>* output) {
  string abc =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890" // NOLINT
        "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"; // NOLINT
  string specialChars = "àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ";
  string deaccented = "aaaaaaaceeeeiiiidnoooooouuuuypy";
  string text;
  text.resize(input.size());

  // Transform the string to lower cases : ABCDefgH -> abcdefgh
  std::transform(input.begin(), input.end(), text.begin(), ::tolower);
  map<int, int>::iterator it;

  // Fill the diacriticsToBasicMap, if it is empty.
  if (_diacriticsToBasicMap.empty()) {
    makeDiacriticsToBasicMap();
  }

  //// Replace all accented chars with their deaccented chars.
  for (size_t i = 0; i < text.size(); i++) {
    char ch = text[i];
    int hex = static_cast<int> (ch);
    hex = hex < 0 ? hex + 256 : hex;
    it = _diacriticsToBasicMap.find(hex);
    if (it != _diacriticsToBasicMap.end()) {
      char basicChar = static_cast<char> (it->second);
      text[i] = basicChar;
    }
  }

  // Split the text on every special character.
  size_t pos = text.find_first_not_of(abc);
  size_t initialPos = 0;

  while (pos != string::npos) {
    string term = text.substr(initialPos, pos - initialPos);
    // Add word to target, if now the size of substring is > 2 and isn't
    // a stopword
    if (!term.empty() && !isStopWord(term)) {
      output->push_back(term);
    }
    initialPos = pos + 1;
    pos = text.find_first_not_of(abc, initialPos);
  }

  pos = text.length();

  // Don't forget to process the last term
  string term = text.substr(initialPos, pos - initialPos);
  //  cout << "(" << initialPos << "," << (pos - initialPos) << ")" << " -> " << term << endl;
  // Add word to target, if now the size of substring is > 2 and isn't
  // a stopword
  if (!term.empty() && !isStopWord(term)) {
    //    cout << " -> ADD " << endl;
    output->push_back(term);
  }
}

// _____________________________________________________________________________
void RecordMatcherUtil::sortAndUniq(vector<string>* input) {
  // Remove all duplicates.
  sort(input->begin(), input->end());
  input->erase(unique(input->begin(), input->end()), input->end());
}

// _____________________________________________________________________________
void RecordMatcherUtil::toString(const vector<string>& input, string* output) {
  vector<string>::const_iterator it;
  for (it = input.begin(); it != input.end(); it++) {
    if (it != input.begin()) {
      output->append(" ");
    }
    output->append(*it);
  }
}

// ____________________________________________________________________________
void normalizeKeepDuplicates(const string& input, vector<string>* target) {
  // -> normalize
}

// Compare Pairs by their second values (desc). The pair with the higher second
// value < The Pair with the lower second value
// i.e.: (1,9) > (4,7); (2,5) > (3,3);  (2,1) > (8, 0)
struct comp_pairs_by_second_desc {
  bool operator()(const pair<int, int>& x, const pair<int, int>& y) {
    if (x.second != y.second) {
      return x.second > y.second;
    } else {
      return x.first < y.first;
    }
  }
};

// ____________________________________________________________________________
void RecordMatcherUtil::mergeAndSortByOccurrencesNew(
    const vector<vector<int>*>& inputLists, size_t k, vector<int>* resultList) {
  timeval start, end;
  double timeInMs;

  dense_hash_map<int, int> occs;
  occs.set_empty_key(-1);

  gettimeofday(&start, 0);
  // Initially, put the first element from each (non-empty) list.
  for (size_t i = 0; i < inputLists.size(); i++) {
    for (size_t j = 0; j < inputLists[i]->size(); j++) {
      occs[(*inputLists[i])[j]]++;
    }
  }
  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  cout << "time needed to iterate over lists: " << timeInMs << endl;

  gettimeofday(&start, 0);
  vector<pair<int, int> > v(occs.begin(), occs.end());
  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  cout << "time needed to put map into list: " << timeInMs << endl;

  gettimeofday(&start, 0);
  std::sort(v.begin(), v.end(), comp_pairs_by_second_desc());
  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  cout << "time needed to sort list: " << timeInMs << endl;

  gettimeofday(&start, 0);
  k = std::min(k, v.size());
  for (size_t i = 0; i < k; i++) {
    resultList->push_back(v[i].first);
  }
  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  cout << "time needed to prepare result: " << timeInMs << endl;
}

// _____________________________________________________________________________
void RecordMatcherUtil::mergeAndSortByOccurrences(
    const vector<vector<int>*>& inputLists, size_t k, vector<int>* resultList) {
  timeval start, end;
  double timeInMs;

  assert(resultList != NULL);
  assert(resultList->size() == 0);

  // The positions in the inputs lists.
  vector<size_t> positions(inputLists.size(), 0);

  // The current list elements in a priority queue.
  priority_queue<pair<int, int> , vector<pair<int, int> > , ComparePairs> pq;
  //  PriorityQueue<int, int> pq;
  // The occurences of list elements in a priority queue.
  priority_queue<pair<int, int> , vector<pair<double, int> > , ComparePairs>
      pq2;
  //  PriorityQueue<int, int> pq2;

  // Initially, put the first element from each (non-empty) list.
  for (size_t i = 0; i < inputLists.size(); i++) {
    if (inputLists.size() > 0) {
      pq.push(pair<int, int> ((*inputLists[i])[0], i));
    }
  }

  gettimeofday(&start, 0);
  // Iterate over the input lists, at each writing out the currently smallest
  // element and advancing by one in the respective list.
  while (pq.size() > 0) {
    // Get the current result element.
    int curr = pq.top().first;
    int i = pq.top().second;
    pq.pop();

    int occ = 1;
    // Advance by one in the list where that element came from and if there is
    // still an element left in that list, add it to the pq.
    positions[i]++;
    if (positions[i] < inputLists[i]->size()) {
      pq.push(pair<int, int> ((*inputLists[i])[positions[i]], i));
    }

    // Count the elements with the same value
    while (pq.size() > 0 && pq.top().first == curr) {
      occ++;
      // Get the next result element.
      int j = pq.top().second;
      pq.pop();
      // Advance by one in the list where that element came from and if there is
      // still an element left in that list, add it to the pq.
      positions[j]++;
      if (positions[j] < inputLists[j]->size()) {
        pq.push(pair<int, int> ((*inputLists[j])[positions[j]], j));
      }
    }

    // Add the element with its occurrence in lists to second priority queue
    // to get the most common elements. Because the pq is min-based, invert the occurence.
    pq2.push(pair<int, int> (-1 * occ, curr));
  }
  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  //  cout << "time needed to iterate over lists: " << timeInMs << endl;

  // Adjust k, if k is too large
  k = pq2.size() <= k ? pq2.size() : k;

  // Fetch the top-k from occurrence-queue
  for (size_t i = 0; i < k; i++) {
    resultList->push_back(pq2.top().second);
    pq2.pop();
  }
}

// _____________________________________________________________________________
void RecordMatcherUtil::readStopWordsFromFile() {
  // Open file, containg the stopwords
  FILE *stopWordsFile;
  stopWordsFile = fopen(stopWordsFileName.c_str(), "r");
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
    _stopWords.push_back(lineAsString.substr(0, pos1 - 1));
  }
  fclose(stopWordsFile);
}

// _____________________________________________________________________________
bool RecordMatcherUtil::isStopWord(const string& word) {
  // Check, if file, containing the stopwords is already parsed
  if (_stopWords.empty()) {
    readStopWordsFromFile();
  }

  // Return the result of a binary search after the given word.
  return (std::binary_search(_stopWords.begin(), _stopWords.end(), word));
}

// _____________________________________________________________________________
double RecordMatcherUtil::localAlignment(const string& x, const string& y,
    int pos_begin) {
  // Step 1:
  //  string x, y;
  //  x.resize(query.length());
  //  y.resize(candidateTitle.length());
  //  // Transform the string to lower cases : ABCDefgH -> abcdefgh
  //  createCleanString(query, &x);
  //
  //  // Transform the string to lower cases : ABCDefgH -> abcdefgh
  //  createCleanString(candidateTitle, &y);

  //  const string modifiedQuery = query.substr(pos_begin);
  size_t n = x.length();
  size_t m = y.length();

  // The easy case: length1 == 0 || length2 = 0;
  if (n <= 0 || m <= 0)
    return 0;

  vector<vector<int> > matrix(n + 1, vector<int> (m + 1));
  double maxScore = 0;

  // Step 2: Fill the boundary cases
  for (int i = 0; i < n + 1; i++) {
    matrix[i][0] = 0;
  }

  for (int j = 0; j < m + 1; j++) {
    matrix[0][j] = 0;
  }

  // Step 3: Fill the matrix by determining the minimum of the three values
  // for Replacement, Insertion and Deletion
  for (int i = 1; i < n + 1; i++) {
    for (int j = 1; j < m + 1; j++) {
      // If chars are the same: costs = 2, otherwise: costs = -1;
      int replaceCosts = x[i - 1] == y[j - 1] ? 2 : -1;

      int diagCost = matrix[i - 1][j - 1] + replaceCosts; // Replace
      int aboveCost = matrix[i - 1][j] - 1; // insert
      int leftCost = matrix[i][j - 1] - 1; // delete

      // Determine Minimum of the three values
      matrix[i][j] = std::max(std::max(0, diagCost),
          std::max(aboveCost, leftCost));
      if (matrix[i][j] > maxScore)
        maxScore = matrix[i][j];
    }
  }
  //  printf("maxScore: %f\n", maxScore);

  // Normalize the score to get a value in interval [0,1]
  //  double max = 2 * std::min(queryLength, titleLength);
  double max = 2 * n;

  return maxScore / max;
  //  return maxScore;
  //  max = 2 * std::max(queryLength, titleLength);

  //  return normalize(maxScore, 0, max, 0, 1);
}

// ____________________________________________________________________________
double RecordMatcherUtil::levensthein(const string& s1, const string& s2) {
  const size_t len1 = s1.size(), len2 = s2.size();
  vector<vector<int> > d(len1 + 1, vector<int> (len2 + 1));

  d[0][0] = 0;
  for (size_t i = 1; i <= len1; ++i)
    d[i][0] = i;
  for (size_t i = 1; i <= len2; ++i)
    d[0][i] = i;

  for (size_t i = 1; i <= len1; ++i) {
    for (size_t j = 1; j <= len2; ++j) {
      d[i][j] = std::min(std::min(d[i - 1][j] + 1, d[i][j - 1] + 1),
          d[i - 1][j - 1] + (s1[i - 1] == s2[j - 1] ? 0 : 1));
    }
  }

  return d[len1][len2];
}

// _____________________________________________________________________________
double RecordMatcherUtil::computeWordCovering(const string& query,
    const vector<string>& candidateWords, int* indexOfLastAuthor) {
  double numCandidateWords = candidateWords.size();
  double numMatches = 0;
  int max_index = 0, current_index;

  //  printf("WC: query: %s\n", query.c_str());

  // check for every word from candidate-words, if query contains it.
  vector<string>::const_iterator it;
  for (it = candidateWords.begin(); it != candidateWords.end(); it++) {
    size_t found = query.find(*it);

    //    printf("  WC: author: %s, Pos: %zu",
    //              it->c_str(), found);

    // Consider only whole words (candidateWord should not be a substring of a
    // word of query. So check, if founded pos is surrounded by whitespaces
    if (found != string::npos) {
      bool checkLeftSide = ((found == 0) || query[(found - 1)] == ' ');
      bool checkRightSide = ((found + it->length() == query.length())
          || (query[found + it->length()] == ' ')); // TODO(korzen): REGEX

      //      printf("  left: %d, right: %d, %zu", checkLeftSide, checkRightSide,
      //          found + it->length());

      if (checkLeftSide || checkRightSide) {
        //      printf("    founded\n");
        current_index = found + it->length() + 1;
        if (current_index > max_index)
          max_index = current_index;
        numMatches++;
      }
    }
    //    printf("\n");
  }

  *indexOfLastAuthor = max_index;
  numMatches = std::min(2 * numMatches, numCandidateWords);

  //  printf("%f / %f = %f", numMatches, numCandidateWords,
  // numMatches / numCandidateWords);

  if (numCandidateWords != 0)
    return numMatches / numCandidateWords;
  return 0;
}

// _____________________________________________________________________________
void RecordMatcherUtil::split(const string& str, const string& separator,
    vector<string>* results) {
  size_t pos1 = 0;
  size_t pos2 = str.find_first_of(separator);
  while (pos2 != string::npos) {
    if (pos2 > 0)
      results->push_back(str.substr(pos1, pos2 - pos1));
    pos1 = pos2 + 1;
    pos2 = str.find_first_of(separator, pos1);
  }
  if (pos1 < str.length())
    results->push_back(str.substr(pos1));
}

// _____________________________________________________________________________
void RecordMatcherUtil::replaceAll(const string& toRemove, int length,
    const string& toInsert, string* stringToTransform) {
  size_t pos = 0;
  while (pos != string::npos) {
    pos = stringToTransform->find(toRemove, pos);
    if (pos != string::npos)
      stringToTransform->replace(pos, length, toInsert);
  }
}

// _____________________________________________________________________________
bool RecordMatcherUtil::isNumber(const string& str) {
  for (size_t i = 0; i < str.length(); i++) {
    if (!std::isdigit(str[i]))
      return false;
  }
  return true;
}

// _____________________________________________________________________________
void RecordMatcherUtil::makeDiacriticsToBasicMap() {
  _diacriticsToBasicMap[0x00C0] = 0x0061;
  _diacriticsToBasicMap[0x00C1] = 0x0061;
  _diacriticsToBasicMap[0x00C2] = 0x0061;
  _diacriticsToBasicMap[0x00C3] = 0x0061;
  _diacriticsToBasicMap[0x00C4] = 0x0061;
  _diacriticsToBasicMap[0x00C5] = 0x0061;
  _diacriticsToBasicMap[0x00C6] = 0x0061;
  _diacriticsToBasicMap[0x00C7] = 0x0063;
  _diacriticsToBasicMap[0x00C8] = 0x0065;
  _diacriticsToBasicMap[0x00C9] = 0x0065;
  _diacriticsToBasicMap[0x00CA] = 0x0065;
  _diacriticsToBasicMap[0x00CB] = 0x0065;
  _diacriticsToBasicMap[0x00CC] = 0x0069;
  _diacriticsToBasicMap[0x00CD] = 0x0069;
  _diacriticsToBasicMap[0x00CE] = 0x0069;
  _diacriticsToBasicMap[0x00CF] = 0x0069;
  _diacriticsToBasicMap[0x00D0] = 0x0064;
  _diacriticsToBasicMap[0x00D1] = 0x006E;
  _diacriticsToBasicMap[0x00D2] = 0x006F;
  _diacriticsToBasicMap[0x00D3] = 0x006F;
  _diacriticsToBasicMap[0x00D4] = 0x006F;
  _diacriticsToBasicMap[0x00D5] = 0x006F;
  _diacriticsToBasicMap[0x00D6] = 0x006F;
  _diacriticsToBasicMap[0x00D7] = 0x006F;
  _diacriticsToBasicMap[0x00D8] = 0x006F;
  _diacriticsToBasicMap[0x00D9] = 0x0075;
  _diacriticsToBasicMap[0x00DA] = 0x0075;
  _diacriticsToBasicMap[0x00DB] = 0x0075;
  _diacriticsToBasicMap[0x00DC] = 0x0075;
  _diacriticsToBasicMap[0x00DD] = 0x0079;
  _diacriticsToBasicMap[0x00DE] = 0x0070;
  _diacriticsToBasicMap[0x00DF] = 0x00DF;
  _diacriticsToBasicMap[0x00E0] = 0x0061;
  _diacriticsToBasicMap[0x00E1] = 0x0061;
  _diacriticsToBasicMap[0x00E2] = 0x0061;
  _diacriticsToBasicMap[0x00E3] = 0x0061;
  _diacriticsToBasicMap[0x00E4] = 0x0061;
  _diacriticsToBasicMap[0x00E5] = 0x0061;
  _diacriticsToBasicMap[0x00E6] = 0x0061;
  _diacriticsToBasicMap[0x00E7] = 0x0063;
  _diacriticsToBasicMap[0x00E8] = 0x0065;
  _diacriticsToBasicMap[0x00E9] = 0x0065;
  _diacriticsToBasicMap[0x00EA] = 0x0065;
  _diacriticsToBasicMap[0x00EB] = 0x0065;
  _diacriticsToBasicMap[0x00EC] = 0x0069;
  _diacriticsToBasicMap[0x00ED] = 0x0069;
  _diacriticsToBasicMap[0x00EE] = 0x0069;
  _diacriticsToBasicMap[0x00EF] = 0x0069;
  _diacriticsToBasicMap[0x00F0] = 0x0064;
  _diacriticsToBasicMap[0x00F1] = 0x006E;
  _diacriticsToBasicMap[0x00F2] = 0x006F;
  _diacriticsToBasicMap[0x00F3] = 0x006F;
  _diacriticsToBasicMap[0x00F4] = 0x006F;
  _diacriticsToBasicMap[0x00F5] = 0x006F;
  _diacriticsToBasicMap[0x00F6] = 0x006F;
  _diacriticsToBasicMap[0x00F7] = 0x006F;
  _diacriticsToBasicMap[0x00F8] = 0x006F;
  _diacriticsToBasicMap[0x00F9] = 0x0075;
  _diacriticsToBasicMap[0x00FA] = 0x0075;
  _diacriticsToBasicMap[0x00FB] = 0x0075;
  _diacriticsToBasicMap[0x00FC] = 0x0075;
  _diacriticsToBasicMap[0x00FD] = 0x0070;
  _diacriticsToBasicMap[0x00FE] = 0x0079;
  _diacriticsToBasicMap[0x00FF] = 0x0070;
}
;

void RecordMatcherUtil::makeHtmlEntitiesToCharMap() {
  _htmlEntitiesToCharMap["Agrave"] = 0x00C0;
  _htmlEntitiesToCharMap["Aacute"] = 0x00C1;
  _htmlEntitiesToCharMap["Acirc"] = 0x00C2;
  _htmlEntitiesToCharMap["Atilde"] = 0x00C3;
  _htmlEntitiesToCharMap["Auml"] = 0x00C4;
  _htmlEntitiesToCharMap["Aring"] = 0x00C5;
  _htmlEntitiesToCharMap["AElig"] = 0x00C6;
  _htmlEntitiesToCharMap["Ccedil"] = 0x00C7;
  _htmlEntitiesToCharMap["Egrave"] = 0x00C8;
  _htmlEntitiesToCharMap["Eacute"] = 0x00C9;
  _htmlEntitiesToCharMap["Ecirc"] = 0x00CA;
  _htmlEntitiesToCharMap["Euml"] = 0x00CB;
  _htmlEntitiesToCharMap["Igrave"] = 0x00CC;
  _htmlEntitiesToCharMap["Iacute"] = 0x00CD;
  _htmlEntitiesToCharMap["Icirc"] = 0x00CE;
  _htmlEntitiesToCharMap["Iuml"] = 0x00CF;
  _htmlEntitiesToCharMap["ETH"] = 0x00D0;
  _htmlEntitiesToCharMap["Ntilde"] = 0x00D1;
  _htmlEntitiesToCharMap["Ograve"] = 0x00D2;
  _htmlEntitiesToCharMap["Oacute"] = 0x00D3;
  _htmlEntitiesToCharMap["Ocirc"] = 0x00D4;
  _htmlEntitiesToCharMap["Otilde"] = 0x00D5;
  _htmlEntitiesToCharMap["Ouml"] = 0x00D6;
  _htmlEntitiesToCharMap["Oslash"] = 0x00D8;
  _htmlEntitiesToCharMap["Ugrave"] = 0x00D9;
  _htmlEntitiesToCharMap["Uacute"] = 0x00DA;
  _htmlEntitiesToCharMap["Ucirc"] = 0x00DB;
  _htmlEntitiesToCharMap["Uuml"] = 0x00DC;
  _htmlEntitiesToCharMap["Yacute"] = 0x00DD;
  _htmlEntitiesToCharMap["THORN"] = 0x00DE;
  _htmlEntitiesToCharMap["szlig"] = 0x00DF;
  _htmlEntitiesToCharMap["agrave"] = 0x00E0;
  _htmlEntitiesToCharMap["aacute"] = 0x00E1;
  _htmlEntitiesToCharMap["acirc"] = 0x00E2;
  _htmlEntitiesToCharMap["atilde"] = 0x00E3;
  _htmlEntitiesToCharMap["auml"] = 0x00E4;
  _htmlEntitiesToCharMap["aring"] = 0x00E5;
  _htmlEntitiesToCharMap["aelig"] = 0x00E6;
  _htmlEntitiesToCharMap["ccedil"] = 0x00E7;
  _htmlEntitiesToCharMap["egrave"] = 0x00E8;
  _htmlEntitiesToCharMap["eacute"] = 0x00E9;
  _htmlEntitiesToCharMap["ecirc"] = 0x00EA;
  _htmlEntitiesToCharMap["euml"] = 0x00EB;
  _htmlEntitiesToCharMap["igrave"] = 0x00EC;
  _htmlEntitiesToCharMap["iacute"] = 0x00ED;
  _htmlEntitiesToCharMap["icirc"] = 0x00EE;
  _htmlEntitiesToCharMap["iuml"] = 0x00EF;
  _htmlEntitiesToCharMap["eth"] = 0x00F0;
  _htmlEntitiesToCharMap["ntilde"] = 0x00F1;
  _htmlEntitiesToCharMap["ograve"] = 0x00F2;
  _htmlEntitiesToCharMap["oacute"] = 0x00F3;
  _htmlEntitiesToCharMap["ocirc"] = 0x00F4;
  _htmlEntitiesToCharMap["otilde"] = 0x00F5;
  _htmlEntitiesToCharMap["ouml"] = 0x00F6;
  _htmlEntitiesToCharMap["oslash"] = 0x00F8;
  _htmlEntitiesToCharMap["ugrave"] = 0x00F8;
  _htmlEntitiesToCharMap["uacute"] = 0x00FA;
  _htmlEntitiesToCharMap["ucirc"] = 0x00FB;
  _htmlEntitiesToCharMap["uuml"] = 0x00FC;
  _htmlEntitiesToCharMap["yacute"] = 0x00FD;
  _htmlEntitiesToCharMap["thorn"] = 0x00FE;
  _htmlEntitiesToCharMap["yuml"] = 0x00FF;
  _htmlEntitiesToCharMap["reg"] = 0x00AE;
  _htmlEntitiesToCharMap["micro"] = 0x00B5;
  _htmlEntitiesToCharMap["times"] = 0x00D7;
}
