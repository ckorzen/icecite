package de.freiburg.iif.extraction.metadata;
//package de.freiburg.iif.extraction.title;
//
//import java.io.File;
//import java.io.IOException;
//import java.util.ArrayList;
//import java.util.Collections;
//import java.util.HashMap;
//import java.util.List;
//import java.util.Map;
//import java.util.Map.Entry;
//import java.util.regex.Matcher;
//
//import org.apache.commons.logging.Log;
//
//import com.google.inject.Inject;
//
//import de.freiburg.iif.extraction.MetadataMatcher;
//import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge;
//import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQuery;
//import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQueryType;
//import de.freiburg.iif.extraction.stripper.PdfExtraction;
//import de.freiburg.iif.model.DblpRecord;
//import de.freiburg.iif.model.HasMetadata;
//import de.freiburg.iif.model.Region;
//import de.freiburg.iif.model.Score;
//import de.freiburg.iif.model.Stats;
//import de.freiburg.iif.utils.Patterns;
//import de.freiburg.iif.utils.StringSimilarity;
//
///**
// * The class DocumentMetadataMatcher, that implements MetadataMatcher and can be
// * used to find the record in the metadata knowledge base, referred by a
// * document. The matching process uses an inverted index, which is implemented
// * in C++. The inverted index provides a socket, which can be queried by sending
// * ordinary HTTP requests to it. The result is a xml file, containing the
// * result.
// * 
// * @author Claudius Korzen
// * 
// */
//public class DocumentMetadataMatcherMAN implements MetadataMatcher {
//  /** The numbers contained in the first page */
//  protected List<Integer> numbersOfFirstPage;
//  /** The text of the first page */
//  protected StringBuilder textOfFirstPage;
//  /** The abstract */
//  protected StringBuilder abstractSb;
//  /** The interface to the metadata knowledge base */
//  protected MetadataKnowledge mk;
//  /** The interface to the pdf extraction tool */
//  protected PdfExtraction ex;
//  /** The extracted lines */
//  protected List<Region> lines;
//  /** The stats containing the most common fontsize and linepitch */
//  protected Stats stats;
//  /** The log4j logger */
//  protected Log LOG;
//  /**
//   * The minimal time interval to wait betwenn two request to the metadata
//   * knowledge.
//   */
//  protected int mkMinWaitInterval;
//
//  /**
//   * The constructor.
//   * 
//   * @param mk
//   *          the implementation of MetadataKnowledge.
//   * @param ex
//   *          the implementation of PdfExtraction.
//   * @param log
//   *          the implementation of Log.
//   */
//  @Inject
//  public DocumentMetadataMatcherMAN(MetadataKnowledge mk, PdfExtraction ex,
//      Log log) {
//    this.mk = mk;
//    this.ex = ex;
//    this.LOG = log;
//
//    this.textOfFirstPage = new StringBuilder();
//    this.numbersOfFirstPage = new ArrayList<Integer>();
//    this.abstractSb = new StringBuilder();
//  }
//
//  @Override
//  public List<HasMetadata> match(String filepath, boolean strict,
//    boolean disableMK, int minWaitInterval) throws IOException {
//    return match(new File(filepath), strict, disableMK, minWaitInterval);
//  }
//
//  @Override
//  public List<HasMetadata> match(File pdfFile, boolean strict,
//    boolean disableMK, int minWaitInterval) throws IOException {
//    lines = ex.extractLines(pdfFile, 1, 1, false);
//    return match(lines, strict, disableMK,
//        minWaitInterval);
//  }
//
//  /**
//   * Tries to find the referred metadata record on the basis of the given
//   * textlines.
//   * 
//   * @param lines
//   *          the textlines to analyze.
//   * @return the matched metadata record.
//   * @throws IOException
//   *           if the matching process fails.
//   */
//  public List<HasMetadata> match(List<Region> lines, boolean strict,
//    boolean disableMK, int minWaitInterval) throws IOException {
//    textOfFirstPage.setLength(0);
//    abstractSb.setLength(0);
//    numbersOfFirstPage.clear();
//    mkMinWaitInterval = minWaitInterval;
//
//    // Fetch only the lines of the first page.
//    lines = scanLinesOfFirstPage(lines);
//    // Filter all lines with emphasis score < the most common emphasis score.
//    lines = filterByEmphasis(lines);
//    // Group the lines into logical blocks
//    lines = groupIntoBlocks(lines);
//
//    return wrap(getMatchingRecord(lines, strict, disableMK));
//  }
//
//  /**
//   * Filters the given lines and returns a new list, containing only the lines
//   * of the first page.
//   * 
//   * @param lines
//   *          the lines to filter.
//   * @return new list, containing only the lines of the first page.
//   */
//  protected List<Region> scanLinesOfFirstPage(List<Region> lines) {
//    Map<Integer, Integer> fontsizes = new HashMap<Integer, Integer>();
//    Map<Integer, Integer> linepitches = new HashMap<Integer, Integer>();
//    int mostCommonFontsize = -1;
//    int mostCommonPitchsize = -1;
//    boolean isAbstract = false;
//
//    if (lines != null) {
//      List<Region> linesOfFirstPage = new ArrayList<Region>();
//      for (int i = 0; i < lines.size(); i++) {
//        Region prevLine = i > 0 ? lines.get(i - 1) : null;
//        Region line = lines.get(i);
//
//        LOG.debug("Processing line " + line);
//
//        if (line != null) {
//          if (line.getPageNumber() == 1) {
//            linesOfFirstPage.add(line);
//
//            // Compute the fontsize and put it into map.
//            int fontsize = Math.round(line.getFontsize());
//            if (fontsizes.containsKey(fontsize)) {
//              fontsizes.put(fontsize, fontsizes.get(fontsize) + 1);
//            } else {
//              fontsizes.put(fontsize, 1);
//            }
//
//            if (prevLine != null) {
//              // Compute the linepitch and put it into map.
//              float prevLineBottom = prevLine.getY() + prevLine.getHeight();
//              float lineTop = line.getY();
//              int linepitch = Math.round(Math.abs(prevLineBottom - lineTop));
//              if (linepitches.containsKey(linepitch)) {
//                linepitches.put(linepitch, linepitches.get(linepitch) + 1);
//              } else {
//                linepitches.put(linepitch, 1);
//              }
//            }
//
//            // Extract all numbers in the first page.
//            Matcher m = Patterns.NUMBERS_PATTERN.matcher(line.getText());
//            while (m.find()) {
//              try {
//                numbersOfFirstPage.add(Integer.parseInt(m.group()));
//              } catch (Exception e) {
//              }
//            }
//          }
//
//          // Extract the abstract
//          // There are papers, which contains multiple abstracts (e.g. one in
//          // english and one in german). Check, if a version was already found
//          // (if length > 0) to avodi to identify both versions.
//
//          if (abstractSb.length() == 0) {
//            Matcher m = Patterns.ABSTRACT_PATTERN.matcher(line.getText());
//            if (m.find()) {
//              isAbstract = true;
//            }
//          }
//
//          // Search for the abstract on all pages.
//          if (isAbstract) {
//            float prevEmphasis = computeEmphasis(prevLine);
//            float emphasis = computeEmphasis(line);
//            float diff = Math.round(Math.abs(prevEmphasis - emphasis));
//            if (diff > 0.1f && abstractSb.length() > 20) {
//              isAbstract = false;
//              // Abstract was found. Nothing more to do, if pageNumber is > 1.
//              if (line.getPageNumber() > 1) {
//                break;
//              }
//            } else {
//              abstractSb.append(line.getText());
//            }
//          }
//        }
//      }
//
//      // Compute the most common fontsize.
//      int mostCommonFontsizeNum = 0;
//      for (Entry<Integer, Integer> stat : fontsizes.entrySet()) {
//        // Don't consider the fontsize 0.
//        if (stat.getKey() > 0 && stat.getValue() > mostCommonFontsizeNum) {
//          mostCommonFontsizeNum = stat.getValue();
//          mostCommonFontsize = stat.getKey();
//        }
//      }
//
//      // Compute the most common linepitch.
//      int mostCommonPitchSizeNum = 0;
//      for (Entry<Integer, Integer> stat : linepitches.entrySet()) {
//        // Don't consider the pitch 0.
//        if (stat.getKey() > 0 && stat.getValue() > mostCommonPitchSizeNum) {
//          mostCommonPitchSizeNum = stat.getValue();
//          mostCommonPitchsize = stat.getKey();
//        }
//      }
//
//      this.stats = new Stats(mostCommonFontsize, mostCommonPitchsize);
//
//      LOG.debug("Most common fontsize: " + mostCommonFontsize);
//      LOG.debug("Most common linepitch " + mostCommonPitchsize);
//
//      return linesOfFirstPage;
//    }
//    return null;
//  }
//
//  /**
//   * Filter the lines by their emphasis grades.
//   * 
//   * @param lines
//   *          the lines to filter.
//   * @return all lines, which are larger than the most common fontsize.
//   */
//  private List<Region> filterByEmphasis(List<Region> lines) {
//    List<Region> largeLines = new ArrayList<Region>();
//    for (int i = 0; i < lines.size(); i++) {
//      Region line = lines.get(i);
//      if (line != null) {
//        float emphasis = computeEmphasis(line);
//
//        textOfFirstPage.append(line.getText());
//        textOfFirstPage.append(" ");
//
//        if (emphasis > stats.mostCommonFontSize
//            || (lines.size() < 10 && emphasis >= stats.mostCommonFontSize)) {
//          line.setIndex(i);
//          largeLines.add(line);
//        }
//      }
//    }
//    return largeLines;
//  }
//
//  /**
//   * Groups the given lines into logical blocks (based on their emphasis
//   * scores).
//   * 
//   * @param lines
//   *          the lines to group.
//   * @return the list of groups.
//   */
//  private List<Region> groupIntoBlocks(List<Region> lines) {
//    List<Region> groups = new ArrayList<Region>();
//    if (lines != null) {
//      Region lastLine = null;
//      for (int i = 0; i < lines.size(); i++) {
//        Region line = lines.get(i);
//
//        float emphasis = computeEmphasis(line);
//
//        if (lastLine != null) {
//          float lastEmphasis = computeEmphasis(lastLine);
//
//          if (emphasis == lastEmphasis
//              && lastLine.getIndex() == line.getIndex() - 1) {
//            lastLine.expand(line);
//            continue;
//          }
//        }
//        groups.add(line);
//        lastLine = line;
//      }
//    }
//    return groups;
//  }
//
//  /**
//   * Computes the match for the given lines.
//   * 
//   * @param lines
//   *          the lines to process.
//   * @param strict
//   *          flag to specify the behavior if the metadata knowledge isn't
//   *          available.
//   * @param disableMK
//   *          flag to sitch on/off the metadata knowledge.
//   * @return the computed match.
//   * @throws IOException
//   *           if matching fails.
//   */
//  private HasMetadata getMatchingRecord(List<Region> lines, boolean strict,
//    boolean disableMK) throws IOException {
//    HasMetadata matchingRecord = null;
//
//    if (lines != null && !lines.isEmpty()) {
//      Collections.sort(lines, new FontsizeComparator());
//
//      String firstTitleCandidate = null;
//      for (int i = 0; i < Math.min(3, lines.size()); i++) {
//        Region line = lines.get(i);
//        System.out.println("line: " + line);
//        if (!disableMK) {
//          if (line != null && line.getText() != null
//              && line.getText().length() > 30) {
//            try {
//              System.out.println("line candidate: " + line.getText());
//              HasMetadata candidate = getMatchingCandidate(line);
//              if (candidate != null) { System.out.println("candidate: " + candidate + " " + candidate.getScore()); }
//              // Only consider the match, if its score is high enough.
//              if (candidate != null && candidate.getScore() >= 0.75) {
//                matchingRecord = candidate;
//                matchingRecord.setAbstract(abstractSb.toString());
//                break;
//              }
//            } catch (IOException e) {
//              if (strict) { throw e; }
//            }
//          }
//        }
//        if (firstTitleCandidate == null && line.getText().length() > 25) {
//          firstTitleCandidate = line.getText();
//        }
//      }
//
//      System.out.println("firstTitle: " + firstTitleCandidate);
//      
//      // Return a default record containing only the first title candidate.
//      if (matchingRecord == null && !strict) {
//        DblpRecord defaultRecord = new DblpRecord();
//        defaultRecord.setTitle(firstTitleCandidate);
//        defaultRecord.setAbstract(abstractSb.toString());
//        matchingRecord = defaultRecord;
//      }
//    }
//    System.out.println("matching: " + matchingRecord);
//    return matchingRecord;
//  }
//
//  // /**
//  // * Creates the metadata knowledge query for the given lines.
//  // *
//  // * @param lines
//  // * the lines
//  // * @param stats
//  // * the stats
//  // * @return the query.
//  // * @throws IOException
//  // * if querying the mkb fails.
//  // */
//  // protected MetadataKnowledgeQuery createMetadataKnowledgeQuery(
//  // List<Region> lines, Stats stats) throws IOException {
//  // int numOfTitleWords = 0;
//  // int numOfAuthorWords = 0;
//  //
//  // MetadataKnowledgeQuery query = new MetadataKnowledgeQuery();
//  //
//  // for (int i = 0; i < lines.size(); i++) {
//  // Region line = lines.get(i);
//  // Matcher m = Patterns.LONG_WORDS_PATTERN.matcher(line.getText());
//  // while (m.find()) {
//  // String word = m.group().trim();
//  //
//  // if (numOfTitleWords < 25) {
//  // int numTitleHits =
//  // mk.getNumOfHits(MetadataKnowledgeQueryType.TITLE, word);
//  // if (numTitleHits > 0) {
//  // query.add(MetadataKnowledgeQueryType.TITLE, word);
//  // numOfTitleWords++;
//  // }
//  // }
//  //
//  // char firstChar = word.charAt(0);
//  // if (Character.isUpperCase(firstChar) && numOfAuthorWords < 10) {
//  // int numAuthorHits =
//  // mk.getNumOfHits(MetadataKnowledgeQueryType.AUTHORS, word);
//  // if (numAuthorHits > 0) {
//  // query.add(MetadataKnowledgeQueryType.AUTHORS, word);
//  // numOfAuthorWords++;
//  // }
//  // }
//  // }
//  // }
//  // query.create();
//  // return query;
//  // }
//
//  /**
//   * Computes the emphasis of the given line.
//   * 
//   * @param line
//   *          the line to process.
//   * @return the emphasis of the line.
//   */
//  protected float computeEmphasis(Region line) {
//    if (line != null) {
//      float emphasis = Math.round(line.getFontsize());
//      emphasis += ((float) line.getFontFlag()) / 10;
//      if (line.isInUpperCase()) {
//        emphasis += .1;
//      }
//      return emphasis;
//    }
//    return 0;
//  }
//
//  // /**
//  // * Computes the linepitch between the given lines.
//  // *
//  // * @param prevLine
//  // * the first line to process.
//  // * @param line
//  // * the second line to process.
//  // * @return the line pitch between the lines.
//  // */
//  // protected float computeLinePitch(Region prevLine, Region line) {
//  // if (prevLine != null && line != null) {
//  // float prevYBottom = prevLine.getY() + prevLine.getHeight();
//  // float curTop = line.getY();
//  // return Math.round(Math.abs(prevYBottom - curTop));
//  // }
//  // return -1;
//  // }
//
//  /**
//   * Determines the best scored candidate for a given text line.
//   * 
//   * @param line
//   *          the line to process.
//   * @return the best scored candidate
//   * @throws IOException
//   *           if quering the mkb fails.
//   */
//  protected HasMetadata getMatchingCandidate(Region line) throws IOException {
//    // Create a query.
//    MetadataKnowledgeQuery query = new MetadataKnowledgeQuery();
//    query.add(MetadataKnowledgeQueryType.TITLE, line.getText());
//    query.create();
//    // Query the metadata knowledge.
//    List<HasMetadata> candidates = mk.query(query, mkMinWaitInterval);
//
//    float maxScore = 0;
//    HasMetadata mostLikelyCandidate = null;
//    if (candidates != null) {
//      for (int i = 0; i < candidates.size(); i++) {
//        HasMetadata candidate = candidates.get(i);
//        if (candidate != null /* && !isStopTitle(candidate.getTitle()) */) {
//          Score score = scoreCandidate(line, candidate);
//          float totalScore =
//              score.titleScore + score.journalScore + score.pageScore
//                  + score.yearScore;
//          LOG.debug(candidate + " -> " + score.titleScore + ", " + totalScore);
//          if ((score.titleScore >= 0.9f || (score.titleScore
//              + score.authorScore + score.yearScore > 1.5))
//              && totalScore > maxScore) {
//            mostLikelyCandidate = candidate;
//            maxScore = totalScore;
//            mostLikelyCandidate.setScore(totalScore);
//          }
//        }
//      }
//    }
//
//    return mostLikelyCandidate;
//  }
//
//  /**
//   * Wraps a given record into a list.
//   * 
//   * @param record
//   *          the record to wrap.
//   * @return a list containing the giveb record.
//   */
//  protected List<HasMetadata> wrap(HasMetadata record) {
//    List<HasMetadata> wrapper = new ArrayList<HasMetadata>();
//    wrapper.add(record);
//    return wrapper;
//  }
//
//  /**
//   * Scores a matching candidate.
//   * 
//   * @param line
//   *          the line from which the candidate has result.
//   * @param candidate
//   *          the candidate to score.
//   * @return the score of the candidate.
//   */
//  protected Score scoreCandidate(Region line, HasMetadata candidate) {
//    float titleScore = 0;
//    float authorsScore = 0;
//    float yearScore = 0;
//    float pageScore = 0;
//    float venueScore = 0;
//    float indexScore = 0;
//
//    if (line != null && candidate != null) {
//      indexScore = (float) (candidate.getScore() / 100);
//
//      LOG.debug("CAND : " + candidate);
//      String s1 = candidate.getTitle();
//      String s2 = line.getText();
//      float maxScore = StringSimilarity.getMaxSmithWatermanScore(s1);
//      float[] simResult = StringSimilarity.smithWaterman(s1, s2);
//      titleScore = simResult[0] / maxScore;
//
//      // Compute the authorsScore.
//      List<String> authors = candidate.getAuthors();
//      if (authors != null && authors.size() > 0) {
//        for (int i = 0; i < authors.size(); i++) {
//          String author = authors.get(i);
//          // Extract the lastname
//          String[] authorWords = author.split(" ");
//          s1 = authorWords[authorWords.length - 1];
//
//          simResult = StringSimilarity.smithWaterman(s1, s2);
//          maxScore = StringSimilarity.getMaxSmithWatermanScore(s1);
//          float authorScore = simResult[0] / maxScore;
//
//          authorsScore += authorScore;
//        }
//        authorsScore /= authors.size();
//      }
//
//      // Compute the journal score.
//      s1 = candidate.getJournal();
//      simResult = StringSimilarity.smithWaterman(s1, s2);
//      maxScore = StringSimilarity.getMaxSmithWatermanScore(s1);
//      if ((simResult[0] / maxScore) == 1) {
//        // page contains the venue.
//        venueScore = 0.1f;
//      }
//
//      // Compute the year score.
//      if (numbersOfFirstPage.contains(candidate.getYear())) {
//        // The page contains the year.
//        yearScore = 0.2f;
//      }
//
//      // Compute the page score.
//      if (numbersOfFirstPage.contains(candidate.getStartPage())) {
//        // The page contains the startpage.
//        pageScore = 0.1f;
//      }
//    }
//
//    LOG.info("  t: " + titleScore + " a:" + authorsScore + " y: " + yearScore
//        + " p: " + pageScore + " v: " + venueScore);
//
//    return new Score(titleScore + indexScore, authorsScore, yearScore,
//        venueScore, pageScore);
//  }
//
//  @Override
//  public String getFulltext() {
//    return null;
//  }
//
//  @Override
//  public long[] getRuntimes() {
//    return new long[1];
//  }
//  
//  @Override
//  public List<Region> getLines() {
//    return lines;
//  }
//}