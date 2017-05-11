// Copyright 2011, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <gtest/gtest.h>
#include <sys/time.h>
#include <stdio.h>
#include <string>
#include <vector>
#include <utility>
#include <map>
#include "./RecordMatcherUtil2.h"

using std::vector;
using std::string;
using std::cout;
using std::endl;
using std::map;

// Test RecordMatcherUtil2::merge
TEST(RecordMatcherUtil2, merge) {
  vector<vector<int>* > lists;
  vector<int> list1; // 1 4 8
  vector<int> list2; // 2 4 4 50
  vector<int> list3; // 8
  vector<pair<int, int> > target;

  list1.push_back(1);
  list1.push_back(4);
  list1.push_back(8);
  lists.push_back(&list1);

  RecordMatcherUtil2::merge(lists, &target);
  ASSERT_FALSE(target.empty());
  ASSERT_EQ(3, target.size());
  ASSERT_EQ(1, target[0].first);
  ASSERT_EQ(1, target[0].second);
  ASSERT_EQ(4, target[1].first);
  ASSERT_EQ(1, target[1].second);
  ASSERT_EQ(8, target[2].first);
  ASSERT_EQ(1, target[2].second);

  target.clear();
  list2.push_back(2);
  list2.push_back(4);
  list2.push_back(4);
  list2.push_back(50);
  lists.push_back(&list2);

  RecordMatcherUtil2::merge(lists, &target);
  ASSERT_FALSE(target.empty());
  ASSERT_EQ(5, target.size());
  ASSERT_EQ(1, target[0].first);
  ASSERT_EQ(1, target[0].second);
  ASSERT_EQ(2, target[1].first);
  ASSERT_EQ(1, target[1].second);
  ASSERT_EQ(4, target[2].first);
  ASSERT_EQ(3, target[2].second);
  ASSERT_EQ(8, target[3].first);
  ASSERT_EQ(1, target[3].second);
  ASSERT_EQ(50, target[4].first);
  ASSERT_EQ(1, target[4].second);
  target.clear();
  list3.push_back(8);
  lists.push_back(&list3);

  RecordMatcherUtil2::merge(lists, &target);
  ASSERT_FALSE(target.empty());
  ASSERT_FALSE(target.empty());
  ASSERT_EQ(5, target.size());
  ASSERT_EQ(1, target[0].first);
  ASSERT_EQ(1, target[0].second);
  ASSERT_EQ(2, target[1].first);
  ASSERT_EQ(1, target[1].second);
  ASSERT_EQ(4, target[2].first);
  ASSERT_EQ(3, target[2].second);
  ASSERT_EQ(8, target[3].first);
  ASSERT_EQ(2, target[3].second);
  ASSERT_EQ(50, target[4].first);
  ASSERT_EQ(1, target[4].second);
}

// Test RecordMatcherUtil2::intersect
TEST(RecordMatcherUtil2, intersect) {
  vector<pair<int, int> > v1;
  v1.push_back(std::make_pair(1, 1));
  v1.push_back(std::make_pair(2, 1));
  v1.push_back(std::make_pair(3, 1));
  v1.push_back(std::make_pair(5, 2));
  vector<pair<int, int> > v2;
  v2.push_back(std::make_pair(3, 2));
  v2.push_back(std::make_pair(5, 4));
  v2.push_back(std::make_pair(7, 1));

  vector<pair<int, int> > result;
  RecordMatcherUtil2::intersect(v1, v2, &result);
  ASSERT_FALSE(result.empty());
  ASSERT_EQ(2, result.size());
  ASSERT_EQ(3, result[0].first);
  ASSERT_EQ(3, result[0].second);
  ASSERT_EQ(5, result[1].first);
  ASSERT_EQ(6, result[1].second);
}

// Test RecordMatcherUtil2::sortByOccurrences
TEST(RecordMatcherUtil2, sortByOccurrence) {
  //  vector<vector<int> > lists;
  //  vector<int> list1;
  //  vector<int> target;
  //
  //  list1.push_back(1);
  //  list1.push_back(1);
  //  list1.push_back(3);
  //  list1.push_back(3);
  //  list1.push_back(3);
  //  list1.push_back(3);
  //  list1.push_back(5);
  //  list1.push_back(2);
  //  list1.push_back(2);
  //  list1.push_back(6);
  //  list1.push_back(6);
  //  list1.push_back(6);
  //
  //  RecordMatcherUtil2::sortByOccurrences(list1, &target);
  //  ASSERT_FALSE(target.empty());
  //  ASSERT_EQ(5, target.size());
  //  ASSERT_EQ(3, target[0]);
  //  ASSERT_EQ(6, target[1]);
  //  ASSERT_EQ(2, target[2]);
  //  ASSERT_EQ(1, target[3]);
  //  ASSERT_EQ(5, target[4]);
}

// Test RecordMatcherUtil2::intersect2
TEST(RecordMatcherUtil2, intersect2) {
  vector<pair<int, int> > v1;
  v1.push_back(std::make_pair(1, 1));
  v1.push_back(std::make_pair(2, 1));
  v1.push_back(std::make_pair(3, 1));
  v1.push_back(std::make_pair(5, 2));
  vector<pair<int, int> > v2;
  v2.push_back(std::make_pair(3, 2));
  v2.push_back(std::make_pair(5, 4));
  v2.push_back(std::make_pair(7, 1));
  vector<pair<int, int> > v3;
  v3.push_back(std::make_pair(3, 2));
  v3.push_back(std::make_pair(4, 4));
  v3.push_back(std::make_pair(7, 1));

  vector<pair<int, int> > result;
  RecordMatcherUtil2::intersect(v1, v2, v3, &result);
  ASSERT_FALSE(result.empty());
  ASSERT_EQ(1, result.size());
  ASSERT_EQ(3, result[0].first);
  ASSERT_EQ(5, result[0].second);
}
