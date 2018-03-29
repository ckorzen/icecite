#CXX = g++ -O3 -Wall
CXX = g++ -g -O3 -Wall
MAIN_BINARIES = $(basename $(wildcard *Main.cpp))
TEST_BINARIES = $(basename $(wildcard *Test.cpp))
HEADER = $(wildcard *.h)
OBJECTS = $(addsuffix .o, $(basename $(filter-out %Main.cpp %Test.cpp,$(wildcard **/*.cpp))))
CPPLINT_PATH = ../lib/cpplint.py

PORT = 6200
DB_DBLP = data/dblp
DB_MEDLINE = data/medline
DB = data/dblp
#DB = data/medline
#DB = dblp+medline

TYPE = titles.dblp
#TYPE = titles.medline
#TYPE_EVAL = references.dblp
#TYPE = references.medline
VERBOSE = 0

all: compile test checkstyle

compile: $(MAIN_BINARIES) $(TEST_BINARIES)

test: $(TEST_BINARIES)
	for T in $(TEST_BINARIES); do ./$$T; done

checkstyle:
	python $(CPPLINT_PATH) *.h *.cpp

clean:
	rm -f *.o
	rm -f $(MAIN_BINARIES)
	rm -f $(TEST_BINARIES)
	rm -f *.class
	rm -f *Test.TMP.*
	rm -f core
	rm -f *.evaluation
	rm -f $(DB).records
	rm -f $(DB).index

evaluate-titles-dblp: RecordMatcherEvaluatorMain
	./RecordMatcherEvaluatorMain $(TYPE) $(DB_DBLP) $(VERBOSE)
	
evaluate-titles-pubmed: RecordMatcherEvaluatorMain
	./RecordMatcherEvaluatorMain $(TYPE) $(DB_MEDLINE) $(VERBOSE)

evaluate-references-dblp: RecordMatcherEvaluatorMain
	./RecordMatcherEvaluatorMain $(TYPE) $(DB_DBLP) $(VERBOSE)
	
evaluate-references-pubmed: RecordMatcherEvaluatorMain
	./RecordMatcherEvaluatorMain $(TYPE) $(DB_MEDLINE) $(VERBOSE)

start: RecordMatcherSocketMain
	./RecordMatcherSocketMain $(PORT) $(DB)

start-index: InvertedIndexSocketMain
	./InvertedIndexSocketMain $(PORT) $(DB)

RecordMatcherEvaluatorMain: RecordMatcherEvaluatorMain.o ReferencesMatcherEvaluator.o TitleMatcherEvaluator.o InvertedIndexRecordMatcher.o InvertedIndex.o RecordMatcherUtil.o RecordMatcherUtil2.o RecordMatcherSocket.o Record.o Query.o
	$(CXX) -o $@ $^

RecordMatcherSocketMain: RecordMatcherSocketMain.o RecordMatcherSocket.o InvertedIndexRecordMatcher.o InvertedIndex.o RecordMatcherUtil.o RecordMatcherUtil2.o Record.o Query.o
	$(CXX) -o $@ $^

InvertedIndexRecordMatcherTest: InvertedIndexRecordMatcherTest.o InvertedIndexRecordMatcher.o InvertedIndex.o RecordMatcherUtil.o RecordMatcherUtil2.o ReferencesMatcherEvaluator.o Record.o Query.o
	$(CXX) -o $@ $^ -lgtest -lgtest_main -pthread
	
InvertedIndexTest: InvertedIndexTest.o InvertedIndex.o RecordMatcherUtil.o RecordMatcherUtil2.o Record.o Query.o
	$(CXX) -o $@ $^ -lgtest -lgtest_main -pthread

RecordMatcherUtilTest: RecordMatcherUtilTest.o InvertedIndex.o InvertedIndexRecordMatcher.o RecordMatcherUtil.o RecordMatcherUtil2.o Record.o Query.o
	$(CXX) -o $@ $^ -lgtest -lgtest_main -pthread

RecordMatcherUtil2Test: RecordMatcherUtil2Test.o InvertedIndex.o InvertedIndexRecordMatcher.o RecordMatcherUtil.o RecordMatcherUtil2.o Record.o Query.o
	$(CXX) -o $@ $^ -lgtest -lgtest_main -pthread

%.o: %.cpp $(HEADER)
	$(CXX) -c $< -o $(addsuffix .o, $(basename $<)) 
