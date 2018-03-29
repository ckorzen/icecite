// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <sys/time.h>
#include <utility>
#include <string>
#include <vector>
#include <algorithm>
#include <google/dense_hash_map>
#include <fstream>
#include "./ReferencesMatcherEvaluator.h"
#include "./InvertedIndexRecordMatcher.h"
#include "./Query.h"

using google::dense_hash_map;
using std::string;
using std::endl;
using std::ofstream;
using std::cout;
using std::cerr;
using std::flush;
using std::pair;

// _____________________________________________________________________________
void ReferencesMatcherEvaluator::evaluate(RecordMatcherBase* recordMatcher,
    const string& type) {
  cout << "Matching references..." << endl;

  // We want to write the results of evaluation to file.
  // So: Open file for writing
  ofstream fileToWrite((type + FILE_EXTENSION_EVALUATION).c_str());
  ofstream matchingFailsFile((type + ".fails" + FILE_EXTENSION_QRELS).c_str());

  if (fileToWrite.good()) {
    // Count the number of right matches and
    // the number of failed matches (for statistics)
    int numOfMatches = 0;
    int numOfFails = 0;
    timeval start, end, queryStart, queryEnd;

    // Read File with groundTruth (contains query with appropriated key)
    // This function will fill _groundTruth
    readGroundTruth(type);

    gettimeofday(&start, 0);
    // TODO(korzen): Pointer groundTruth

    fileToWrite << "[YES|NO] TAB running time overall (in ms);"
        "find candidates (in ms); evaluate candidates (in ms);"
        "fetch topK (in ms) TAB groundTruthKey <-> foundKey TAB query" << endl;

    vector<pair<string, string> >::iterator it;
    double time0 = 0, time1 = 0, time2 = 0;
    for (it = _groundTruth.begin(); it != _groundTruth.end(); it++) {
      gettimeofday(&queryStart, 0);

      // Store the keys of found best matchings for the query
      // The number of keys can be > 1, if there are best matchings
      // with same score. So we use a vector.
      vector<pair<int, double> > recordScores;
      vector<double> runTimesInMs;

      // The query to evaluate
      dense_hash_map<string, string> parameter;
      parameter.set_empty_key("");
      parameter["q"] = it->first;
      Query query(&parameter);

      // The appropriated key
      string groundTruthKey = it->second;

      // Execute the search for best matchings for query and
      // store the result(s) in foundKeys
      recordMatcher->findBestMatchingRecords(query, &recordScores, &runTimesInMs);

      // Determine, if the result of matching contains the groundTruthKey
      Record* matchedRecord;
      if (!recordScores.empty()) {
        recordMatcher->resolveId(recordScores[0].first, &matchedRecord);
      }

      gettimeofday(&queryEnd, 0);
      double timeInMs = ((queryEnd.tv_sec - queryStart.tv_sec) * 1000000 +
          queryEnd.tv_usec - queryStart.tv_usec) / 1000.0;

      // write the result to file: One line per query:
      // (YES || NO) TAB times-statistics TAB query
      // If matching was successfully (that means: foundKeys contains
      // groundTruthKey), we will print a "YES" in front of line; "NO" other-
      // wise.
      // Explanation of the second condition:
      // The groundtruth-file contains entries for documents with no
      // dblp-match. In this case, the key is "NO_MATCH". So, when foundKeys
      // has no entries, the matching was also successfully (because the
      // algorithm has return the right result (no key -> no match))
      if (matchedRecord->key.compare(groundTruthKey) == 0 ||
          (groundTruthKey == "NO_MATCH" && matchedRecord->key.empty()) ) {
        fileToWrite << "YES";
        numOfMatches++;
      } else {
        fileToWrite << "NO";
        // TODO: Take into account, that query has no "raw" variable anymore.
//        matchingFailsFile << (query.raw + "\t" + groundTruthKey) << endl;

        cout << "Matching failed" << endl;
//        cout << "query: " << query.raw << endl;
        cout << "groundTruthKey: \'" << groundTruthKey << flush << "\'" << endl;

        if (recordScores.size() > 0) {
          cout << "Found match: \"" << matchedRecord->key << "\"" << endl;
        } else {
          cout << "Found match: No Match!" << endl;
        }
        cout << endl;
        numOfFails++;
      }
      fileToWrite << "\t";
      // Write time-statistics
      fileToWrite << timeInMs;
      fileToWrite << "; ";
      fileToWrite << runTimesInMs[0];
      fileToWrite << "; ";
      fileToWrite << runTimesInMs[1];
      fileToWrite << "; ";
      fileToWrite << runTimesInMs[2];
      fileToWrite << "\t";
      fileToWrite << groundTruthKey;
      fileToWrite << " <-> ";
      if (recordScores.size() > 0) {
        fileToWrite << matchedRecord->key;
      } else {
        fileToWrite << "NO_MATCH";
      }
      fileToWrite << "\t";
//      fileToWrite << query.raw;
      fileToWrite << "\n";

      time0 += runTimesInMs[0];
      time1 += runTimesInMs[1];
      time2 += runTimesInMs[2];
    }
    gettimeofday(&end, 0);

    double timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 +
        end.tv_usec - start.tv_usec) / 1000.0;
    cout << "Done!" << endl << endl;

    fileToWrite.close();
    matchingFailsFile.close();

    // Print some statistics: Number of right/failed matches & the according
    // percentage
    double numOfQueries = static_cast<double>(numOfFails + numOfMatches);
    cout << "Statistics:" << endl;
    cout << "Number of queries: " << (numOfFails + numOfMatches) << endl;
    cout << "Number of correct matches: " << numOfMatches
         << " ("
         << 100 * (static_cast<double>(numOfMatches) / numOfQueries)
         << "%)"
         << endl;
    cout << "Number of failed matches: " << numOfFails
         << " ("
         << 100 * (static_cast<double>(numOfFails) /
            static_cast<double>(numOfFails + numOfMatches))
         << "%)"
         << endl;
    cout << "Needed Time: Overall: " << timeInMs << "ms, "
         << "Avg per query: " << timeInMs / numOfQueries << "ms" << endl;
    cout << "  avg find candidates: " << time0 / numOfQueries << ", "
         << "avg evaluate candidates: " << time1 / numOfQueries << ", "
         << "avg fetch top-k: " << time2 / numOfQueries << endl;
  } else {
    cerr << "Error: Cannot find file "
         << (type + FILE_EXTENSION_EVALUATION) << endl;
    exit(1);
  }
}

// _____________________________________________________________________________
void ReferencesMatcherEvaluator::readGroundTruth(const string& baseName) {
  // Open file, containing the groundtruth (name of file given by baseName)
  ifstream groundTruthFile((baseName + FILE_EXTENSION_QRELS).c_str());

  string line;
  // Read file line by line, line of form: query TAB key
  while (getline(groundTruthFile, line)) {
    size_t pos1, pos2;
    // Pair: (query, key)
    pair<string, string> groundTruthElement;

    pos1 = 0;
    // Search for the TAB
    pos2 = line.find("\t", pos1);

    if (pos2 == 0) {
      pos1 = pos2 + 1;
      pos2 = line.find("\t", pos1);

      if (pos2 != string::npos) {
        groundTruthElement.first = line.substr(pos1, pos2 - pos1);

        pos1 = pos2 + 1;
        pos2 = line.find("\n", pos1);

        string key = line.substr(pos1, pos2 - pos1);

        // trim
        key = key.substr(0, key.length() - 1);

        groundTruthElement.second = key;
        _groundTruth.push_back(groundTruthElement);
      }
    } else if (pos2 > 0) {
      groundTruthElement.first = line.substr(pos1, pos2 - pos1);
      pos1 = pos2 + 1;
      pos2 = line.find("\n", pos1);

      string key = line.substr(pos1, pos2 - pos1);

      // trim
      key = key.substr(0, key.length());

      groundTruthElement.second = key;
      _groundTruth.push_back(groundTruthElement);
    }
  }
}
