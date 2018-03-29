// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <gtest/gtest.h>
#include <sys/time.h>
#include <stdio.h>
#include <string>
#include <vector>
#include <utility>
#include "./RecordMatcherUtil.h"

using std::vector;
using std::string;
using std::cout;
using std::endl;

// Test RecordMatcherUtil::normalizeString
TEST(RecordMatcherUtil, normalize) {
  vector<string> prepared1;
  string s = "";
  RecordMatcherUtil::normalize(s, &prepared1);
  ASSERT_EQ(0, prepared1.size());

  vector<string> prepared1a;
  s = "algorithm";
  RecordMatcherUtil::normalize(s, &prepared1a);
  ASSERT_EQ(1, prepared1a.size());
  ASSERT_EQ("algorithm", prepared1a[0]);

  vector<string> prepared2;
  s = "Word0 Word1 word2 word3";
  RecordMatcherUtil::normalize(s, &prepared2);
  ASSERT_EQ(4, prepared2.size());
  ASSERT_EQ("word0", prepared2[0]);
  ASSERT_EQ("word1", prepared2[1]);
  ASSERT_EQ("word2", prepared2[2]);
  ASSERT_EQ("word3", prepared2[3]);

  vector<string> prepared3;
  s = "Multi Modal Annotation of Quest Games in Rubber Life";
  RecordMatcherUtil::normalize(s, &prepared3);
  ASSERT_EQ(6, prepared3.size());
  ASSERT_EQ("annotation", prepared3[0]);
  ASSERT_EQ("games", prepared3[1]);
  ASSERT_EQ("life", prepared3[2]);
  ASSERT_EQ("modal", prepared3[3]);
  ASSERT_EQ("quest", prepared3[4]);
  ASSERT_EQ("rubber", prepared3[5]);

  vector<string> prepared4;
  s = "word";
  RecordMatcherUtil::normalize(s, &prepared4);
  ASSERT_EQ(1, prepared4.size());
  ASSERT_EQ("word", prepared4[0]);

  // Test string with duplicates
  vector<string> essentials;
  RecordMatcherUtil::normalize("house tree garden use tree", &essentials);
  ASSERT_EQ(3, essentials.size());
  ASSERT_EQ("garden", essentials[0]);
  ASSERT_EQ("house", essentials[1]);
  ASSERT_EQ("tree", essentials[2]);
}

// Test RecordMatcherUtil::isStopWord
TEST(RecordMatcherUtil, isStopWord) {
  ASSERT_TRUE(RecordMatcherUtil::isStopWord("i"));
  ASSERT_TRUE(RecordMatcherUtil::isStopWord("two"));
  ASSERT_FALSE(RecordMatcherUtil::isStopWord("who"));
  ASSERT_FALSE(RecordMatcherUtil::isStopWord(""));
  ASSERT_FALSE(RecordMatcherUtil::isStopWord("clustering"));
  ASSERT_FALSE(RecordMatcherUtil::isStopWord("searching"));
  ASSERT_FALSE(RecordMatcherUtil::isStopWord("index"));
  ASSERT_TRUE(RecordMatcherUtil::isStopWord("claudius"));
  ASSERT_TRUE(RecordMatcherUtil::isStopWord("prentice"));
}

// Test RecordMatcherUtil::editDistance
TEST(RecordMatcherUtil, localAlignment) {
  ASSERT_EQ(0.75, RecordMatcherUtil::localAlignment(
      string("ACACACTA"), string("AGCACACA"), 0));
  ASSERT_EQ(0, RecordMatcherUtil::localAlignment(
      string(""), string("AGCACACA"), 0));
  ASSERT_EQ(0, RecordMatcherUtil::localAlignment(
      string("AGCACACA"), string(""), 0));
  ASSERT_EQ(0.5, RecordMatcherUtil::localAlignment(
      string("TCCG"), string("ACGA"), 0));
  ASSERT_EQ(1, RecordMatcherUtil::localAlignment(
      string("ABCD"), string("ABCD"), 0));
  ASSERT_EQ(0, RecordMatcherUtil::localAlignment(
      string("ABCD"), string("EFGH"), 0));
}

// Test RecordMatcherUtil::computeWordCovering
TEST(RecordMatcherUtil, computeWordCovering) {
  string query1 = string("Today, it's one day after yesterday");
  string query2 = string("");
  string query3 = string("today, it's ONE day before tomorrow");
  string query4 = string("Today, it's ONE Day before tomorrow");

  vector<string> words;
  words.push_back("Today");
  words.push_back("tomorrow");
  words.push_back("ONE");
  words.push_back("Day");

  int index;
  ASSERT_EQ(0.5,
      RecordMatcherUtil::computeWordCovering(query1, words, &index));
  ASSERT_EQ(0, RecordMatcherUtil::computeWordCovering(query2, words, &index));
  ASSERT_EQ(1, RecordMatcherUtil::computeWordCovering(query3, words, &index));
  ASSERT_EQ(1, RecordMatcherUtil::computeWordCovering(query4, words, &index));
}

// Test RecordMatcherUtil::merge
TEST(RecordMatcherUtil, merge) {
  //  vector<vector<int> > inputLists(3);
  //
  //  vector<int>& A1 = inputLists[0];
  //  vector<int>& A2 = inputLists[1];
  //  vector<int>& A3 = inputLists[2];
  //
  //  A1.push_back(1);
  //  A1.push_back(5);
  //  A1.push_back(7);
  //  A2.push_back(5);
  //  A2.push_back(7);
  //  A3.push_back(5);
  //
  //  vector<int> R;
  //
  //  RecordMatcherUtil::merge(inputLists, 1, &R);
  //
  //  ASSERT_EQ(1, R.size());
  //  ASSERT_EQ(5, R[0]);
}

// Test RecordMatcherUtil::mergeAndSortWithOccurences
TEST(RecordMatcherUtil, mergeAndSortWithOccurences) {
  timeval start, end;
  double timeInMs;
  vector<vector<int>* > lists;

  vector<int> list1;
  vector<int> list2;
  vector<int> list3;

  list1.push_back(1);
  list1.push_back(4);
  list1.push_back(8);

  list2.push_back(0);
  list2.push_back(2);
  list2.push_back(4);
  list2.push_back(50);

  list3.push_back(8);

  lists.push_back(&list1);
  lists.push_back(&list2);
  lists.push_back(&list3);

  vector<int> target;

//  gettimeofday(&start, 0);
//  RecordMatcherUtil::mergeAndSortByOccurrences(lists, 3, &target);
//  gettimeofday(&end, 0);
//  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 +
//      end.tv_usec - start.tv_usec) / 1000.0;
//  cout << "time needed for old version: " << timeInMs << "ms" << endl;

  gettimeofday(&start, 0);
  RecordMatcherUtil::mergeAndSortByOccurrencesNew(lists, 3, &target);
  gettimeofday(&end, 0);
  timeInMs = ((end.tv_sec - start.tv_sec) * 1000000 +
      end.tv_usec - start.tv_usec) / 1000.0;
  cout << "time needed for new version: " << timeInMs << "ms" << endl;


  ASSERT_FALSE(target.empty());
  ASSERT_EQ(3, target.size());
  ASSERT_EQ(target[0], 4);
  ASSERT_EQ(target[1], 8);
  ASSERT_EQ(target[2], 0);
}
