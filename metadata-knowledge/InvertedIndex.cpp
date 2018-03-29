// Copyright 2013, University of Freiburg,
// Chair of Algorithms and Data Structures.
// Author: Claudius Korzen <korzen>.

#include <google/dense_hash_map>
#include <errno.h>
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>
#include "./InvertedIndex.h"
#include "./Record.h"

using google::dense_hash_map;
using std::cout;
using std::endl;
using std::ifstream;
using std::ofstream;
using std::getline;
using std::flush;
using std::stringstream;
using std::min;
using std::string;

void split(const string& s, char delim, vector<string>* elems) {
  stringstream ss(s);
  string item;
  while (getline(ss, item, delim)) {
    elems->push_back(item);
  }
}

// _____________________________________________________________________________
void InvertedIndex::build(const string& basename) {
  assert(basename.size() > 0);

  // Check, if there is a previous computed records file.
  ifstream recordsFile((basename + FILE_EXTENSION_RECORDS).c_str());
  // Check, if there is a previous computed serialized version of the index.
  ifstream indexFile((basename + FILE_EXTENSION_INDEX).c_str());

  // Read the records.
  if (!recordsFile.is_open()) {
    cout << "Records file doesn't exist. Need to create it first..." << flush;
    createRecordsFile(basename);
    cout << "Done!" << endl;
  }
  cout << "Read records from file " << (basename + FILE_EXTENSION_RECORDS)
      << "..." << flush;
  readRecordsFile(basename);
  cout << "Done!" << endl;

  // Build the index.
  if (indexFile.is_open()) {
    cout << "Serialized index exists. Try to deserialize it..." << flush;
    deserialize(basename);
    cout << "Done!" << endl;
  } else {
    cout << "Serialized index doesn't exist. Need to compute it..." << flush;
    buildIndex(basename);
    cout << "Done!" << endl;
  }

  recordsFile.close();
  indexFile.close();
}

// _____________________________________________________________________________
void InvertedIndex::createRecordsFile(const string& basename) {
  // Define several types identifying a record on parsing.
  string recordTypesArray[] = { "<article ", "<inproceedings ", "<book ",
      "<phdthesis ", "<mastersthesis ", "<incollection ", "<proceedings " };
  vector<string> recordTypes(recordTypesArray, recordTypesArray + 7);

  // Open xml-file, to parse it for the records
  ifstream xmlFile((basename + FILE_EXTENSION_XML).c_str());
  // Open records-file, to persist extracted records from xml-file
  ofstream recordsFile((basename + FILE_EXTENSION_RECORDS).c_str());

  assert(xmlFile != NULL);
  assert(recordsFile != NULL);

  // Read the file line by line.
  // example for an entry of a record in dblp.xml:
  // <incollection mdate="2004-03-08" key="books/acm/kim95/BreitbartGS95">
  //   <author>Yuri Breitbart</author>
  //   <author>Hector Garcia-Molina</author>
  //   <author>Abraham Silberschatz</author>
  //   <title>Transaction Management in Multidatabase Systems.</title>
  //   <pages>573-591</pages>
  //   <booktitle>Modern Database Systems</booktitle>
  //   <crossref>books/acm/Kim95</crossref>
  //   <url>db/books/collections/kim95.html#BreitbartGS95</url>
  //   <year>1995</year>
  // </incollection>
  // From this, we have to extract key, authors and title

  string line, type, key, title, year, journal, pages, url, ee;
  bool isFirstAuthor = true;
  stringstream authors;

  // Read file line by line.
  while (getline(xmlFile, line)) {
    // Check, if line includes the actual type within a closing element.
    // Because it identifies the end of a record, all values have to been set.
    // Write an according line that includes the values to the records-file.
    if (line.find("</" + type + ">") != string::npos) {
      assert(title.size() > 0);
      assert(key.size() > 0);
      // Don't insist on non-empty author(s) and year, because there are
      // records without author(s) and/or a year.

      // Write line to record file.
      recordsFile << key << "\t" << authors.str() << "\t" << year << "\t"
          << title << "\t" << journal << "\t" << pages << "\t" << url << "\t" 
          << ee << endl;
      // Clear the temporary values.
      type.clear();
      key.clear();
      title.clear();
      authors.str("");
      year.clear();
      journal.clear();
      pages.clear();
      url.clear();
      ee.clear();
      isFirstAuthor = true;
    }

    // Check if the line symbolize the start of a record (check for a type).
    size_t typeElementStart = string::npos;
    for (size_t i = 0; i < recordTypes.size(); i++) {
      // Take the first occurrence of any type.
      typeElementStart = min(typeElementStart, line.find(recordTypes[i]));
    }

    // Check if a proper type was found. If so, extract it as well as the key.
    if (typeElementStart != string::npos) {
      // Increment the value of posTypeStart to skip the "<"
      size_t typeStart = typeElementStart + 1;
      // Extract the type of the record.
      size_t typeEnd = line.find_first_of(" ", typeStart);
      type = line.substr(typeStart, typeEnd - typeStart);

      // Extract the key of the record. Skip the 5 chars of "key=\"".
      size_t keyStart = line.find("key=\"", typeEnd) + 5;
      size_t keyEnd = line.find("\"", keyStart);
      key = line.substr(keyStart, keyEnd - keyStart);
    }

    if (type.size() > 0) {
      // Check if line includes the title.
      size_t titleElementStart = line.find("<title");
      size_t titleStart = line.find(">", titleElementStart) + 1;
      size_t titleEnd = line.find("</title>", titleStart);
      if (titleElementStart != string::npos) {
        title = line.substr(titleStart, titleEnd - titleStart);
      }

      // Check if line includes an author.
      size_t authorElementStart = line.find("<author");
      size_t authorStart = line.find(">", authorElementStart) + 1;
      size_t authorEnd = line.find("</author>", authorStart);
      if (authorElementStart != string::npos) {
        if (!isFirstAuthor) {
          authors << "$";
        } // Separate individual authors by semicolon.
        authors << line.substr(authorStart, authorEnd - authorStart);
        isFirstAuthor = false;
      }

      // Check if line includes the year.
      size_t yearElementStart = line.find("<year");
      size_t yearStart = line.find(">", yearElementStart) + 1;
      size_t yearEnd = line.find("</year>", yearStart);
      if (yearElementStart != string::npos) {
        year = line.substr(yearStart, yearEnd - yearStart);
      }

      // Check if line includes the journal.
      size_t journalElementStart = line.find("<journal");
      size_t journalStart = line.find(">", journalElementStart) + 1;
      size_t journalEnd = line.find("</journal>", journalStart);
      if (journalElementStart != string::npos) {
        journal = line.substr(journalStart, journalEnd - journalStart);
      }

      // Check if line includes the journal.
      size_t booktitleElementStart = line.find("<booktitle");
      size_t booktitleStart = line.find(">", booktitleElementStart) + 1;
      size_t booktitleEnd = line.find("</booktitle>", booktitleStart);
      if (booktitleElementStart != string::npos) {
        journal = line.substr(booktitleStart, booktitleEnd - booktitleStart);
      }

      // Check if line includes the journal.
      size_t publisherElementStart = line.find("<publisher");
      size_t publisherStart = line.find(">", publisherElementStart) + 1;
      size_t publisherEnd = line.find("</publisher>", publisherStart);
      if (publisherElementStart != string::npos) {
        journal = line.substr(publisherStart, publisherEnd - publisherStart);
      }

      // Check if line includes the pages.
      size_t pagesElementStart = line.find("<pages");
      size_t pagesStart = line.find(">", pagesElementStart) + 1;
      size_t pagesEnd = line.find("</pages>", pagesStart);
      if (pagesElementStart != string::npos) {
        pages = line.substr(pagesStart, pagesEnd - pagesStart);
      }

      // Check if line includes the url.
      size_t urlElementStart = line.find("<url");
      size_t urlStart = line.find(">", urlElementStart) + 1;
      size_t urlEnd = line.find("</url>", urlStart);
      if (urlElementStart != string::npos) {
        url = line.substr(urlStart, urlEnd - urlStart);
      }

      // Check if line includes the url.
      size_t eeElementStart = line.find("<ee");
      size_t eeStart = line.find(">", eeElementStart) + 1;
      size_t eeEnd = line.find("</ee>", eeStart);
      if (eeElementStart != string::npos) {
        ee = line.substr(eeStart, eeEnd - eeStart);
      }
    }
  }
  xmlFile.close();
  recordsFile.close();
}

// _____________________________________________________________________________
void InvertedIndex::readRecordsFile(const string& basename) {
  // Read the records from records file.
  ifstream recordsFile((basename + FILE_EXTENSION_RECORDS).c_str());

  assert(recordsFile.is_open());

  string line;
  // Read line by line: <key> TAB <authors> TAB <year> TAB <title>
  while (getline(recordsFile, line)) {
    size_t pos1, pos2;
    Record record;

    // Extract the key from line
    pos1 = 0;
    pos2 = line.find("\t", pos1);
    record.key = line.substr(pos1, pos2 - pos1);

    // Extract the authors from line
    pos1 = pos2 + 1;
    pos2 = line.find("\t", pos1);
    record.setAuthors(line.substr(pos1, pos2 - pos1));

    // Extract the year from line
    pos1 = pos2 + 1;
    pos2 = line.find("\t", pos1);
    record.year = line.substr(pos1, pos2 - pos1);

    // Extract the title from line
    pos1 = pos2 + 1;
    pos2 = line.find("\t", pos1);
    record.setTitle(line.substr(pos1, pos2 - pos1));

    // Extract the journal from line
    pos1 = pos2 + 1;
    pos2 = line.find("\t", pos1);
    record.journal = line.substr(pos1, pos2 - pos1);

    // Extract the pages from line
    pos1 = pos2 + 1;
    pos2 = line.find("\t", pos1);
    record.pages = line.substr(pos1, pos2 - pos1);

    // Extract the url from line
    pos1 = pos2 + 1;
    pos2 = line.find("\t", pos1);
    record.url = line.substr(pos1, pos2 - pos1);

    // Extract the ee from line
    pos1 = pos2 + 1;
    pos2 = line.find("\n", pos1);
    record.ee = line.substr(pos1, pos2 - pos1);

    _records.push_back(record);
  }
  recordsFile.close();
}

// _____________________________________________________________________________
void InvertedIndex::deserialize(const string& basename) {
  size_t pos1, pos2;
  // Open the serialized index file.
  ifstream serializedIndex((basename + FILE_EXTENSION_INDEX).c_str());

  // Assert that serialized index file exists.
  assert(serializedIndex.is_open());

  string line;
  // read file. lines look like this: "term TAB id1 id2 id3 ..."
  while (getline(serializedIndex, line)) {
    string term;
    vector<int> invertedList;

    // Extract the term from line.
    pos1 = 0;
    pos2 = line.find("\t");
    term = line.substr(pos1, pos2 - pos1);

    // Extract the inverted list from line.
    while (pos2 != string::npos) {
      pos1 = pos2 + 1;
      pos2 = line.find(" ", pos1);

      // convert string to int
      int id = atoi(line.substr(pos1, pos2 - pos1).c_str());
      invertedList.push_back(id);
    }
    add(term, invertedList);
  }
  serializedIndex.close();
}

// _____________________________________________________________________________
void InvertedIndex::buildIndex(const string& basename) {
  assert(_records.size() > 0);

  // read records from memory
  vector<Record>::iterator it;
  vector<string>::iterator jt;
  vector<string>::iterator kt;
  int i = 0;
  for (it = _records.begin(); it != _records.end(); it++, i++) {
    vector<string> titleWords;
    string title = RecordMatcherUtil::decodeHtml(it->title);
    RecordMatcherUtil::normalize(title, &titleWords);
    for (jt = titleWords.begin(); jt != titleWords.end(); jt++) {
      add(*jt, i);
      add("title:" + *jt, i);
    }

    vector<string> authorWords;
    string authors = RecordMatcherUtil::decodeHtml(it->authors);
    RecordMatcherUtil::normalize(authors, &authorWords);
    for (jt = authorWords.begin(); jt != authorWords.end(); jt++) {
      add(*jt, i);
      add("author:" + *jt, i);
    }
    //    vector<string> authors;
    //    // Split the author string into the individual author names.
    //    split(it->authors, '$', &authors);
    //    for (jt = authors.begin(); jt != authors.end(); jt++) {
    //      vector<string> authorWords;
    //      // Split each author in its words.
    //      split(*jt, ' ', &authorWords);
    //      for (kt = authorWords.begin(); kt != authorWords.end(); kt++) {
    //        add(*kt, i);
    //      }
    //      // Add the last name of author with prefix "author" to index.
    //      if (!authorWords.empty()) { add("author:" + authorWords.back(), i); }
    //    }

    vector<string> yearWords;
    RecordMatcherUtil::normalize(it->year, &yearWords);
    for (jt = yearWords.begin(); jt != yearWords.end(); jt++) {
      add(*jt, i);
      add("year:" + *jt, i);
    }
  }
  // Serialize the index (write it to file)
  serialize(basename);
}

// _____________________________________________________________________________
void InvertedIndex::serialize(const string& basename) {
  // Open a file, to write the inverted index in it.
  ofstream serializedIndex((basename + FILE_EXTENSION_INDEX).c_str());
  dense_hash_map<string, vector<int> >::iterator it;

  // Iterate over index and write one line per inverted index like:
  // term TAB id1 id2 id3 ...
  for (it = _invertedIndex.begin(); it != _invertedIndex.end(); it++) {
    stringstream lineToWrite, listToWrite;

    string term = it->first;
    vector<int> invertedList = it->second;

    // Write term to line
    lineToWrite << term;
    lineToWrite << '\t';

    // Write inverted list to line.
    vector<int>::iterator jt;
    for (jt = invertedList.begin(); jt != invertedList.end(); jt++) {
      // Separate the id's by space-character (except the last one)
      if (jt != invertedList.begin()) {
        listToWrite << " ";
      }
      listToWrite << *jt;
    }
    // Finish line by escape-sequence "new line"
    listToWrite << "\n";
    lineToWrite << listToWrite.str();

    serializedIndex << lineToWrite.str();
  }
  serializedIndex.close();
}

// _____________________________________________________________________________
void InvertedIndex::resolveId(int id, Record** record) {
  *record = &_records[id];
}

// _____________________________________________________________________________
void InvertedIndex::add(const string& term, int id) {
  // Add the doc-id to inverted list only, if given term isn't empty
  if (!term.empty()) {
    _invertedIndex[term].push_back(id);
  }
}

// _____________________________________________________________________________
void InvertedIndex::add(const string& term, const vector<int>& list) {
  // Add the doc-id to inverted list only, if given term isn't empty and if
  // given list isn't empty
  if (!term.empty() && !list.empty()) {
    _invertedIndex[term] = list;
  }
}

// _____________________________________________________________________________
bool InvertedIndex::empty() {
  return _invertedIndex.empty();
}

// _____________________________________________________________________________
void InvertedIndex::get(const string& term, vector<int>** list) {
  *list = &_invertedIndex[term];
}
