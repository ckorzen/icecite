// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <errno.h>
#include <stdio.h>
#include <sys/time.h>
#include <iostream>
#include <fstream>
#include <utility>
#include <string>
#include <map>
#include <queue>
#include <vector>
#include <algorithm>
#include "./InvertedIndexRecordMatcher.h"
#include "./Record.h"

using std::cout;
using std::endl;
using std::string;
using std::pair;
using std::priority_queue;

// Compare Pairs by their second values (desc). The pair with the higher second
// value comes before the Pair with the lower second value
// i.e.: (1, 0.9) > (4, 0.87); (2, 0.1) > (3, 0.01);  (2, 0.3) > (8, 0)
bool comp_pairs_by_second_desc(const pair<int, int>& pair1,
    const pair<int, int>& pair2) {
  return (pair1.second > pair2.second);
}

// Read records from file and store them in invertedIndex.
void InvertedIndexRecordMatcher::readRecordsFromFile(const string& baseName) {
  _invertedIndex.build(baseName);
}

// _____________________________________________________________________________
void InvertedIndexRecordMatcher::findBestMatchingRecords(const Query& query,
    vector<pair<int, double> >* recordScores, vector<double>* runTimesInMs) {
  // pair of form (id, number of terms in common with the query).
  vector<pair<int, int> > candidates;
  // pairs of form: (id, score)
  vector<pair<int, double> > scores;
  timeval start, end;
  double timeInMs1;
  double timeInMs2;
  double timeInMs3;

  // Find candidates for query
  gettimeofday(&start, 0);
  findCandidates(query, &candidates);
  gettimeofday(&end, 0);
  timeInMs1 = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  runTimesInMs->push_back(timeInMs1);
  if (printRuntimes) {
    cout << "  Time needed to find candidates: " << timeInMs1 << endl;
  }

  // evaluate (score) the retrieved candidates
  gettimeofday(&start, 0);
  evaluateCandidates(query, candidates, &scores);
  gettimeofday(&end, 0);
  timeInMs2 = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  runTimesInMs->push_back(timeInMs2);
  if (printRuntimes) {
    cout << "  Time needed to evaluate candidates: " << timeInMs2 << endl;
  }

  // fetch the candidate(s) with best scoring
  gettimeofday(&start, 0);
  findCandidatesWithBestScoring(query, scores, recordScores);
  gettimeofday(&end, 0);
  timeInMs3 = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  runTimesInMs->push_back(timeInMs3);
  if (printRuntimes) {
    cout << "  Time needed to find candidates with best scoring: " << timeInMs3
        << endl;
  }
}

// _____________________________________________________________________________
void InvertedIndexRecordMatcher::findCandidates(const Query& query,
    vector<pair<int, int> >* candidates) {
  dense_hash_map<string, string>::const_iterator parametersIt;
  vector<vector<int>*> authorLists;
  vector<vector<int>*> titleLists;
  //  vector<vector<int>*> yearLists;
  vector<vector<int>*> otherLists;
  timeval start, end;
  double timeInMs;
  gettimeofday(&start, 0);
  for (parametersIt = query.parameters->begin(); parametersIt
      != query.parameters->end(); parametersIt++) {
    vector<string> words;
    RecordMatcherUtil::normalize(parametersIt->second, &words);
    RecordMatcherUtil::sortAndUniq(&words);
    vector<string>::const_iterator wordsIt;
    for (wordsIt = words.begin(); wordsIt != words.end(); wordsIt++) {
      if (wordsIt->length() > 0) {
        if (parametersIt->first == "a") {
          // Get list for author word.
          vector<int>* invertedList;
          _invertedIndex.get("author:" + *wordsIt, &invertedList);
          authorLists.push_back(invertedList);
        } else if (parametersIt->first == "t" /* && wordsIt->length() > 0 */) {
          // Get list for title word.
          vector<int>* invertedList;
          _invertedIndex.get("title:" + *wordsIt, &invertedList);
          titleLists.push_back(invertedList);
        }
        //        else if (parametersIt->first == "y") {
        //          // Get list for title word.
        //          vector<int>* invertedList;
        //          _invertedIndex.get("year:" + *wordsIt, &invertedList);
        //          yearLists.push_back(invertedList);
        //        }
        else {
          // Get list for title word.
          vector<int>* invertedList;
          _invertedIndex.get(*wordsIt, &invertedList);
          otherLists.push_back(invertedList);
        }
      }
    }
  }

  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  if (printRuntimes) {
    cout << "    Time needed to fetch lists: " << timeInMs << endl;
  }

  gettimeofday(&start, 0);
  // TODO: Refactor.
  if (authorLists.size() > 0 && titleLists.size() > 0 && otherLists.size() > 0) {
    // Merge the author lists.
    vector<pair<int, int> > authorCandidates;
    RecordMatcherUtil2::merge(authorLists, &authorCandidates);
    // Merge the title lists.
    vector<pair<int, int> > titleCandidates;
    RecordMatcherUtil2::merge(titleLists, &titleCandidates);
    // Merge the year lists.
    vector<pair<int, int> > otherCandidates;
    RecordMatcherUtil2::merge(otherLists, &otherCandidates);
    // Intersect both lists.
    RecordMatcherUtil2::intersect(titleCandidates, authorCandidates,
        otherCandidates, candidates);
  } else if (authorLists.size() > 0 && titleLists.size() > 0) {
    // Merge the author lists.
    vector<pair<int, int> > authorCandidates;
    RecordMatcherUtil2::merge(authorLists, &authorCandidates);
    // Merge the title lists.
    vector<pair<int, int> > titleCandidates;
    RecordMatcherUtil2::merge(titleLists, &titleCandidates);
    // Intersect both lists.
    RecordMatcherUtil2::intersect(titleCandidates, authorCandidates, candidates);
  } else if (authorLists.size() > 0 && otherLists.size() > 0) {
    // Merge the author lists.
    vector<pair<int, int> > authorCandidates;
    RecordMatcherUtil2::merge(authorLists, &authorCandidates);
    // Merge the title lists.
    vector<pair<int, int> > otherCandidates;
    RecordMatcherUtil2::merge(otherLists, &otherCandidates);
    // Intersect both lists.
    RecordMatcherUtil2::intersect(authorCandidates, otherCandidates, candidates);
  } else if (titleLists.size() > 0 && otherLists.size() > 0) {
    // Merge the author lists.
    vector<pair<int, int> > titleCandidates;
    RecordMatcherUtil2::merge(titleLists, &titleCandidates);
    // Merge the title lists.
    vector<pair<int, int> > otherCandidates;
    RecordMatcherUtil2::merge(otherLists, &otherCandidates);
    // Intersect both lists.
    RecordMatcherUtil2::intersect(titleCandidates, otherCandidates, candidates);
  } else if (authorLists.size() > 0) {
    RecordMatcherUtil2::merge(authorLists, candidates);
  } else if (otherLists.size() > 0) {
    RecordMatcherUtil2::merge(otherLists, candidates);
  } else {
    RecordMatcherUtil2::merge(titleLists, candidates);
  }
  // Finally, sort the candidates by their occurrences
  std::sort(candidates->begin(), candidates->end(), comp_pairs_by_second_desc);

  gettimeofday(&end, 0);

  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  if (printRuntimes) {
    cout << "    Time needed to merge and sort: " << timeInMs << endl;
  }
}

// _____________________________________________________________________________
void InvertedIndexRecordMatcher::evaluateCandidates(const Query& query,
    const vector<pair<int, int> >& candidates,
    vector<pair<int, double> >* scores) {
  timeval start, end;
  double times1;
  double times2;
  double timeInMs;

  // Iterate over records in mergedList and compute for all of
  // them the score, consisting of author-score and title-score
  vector<pair<int, int> >::const_iterator it;
  Record* record;

  for (it = candidates.begin(); it != candidates.end(); it++) {
    gettimeofday(&start, 0);
    bool isGoodScore = false;

    _invertedIndex.resolveId(it->first, &record);

    if (record != NULL) {
//      string key = record->key;
//      string authors = record->authors;
//      string year = record->year;

      gettimeofday(&end, 0);
      times1 += ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
          - start.tv_usec) / 1000.0;

//      if (verbose) {
//        cout << "EVAL: " << key << " " << authors << " " << " " << year << " "
//            << record->title << endl;
//      }

      int occ = it->second;
      double bonus = 0;
      double malus = 0;
      // TODO: Take into account, that a query can now contain various types.
      //    if (query.type == "a") {
//      vector<string> authors = record->authorWords;
//      bonus = 1 - (double) authors.size() / 1000;
      //      cout << "***" << record->key << "***" << endl;
      //      cout << "actualNumOfLists: " << actualNumOfLists << endl;
      //      cout << "authorWords: " << record->authorWords.size() << endl;
      //    malus = 1 - ((double) std::min(inputLists.size(),
      //        record->authorWords.size()) / std::max(inputLists.size(),
      //        record->authorWords.size()));
      //    } else if (query.type == "t") {
      //      bonus = 1 - (double) record->titleWords.size() / 1000;
      //    }

      double score = occ + bonus;

      // TODO: Move score-computations of mergeAndSortByOccurence to this point.
      // Now we can get occurrences via it->second.
      isGoodScore = true;

      // TODO: Take into Account, that a query can now contain various types!
      //    if (query.type == "t") {
      //      gettimeofday(&start, 0);
      //      // Title matching
      //      score = RecordMatcherUtil::localAlignment(query.normalized,
      //          record->normalizedTitle, 0);
      //      //      score = -1 * RecordMatcherUtil::levensthein(query.raw_lowercases, title);
      //
      //      //      double maxLength = (double) std::max(query.raw.size(), title.size());
      //      //      double minLength = (double) std::min(query.raw.size(), title.size());
      //      //      double relation = minLength / maxLength;
      //      //      double rawScore = score;
      //      //      score = -1 * rawScore * rawScore * relation;
      //
      //      //      score = -1 * RecordMatcherUtil::levensthein(query.raw_lowercases, title);
      //      //      if (score > -0.5 * maxLength) { isGoodScore = true; }
      //      isGoodScore = true;
      //      if (verbose) {
      //        cout << "  " << record->title << endl;
      //        cout << "    t: " << score << endl;
      //      }
      //      gettimeofday(&end, 0);
      //      times2 += ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      //          - start.tv_usec) / 1000.0;
      //    } else if (query.type == "a") {
      //      //      score = it->second / record->authorWords.size();
      //      score = it->second;
      //      isGoodScore = true;
      //    }

      //      double score = 0;
      //    if (query.isBibEntry) {
      //      int indexOfLastAuthor = 0;
      //      // compute authorScore (via computing word-covery: check for every author-
      //      // name, if candidate-string contains the author
      //      double authorScore = RecordMatcherUtil::computeWordCovering(
      //          query.normalized, record->authorWords, &indexOfLastAuthor);
      //
      //      double yearScore = 0;
      //      size_t found = query.raw.rfind(year);
      //      if (found != string::npos) { yearScore = 1; }
      //
      //      double titleScore = 0;
      //
      //      if (authorScore > 0) {
      //        // compute titleScore (via local-alignment: Smith Waterman)
      //        titleScore = RecordMatcherUtil::localAlignment(query.normalized,
      //            record->normalizedTitle, 0);
      //
      //        score = ((3.0 / 4.0) * titleScore) + ((3.0 / 16.0) * authorScore) +
      //            ((1.0 / 16.0) * yearScore);
      //        if (score > 0.5) { isGoodScore = true; }
      //        if (verbose) {
      //          cout << "   a: " << authorScore << " y: " << yearScore << " t: "
      //              << titleScore << " s: " << score << endl;
      //        }
      //      }
      //    } else {
      //
      //    }

      if (isGoodScore) {
        pair<int, double> scorePair;
        scorePair.first = it->first;
        scorePair.second = score;
        scores->push_back(scorePair);
      }
    }
  }
  gettimeofday(&start, 0);
  // Sort the records by their scores
  std::sort(scores->begin(), scores->end(), sortFunctor(&_invertedIndex));
  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec
      - start.tv_usec) / 1000.0;
  if (printRuntimes) {
    cout << "    Time needed to prepare candidates: " << times1 << endl;
    cout << "    Time needed to score candidates  : " << times2 << endl;
    cout << "    Time needed to sort candidates   : " << timeInMs << endl;
  }
}

// _____________________________________________________________________________
void InvertedIndexRecordMatcher::findCandidatesWithBestScoring(
    const Query& query, const vector<pair<int, double> >& scores,
    vector<pair<int, double> >* recordScores) {
  // Return all documents with the highest word covering (can be > 1 documents!)
  double prevScore = -1;
  // check, how many candidates are there with score = highestScore
  vector<pair<int, double> >::const_iterator it;
  int i = 0;
  for (it = scores.begin(); it != scores.end(); it++) {
    double currentScore = it->second;

    // Abort, if match with a lower word-covering than highest word-covering
    // is found or if the match has a word-covering, which is to low
    // (< MINIMAL_WORD_COVERING)
    if (currentScore != prevScore && recordScores->size() >= 10) {
      break;
    }

    recordScores->push_back(*it);
    prevScore = currentScore;
    i++;
    if (i == 100) { break; }
  }
}

// _____________________________________________________________________________
void InvertedIndexRecordMatcher::resolveId(int id, Record** record) {
  _invertedIndex.resolveId(id, record);
}

// _____________________________________________________________________________
size_t InvertedIndexRecordMatcher::getNumOfDocuments(const Query& query) {
  dense_hash_map<string, string>::const_iterator parametersIt;

  for (parametersIt = query.parameters->begin(); parametersIt
      != query.parameters->end(); parametersIt++) {
    string normalized;
    vector<string> tmp;
    RecordMatcherUtil::normalize(parametersIt->second, &tmp);
    RecordMatcherUtil::sortAndUniq(&tmp);
    RecordMatcherUtil::toString(tmp, &normalized);
    vector<int>* invertedList;

    if (!normalized.empty()) {
      if (parametersIt->first == "na") {
        _invertedIndex.get("author:" + normalized, &invertedList);
      } else if (parametersIt->first == "nt") {
        _invertedIndex.get("title:" + normalized, &invertedList);
      }
      assert(invertedList != NULL);
      return invertedList->size();
    } else {
      return 0;
    }
  }
}
