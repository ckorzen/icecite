package de.freiburg.iif.extraction.references;

import static de.freiburg.iif.utils.Patterns.FIRST_PUNCTUATION_MARK_PATTERN;
import static de.freiburg.iif.utils.Patterns.FIRST_WORD_IN_LINE_PATTERN;
import static de.freiburg.iif.utils.Patterns.LONG_WORDS_PATTERN;
import static de.freiburg.iif.utils.Patterns.LOWERCASED_LINE_START_PATTERN;
import static de.freiburg.iif.utils.Patterns.OPEN_LINE_END_PATTERN;
import static de.freiburg.iif.utils.Patterns.REFERENCE_ANCHOR_PATTERN;
import static de.freiburg.iif.utils.Patterns.UPPERCASED_WORD_PATTERN;
import static de.freiburg.iif.utils.Patterns.YEAR_PATTERN;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.pdfbox.pdmodel.PDDocument;

import de.freiburg.iif.extraction.MetadataMatcher;
import de.freiburg.iif.extraction.metadata.DocumentMetadataMatcher.Stats;
import de.freiburg.iif.extraction.metadataknowledge.InvertedIndexMetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQuery;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQueryType;
import de.freiburg.iif.extraction.stripper.PdfBoxStripper;
import de.freiburg.iif.extraction.stripper.PdfStripper;
import de.freiburg.iif.model.DblpRecord;
import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;
import de.freiburg.iif.model.Score;
import de.freiburg.iif.utils.Patterns;
import de.freiburg.iif.utils.Semantics;
import de.freiburg.iif.utils.StringSimilarity;

/**
 * The class ReferencesMetadataMatcher, that implements MetadataMatcher and can
 * be used to find the record in the metadata knowledge base, referred by a a
 * reference. The matching process uses an inverted index, which is implemented
 * in C++. The inverted index provides a socket, which can be queried by sending
 * ordinary HTTP requests to it. The result is a xml file, containing the
 * result.
 * 
 * @author Claudius Korzen
 * 
 */
public class ReferencesMetadataMatcher implements MetadataMatcher {
  /** The log4j logger */
  protected Log LOG;
  /** The interface to the metadata knowledge base */
  protected MetadataKnowledge mk;
  /** The interface to the pdf extraction tool */
  protected PdfStripper ex;
  /** The most common position of the first author in a line */
  protected int mostCommonPosFirstAuthor;
  /** The StringBuilder for fulltext */
  protected StringBuilder fulltext;
  /** The runtimes */
  protected long[] runtimes;
  /** The textlines */
  protected List<Region> lines;

  /**
   * The constructor of ReferencesMetadataMatcher.
   */
  public ReferencesMetadataMatcher() {
    this.mk = new InvertedIndexMetadataKnowledge();
    this.ex = new PdfBoxStripper();
    this.LOG = LogFactory.getLog(ReferencesMetadataMatcher.class);
    this.mostCommonPosFirstAuthor = -1;
    this.fulltext = new StringBuilder();
    this.runtimes = new long[6];
  }

  @Override
  public List<HasMetadata> match(String pdfFilePath, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException {
    return match(PDDocument.load(pdfFilePath), strict, disableMK, minWaitInterval);
  }

  @Override
  public List<HasMetadata> match(File file, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException {
    return match(PDDocument.load(file), strict, disableMK, minWaitInterval);
  }
  
  @Override
  public List<HasMetadata> match(InputStream is, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException {
    return match(PDDocument.load(is), strict, disableMK, minWaitInterval);
  }
  
  @Override
  public List<HasMetadata> match(PDDocument doc, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException {
    long start = System.currentTimeMillis();
    List<Region> lines = ex.extractLines(doc, 1, Integer.MAX_VALUE, true);
    long end = System.currentTimeMillis();

    runtimes[1] = end - start;

    return match(lines, strict, disableMK, minWaitInterval);
  }

  /**
   * Tries to find the referred metadata records on the basis of the given
   * textlines.
   * 
   * @param lines
   *          the textlines to analyze.
   * @return the matched metadata records.
   * @throws IOException
   *           if the matching process fails.
   */
  public List<HasMetadata> match(List<Region> lines, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException {
    setLines(lines);
    
    fulltext.setLength(0);

    runtimes[2] = 0;
    runtimes[3] = 0;
    runtimes[4] = 0;
    runtimes[5] = 0;

    /** Locate the bibliography */
    long start = System.currentTimeMillis();
    List<Region> bibliography = getBibliographyLines(lines);
    long end = System.currentTimeMillis();

    runtimes[2] += (end - start);

    return identify(bibliography, /* stats */null);
  }

  /**
   * Searches for a bibliography header and returns all lines from the position
   * of the bibliography header to the end of the document. Moreover, this
   * method computes the most common position of the first author in the line.
   * 
   * @param lines
   *          the extracted lines from the pdf file.
   * @return the lines of the bibliography.
   * @throws IOException
   *           if querying the metadata knowledge on author identification
   *           fails.
   */
  protected List<Region> getBibliographyLines(List<Region> lines)
    throws IOException {
    Map<Integer, Integer> posFirstAuthorMap = new HashMap<Integer, Integer>();
    List<Region> bibLines = new ArrayList<Region>();

    if (lines != null) {
      boolean isBibliographyHeaderDetected = false;

      for (int i = 0; i < lines.size(); i++) {
        Region line = lines.get(i);
        if (line != null) {
          if (isBibliographyHeaderDetected) {
            // Compute the position of the first author in the line.
            int posOfFirstAuthor = getPosOfFirstAuthor(line);
            if (posOfFirstAuthor >= 0) {
              int key = posOfFirstAuthor > 0 ? 1 : 0;
              int count =
                  posFirstAuthorMap.containsKey(key) ? posFirstAuthorMap
                      .get(key) : 0;
              // Put the position into the map.
              posFirstAuthorMap.put(key, count + 1);
            }
            bibLines.add(line);
          } else {
            String text = line.getText();
            if (Semantics.isBibliographyHeader(text)) {
              isBibliographyHeaderDetected = true;
            }
          }
          fulltext.append(line.getText());
          fulltext.append(" ");
        }
      }
    }

    // Compute the most common position of the first author in a line.
    int mostCommonPosFirstAuthorOcc = -1;
    for (Entry<Integer, Integer> stat : posFirstAuthorMap.entrySet()) {
      if (stat.getValue() > mostCommonPosFirstAuthorOcc) {
        mostCommonPosFirstAuthorOcc = stat.getValue();
        mostCommonPosFirstAuthor = stat.getKey();
      }
    }
    return bibLines;
  }

  /**
   * Computes the position of the first author in a line.
   * 
   * @param line
   *          the line to analyze.
   * @return the position of the fitrst author in a line (-1 if there is no
   *         author in the line).
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  public int getPosOfFirstAuthor(Region line) throws IOException {
    if (line != null) {
      String text = line.getText();
      if (text != null) {
        text = text.trim();

        Matcher m = FIRST_WORD_IN_LINE_PATTERN.matcher(text);
        int retVal = -1;

        while (m.find()) {
          text = m.group(2);

          if (!text.isEmpty()) {
            char firstChar = text.charAt(0);
            if (!Character.isUpperCase(firstChar)) { return -1; }
            int type = getType(text);

            switch (type) {
            case 0: // The text isn't a title and isn't an author.
              // if (retVal < 0) {
              // retVal = m.start(2);
              // }
              // break;
              return -1;

            case 1: // The text is a title.
              return -1;

            case 2: // The text is an author.
            case 3: // The text can be a title and an author.
              return retVal >= 0 ? retVal : m.start(2);

            default:
              break;
            }
          }
        }
      }
    }
    return -1;
  }

  /**
   * Returns the type of the given text.
   * 
   * @param text
   *          the text to analyze.
   * @return the type of text.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  // TODO: Rename this method to a more reasonable name.
  private int getType(String text) throws IOException {
    int numOfTitleHits = 0;
    int numOfAuthorHits = 0;

    if (text != null && !text.trim().isEmpty()) {
      // Query the metadata knowledge.
      numOfTitleHits =
          mk.getNumOfHits(MetadataKnowledgeQueryType.NUMOFHITS_TITLE, text, 0);
      numOfAuthorHits =
          mk.getNumOfHits(MetadataKnowledgeQueryType.NUMOFHITS_AUTHORS, text, 0);

      if ((numOfTitleHits > 0 && numOfAuthorHits < 2)
          || (numOfTitleHits > 1000 * numOfAuthorHits)) { return 1; }

      if ((numOfAuthorHits > 1 && numOfTitleHits == 0)
          || numOfAuthorHits > 100) { return 2; }

      if (numOfAuthorHits > 1 && numOfTitleHits > 0) { return 3; }
    }
    return 0;
    // if (text != null && !text.trim().isEmpty()) {
    // // Query the metadata knowledge.
    // int numOfTitleHits = mk.getNumOfHits(QueryType.NUMOFHITS_TITLE, text);
    // int numOfAuthorHits = mk.getNumOfHits(QueryType.NUMOFHITS_AUTHORS, text);
    //
    // // boolean titleOutperformsAuthor =
    // // numOfTitleHits > 5 && numOfTitleHits > 10 * numOfAuthorHits;
    // // boolean authorOutperformsTitle = numOfAuthorHits > 10 *
    // numOfTitleHits;
    //
    // if (titleOutperformsAuthor) {
    // return 1;
    // } else if (authorOutperformsTitle) {
    // return 2;
    // } else if (numOfTitleHits > 5 && numOfAuthorHits > 0) { return 3; }
    // }
    // return 0;
  }

  /**
   * Identifies the metadata records, that are included in the given lines.
   * 
   * @param lines
   *          the lines to analyze.
   * @param stats
   *          the statistics about the most common fontsize and the most common
   *          line pitches.
   * @return the list of identified metadata records.
   * @throws IOException
   *           if identifying the metadata records fails.
   * 
   */
  private List<HasMetadata> identify(List<Region> lines, Stats stats)
    throws IOException {
    List<HasMetadata> records = new ArrayList<HasMetadata>();
    StringBuffer sb = new StringBuffer();
    HasMetadata match = null;
    List<Object[]> lineCoordinates = new ArrayList<Object[]>();
    
    for (int i = 0; i < lines.size(); i++) {
      Region prevLine = i > 0 ? lines.get(i - 1) : null;
      Region line = lines.get(i);
      Region nextLine = i < lines.size() - 1 ? lines.get(i + 1) : null;

      if (line != null) {
        LOG.debug("---------------------------------------");
        LOG.debug("LINE: " + line);
        
        /** Determine the type of the line */
        long start = System.currentTimeMillis();
        line.setType(getReferenceLineType2(prevLine, line, nextLine));
        long end = System.currentTimeMillis();

        runtimes[2] += (end - start);
               
        switch (line.getType()) {
          case HEADER:
            match = matchReference(sb.toString());
            if (match != null) {
              match.setLineCoordinates(lineCoordinates);
              records.add(match);
            }
            lineCoordinates = new ArrayList<Object[]>();
            sb.setLength(0);
            sb.append(line.getText());
            sb.append(" ");
            break;
          case BODY:
          case END:
            sb.append(line.getText());
            sb.append(" ");
            break;
        }
        
        Object[] lineCoords = new Object[5];
        lineCoords[0] = line.getPageNumber();
        lineCoords[1] = line.getX();
        lineCoords[2] = line.getYLowerLeft();
        lineCoords[3] = line.getXOfLineEnd();
        lineCoords[4] = line.getYLowerLeft() + line.getHeight();
        lineCoordinates.add(lineCoords);        
      }
    }
    // Don't forget to add the last match.
    match = matchReference(sb.toString());
    if (match != null) {
      match.setLineCoordinates(lineCoordinates);
      records.add(match);
    }
    return records;
  }

  // /**
  // * Computes the ReferenceLineType (HEADER, BODY, END) of a line.
  // *
  // * @param prevLine
  // * the previous line.
  // * @param line
  // * the line to analyze.
  // * @param nextLine
  // * the next line.
  // * @return the {@link ReferenceLineType} for the line.
  // * @throws IOException
  // * if querying the metadata knowledge fails.
  // */
  // protected ReferenceLineType getReferenceLineType(Region prevLine,
  // Region line, Region nextLine) throws IOException {
  // ReferenceLineType type = line != null ? line.getType() : null;
  // ReferenceLineType prevType = prevLine != null ? prevLine.getType() : null;
  //
  // int compareToPrevLineStart = compareLinePositions(prevLine, line, false);
  // int compareToNextLineStart = compareLinePositions(line, nextLine, false);
  // int compareToPrevToNextLineStart = compareLinePositions(prevLine, nextLine,
  // false);
  //
  // // int startIndentations = getStartIndentations(prevLine, line, nextLine);
  // // int endIndentations = getEndIndentations(prevLine, line, nextLine);
  //
  // // startIndentations and endIndentations represent the indentations in the
  // // following manner: consider the integer-value as binary representation,
  // // where the bit at pos 0 detect the indentations of nextLine, the bit at
  // // pos 1 the indentation of line and the bit at pos 2 the indentation of
  // // prevLine.
  // // Example: 4 = 100 means: prevLine is intended, the other lines not.
  //
  // // TODO: Implement bitwise operations.
  // boolean isLineStartAdvanced = (compareToPrevLineStart == 1 ||
  // compareToNextLineStart == -1);
  // boolean isNextLineStartAdvanced = (compareToPrevLineStart == 1 ||
  // compareToPrevToNextLineStart == 1);
  // boolean isLineStartIntended = (compareToPrevLineStart == -1 ||
  // compareToNextLineStart == 1);
  // boolean isLineEndIntended = endIndentations == 2;
  // boolean isNextLineEndIntended = endIndentations == 1;
  // boolean isEqualToPrevLineStartIndentation =
  // startIndentations == 0 || startIndentations == 1
  // || startIndentations == 6;
  //
  // // First, make some assumptions for nextLine.
  // if (isNextLineEndIntended && !isNextLineStartAdvanced &&
  // !isLineStartAdvanced
  // && !endsWithOpenString(nextLine)
  // && !startsWithReferenceAnchor(nextLine)) { // TODO
  // LOG.debug("$(next) END (prevLine and line dominate nextLine)");
  // nextLine.setType(ReferenceLineType.END);
  // }
  //
  // if (isLineStartIntended
  // || (prevLine != null && prevLine.isIndented() &&
  // isEqualToPrevLineStartIndentation)) {
  // // If line start uis intended, it can be a body or end.
  // LOG.debug("$ (line start is intended)");
  // line.setIsIndented(true);
  // }
  //
  // if (type == null) {
  // if (startsWithReferenceAnchor(line)) {
  // // The line is a reference header, if it starts with an anchor.
  // LOG.debug("$HEADER (line starts with anchor)");
  // return ReferenceLineType.HEADER;
  // } else if (prevType == ReferenceLineType.END
  // && !endsWithOpenString(prevLine) && !line.isIndented()) {
  // // The line is a header, if prevLine is END.
  // LOG.debug("$HEADER (prevLine was END)");
  // return ReferenceLineType.HEADER;
  // } else if (startsWithLowerCasedWord(line)) {
  // // The line cannot be a header, if the first word is lowercased.
  // LOG.debug("$ (line starts with lowercased word)");
  // return distinguishBodyAndEnd(prevLine, line, nextLine);
  // } else if (endsWithOpenString(prevLine)) {
  // // The line can't be a header, if prevLine ends with an open string
  // LOG.debug("$ (prevLine ends with open string)");
  // return distinguishBodyAndEnd(prevLine, line, nextLine);
  // } else if (endsWithAuthor(prevLine)) {
  // // The line can't be a header, if prevLine ends with an author.
  // LOG.debug("$ (prevLine ends with author)");
  // return distinguishBodyAndEnd(prevLine, line, nextLine);
  // } else if (isLineStartAdvanced) {
  // // The line is a reference header, if is adavnced to prevLine or
  // // nextLine.
  // LOG.debug("$HEADER (line is advanced to prevLine or nextLine)");
  // return ReferenceLineType.HEADER;
  // } else if (line.isIndented()) {
  // // If line start uis intended, it can be a body or end.
  // LOG.debug("$ (line start is intended)");
  // line.setIsIndented(true);
  // return distinguishBodyAndEnd(prevLine, line, nextLine);
  // } else if (isLineEndIntended) {
  // // The line is a reference end, if the end of line is intended.
  // LOG.debug("$END (line end is intended)");
  // return ReferenceLineType.END;
  // } else if (endIndentations == 4 && (prevLine != null &&
  // prevLine.isIndented() && isEqualToPrevLineStartIndentation)) {
  // // The line is a reference header, if is starts with an author.
  // LOG.debug("$HEADER (line and next dominate prev)");
  // return ReferenceLineType.HEADER;
  // } else if (startsWithAuthor2(line)) {
  // // The line is a reference header, if is starts with an author.
  // LOG.debug("$HEADER (line starts with author)");
  // return ReferenceLineType.HEADER;
  // } else {
  // // No condition met, assume a reference body.
  // LOG.debug("$BODY (no condition met)");
  // return ReferenceLineType.BODY;
  // }
  // }
  //
  // return type;
  // }

  /**
   * Returns the type of the given reference line.
   * 
   * @param prevLine
   *          the previous line of line to process.
   * @param line
   *          the line to process.
   * @param nextLine
   *          the next line of line to process.
   * @return the type of line.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  protected ReferenceLineType getReferenceLineType2(Region prevLine,
    Region line, Region nextLine) throws IOException {
    ReferenceLineType type = line != null ? line.getType() : null;
    ReferenceLineType prevType = prevLine != null ? prevLine.getType() : null;

    int compareToPrevLineStart = compareLinePositions(prevLine, line, false);
    int compareToNextLineStart = compareLinePositions(line, nextLine, false);
    int compareToPrevToNextLineStart =
        compareLinePositions(prevLine, nextLine, false);
    int compareToPrevLineEnd = compareLinePositions(prevLine, line, true);
    int compareToNextLineEnd = compareLinePositions(line, nextLine, true);
    // int compareToPrevToNextLineEnd =
    // compareLinePositions(prevLine, nextLine, true);

    boolean isLineStartAdvanced =
        (compareToPrevLineStart == 1 || compareToNextLineStart == -1);
    boolean isNextLineStartAdvanced =
        (compareToPrevLineStart == 1 || compareToPrevToNextLineStart == 1);
    boolean isLineStartIntended = (compareToPrevLineStart == -1/*
                                                                * ||
                                                                * compareToNextLineStart
                                                                * == 1
                                                                */);
    // boolean isLineEndIntended =
    // compareToPrevLineEnd == 1 && compareToNextLineEnd == -1
    // && compareToPrevToNextLineEnd == 0;
    boolean isNextLineEndIntended =
        compareToPrevLineEnd == 0 && compareToNextLineEnd == 1;
    boolean isPrevLineEndIntended =
        compareToPrevLineEnd == -1 && compareToNextLineEnd == 0;
    boolean isEqualToPrevLineStartIndentation = compareToPrevLineStart == 0;

    int nextTextLength =
        nextLine != null && nextLine.getText() != null ? nextLine.getText()
            .length() : Integer.MAX_VALUE;

    // First, make some assumptions for nextLine.
    if ((isNextLineEndIntended || nextTextLength < 20)
        && !isNextLineStartAdvanced && !isLineStartAdvanced
        && !endsWithOpenString(nextLine)
        && !startsWithReferenceAnchor(nextLine) && compareToPrevLineStart == 0) { // TODO
      LOG.debug("$(next) END (prevLine and line dominate nextLine)");
      nextLine.setType(ReferenceLineType.END);
    }

    if (isLineStartIntended
        || (prevLine != null && prevLine.isIndented() && isEqualToPrevLineStartIndentation)) {
      // If line start uis intended, it can be a body or end.
      LOG.debug("$ (line start is intended)");
      line.setIsIndented(true);
    }

    boolean startsWithReferencesAnchor = startsWithReferenceAnchor(line);
    boolean isPrevLineEnd = prevType == ReferenceLineType.END;
    boolean startsWithAuthor = startsWithAuthor2(line);
    boolean prevEndsWithOpenString = endsWithOpenString(prevLine);
    boolean prevEndsWithAuthor = endsWithAuthor(prevLine);
    boolean startsWithLowercaseWord = startsWithLowercaseWord(line);

    if (type == null) {
      LOG.debug("startsWithAnchor: " + startsWithReferencesAnchor);
      LOG.debug("startsWithAuthor: " + startsWithAuthor);
      LOG.debug("prevEndsWithAuthor: " + prevEndsWithAuthor);
      LOG.debug("isLineAdvanced: " + isLineStartAdvanced);
      LOG.debug("isPrevLineEnd: " + isPrevLineEnd);
      LOG.debug("isIndented: " + line.isIndented());
      LOG.debug("endsWithOpenString: " + prevEndsWithOpenString);
      LOG.debug("startsWithLowercaseWord: " + startsWithLowercaseWord);

      if (isReferenceEnd(prevLine, line, nextLine)
          || line.getText().length() < 20) {
        LOG.debug("$END");
        return ReferenceLineType.END;
      } else if (isPrevLineEnd) {
        LOG.debug("$HEADER (prev is end)");
        return ReferenceLineType.HEADER;
      } else if (startsWithLowercaseWord) {
        return ReferenceLineType.BODY;
      } else if (line.isIndented()) {
        LOG.debug("$BODY (is indented or starts with lowercase word)");
        return ReferenceLineType.BODY;
      } else if (prevEndsWithOpenString) {
        LOG.debug("$BODY (prev ends with open string)");
        return ReferenceLineType.BODY;
      } else if (startsWithReferencesAnchor || isLineStartAdvanced
          || isPrevLineEndIntended
          || (startsWithAuthor && !prevEndsWithAuthor)) {
        // The line is a reference header, if it starts with an anchor.
        return ReferenceLineType.HEADER;
      } else {
        return ReferenceLineType.BODY;
      }
    }
    return type;
  }

  /**
   * Returns true, if the given line starts with an lowercase word.
   * 
   * @param line
   *          the line to process.
   * @return true, if the line starts with an lowercase word.
   */
  private boolean startsWithLowercaseWord(Region line) {
    if (line != null && line.getText() != null) {
      String text = line.getText();
      Matcher m =
          Patterns.LINE_STARTS_WITH_LOWERCASE_WORD_PATTERN.matcher(text);
      return m.find();
    }
    return false;
  }

  /**
   * Returns true, if the given line denotes a reference end.
   * 
   * @param prevLine
   *          the previous line of the line to process.
   * @param line
   *          the line to process.
   * @param nextLine
   *          the next line of the line to process.
   * @return true, if the line denotes a reference end.
   */
  private boolean
    isReferenceEnd(Region prevLine, Region line, Region nextLine) {
    // Line is a reference body or a reference end.
    if (endsWithOpenString(line)) {
      LOG.debug("$BODY (line ends with open string)");
      return false;
    } else {
      LOG.debug("*****");
      int endIndentations = getEndIndentations(prevLine, line, nextLine);
      if (endIndentations == 2) {
        LOG.debug("$END (prevLine and nextLine dominate line)");
        return true;
      } else {
        LOG.debug("$BODY (prevLine and nextLine don't dominate line)");
        return false;
      }
    }
  }

  // /**
  // * Compares the start indentations of three line. The return value have to
  // be
  // * considered as binary value. If the return value is 6 = 110, the previous
  // * and the current line are intended (but not the next line).
  // *
  // * @param prevLine
  // * the previous line.
  // * @param line
  // * the line to analyze.
  // * @param nextLine
  // * the next line.
  // * @return a integer, identifying the startIndentations of the three lines.
  // */
  // private int getStartIndentations(Region prevLine, Region line,
  // Region nextLine) {
  // int compareToPrevLineStart = compareLinePositions(prevLine, line, false);
  // LOG.debug("Compare to next line start");
  // int compareToNextLineStart = compareLinePositions(line, nextLine, false);
  //
  // // Ignore the cases, where lines don't overlap.
  // if (Math.abs(compareToPrevLineStart) > 1) {
  // compareToPrevLineStart = 2;
  // }
  // if (Math.abs(compareToNextLineStart) > 1) {
  // compareToNextLineStart = 2;
  // }
  //
  // if (compareToPrevLineStart == 0 && compareToNextLineStart == -1) {
  // return 1;
  // } else if (compareToPrevLineStart == -1 && compareToNextLineStart == 1) {
  // return 2;
  // } else if (compareToPrevLineStart == -1 && compareToNextLineStart == 0) {
  // return 3;
  // } else if (compareToPrevLineStart == 1 && compareToNextLineStart == 0) {
  // return 4;
  // } else if (compareToPrevLineStart == 1 && compareToNextLineStart == -1) {
  // return 5;
  // } else if (compareToPrevLineStart == 0 && compareToNextLineStart == 1) {
  // return 6;
  // } else {
  // return 0;
  // }
  // }

  /**
   * Compares the end indentations of three line. The return value have to be
   * considered as binary value. If the return value is 6 = 110, the previous
   * and the current line are intended (but not the next line).
   * 
   * @param prevLine
   *          the previous line.
   * @param line
   *          the line to analyze.
   * @param nextLine
   *          the next line.
   * @return a integer, identifying the endIndentations of the three lines.
   */
  private int
    getEndIndentations(Region prevLine, Region line, Region nextLine) {
    int compareToPrevLineEnd = compareLinePositions(prevLine, line, true);
    int compareToNextLineEnd = compareLinePositions(line, nextLine, true);
    int comparePrevToNextLineEnd =
        compareLinePositions(prevLine, nextLine, true);

    if (compareToPrevLineEnd == 0 && compareToNextLineEnd == 1) {
      return 1;
    } else if (compareToPrevLineEnd == 1 && compareToNextLineEnd == -1
        && comparePrevToNextLineEnd == 0) {
      return 2;
    } else if (compareToPrevLineEnd == 1 && compareToNextLineEnd == 0) {
      return 3;
    } else if (compareToPrevLineEnd == -1 && compareToNextLineEnd == 0) {
      return 4;
    } else if (compareToPrevLineEnd == -1 && compareToNextLineEnd == 1) {
      return 5;
    } else if (compareToPrevLineEnd == 0 && compareToNextLineEnd == -1) {
      return 6;
    } else {
      return 0;
    }
  }

  /**
   * Distinguishes a reference body from a reference end.
   * 
   * @param prevLine
   *          the previous line.
   * @param line
   *          the line to analyze.
   * @param nextLine
   *          the next line.
   * @return the {@link ReferenceLineType} for the line.
   */
  protected ReferenceLineType distinguishBodyAndEnd(Region prevLine,
    Region line, Region nextLine) {
    // Line is a reference body or a reference end.
    if (endsWithOpenString(line)) {
      LOG.debug("$BODY (line ends with open string)");
      return ReferenceLineType.BODY;
    } else {
      LOG.debug("*****");
      int endIndentations = getEndIndentations(prevLine, line, nextLine);
      if (endIndentations == 2) {
        LOG.debug("$END (prevLine and nextLine dominate line)");
        return ReferenceLineType.END;
      } else {
        LOG.debug("$BODY (prevLine and nextLine don't dominate line)");
        return ReferenceLineType.BODY;
      }
    }
  }

  /**
   * Returns true, if the line starts with an author and the position of the
   * author is equal to mostCommonPosFirstAuthor.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the line starts with an author.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  protected boolean startsWithAuthor2(Region line) throws IOException {
    int posOfFirstAuthor = getPosOfFirstAuthor(line);
    if (posOfFirstAuthor == 0 && mostCommonPosFirstAuthor == 0
        || posOfFirstAuthor > 0 && mostCommonPosFirstAuthor > 0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * Returns true, if the given line starts with an lowercased word, that
   * contains at least 3 characters.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the given line starts with an lowercased word.
   */
  protected boolean startsWithLowerCasedWord(Region line) {
    return matches(line, LOWERCASED_LINE_START_PATTERN);
  }

  /**
   * Returns true, if the given line ends with an open string (a string that
   * suggests a following line like "and", "of", etc.).
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the given line starts with an lowercased word.
   */
  protected boolean endsWithOpenString(Region line) {
    return matches(line, OPEN_LINE_END_PATTERN);
  }

  /**
   * Returns true, if the given line contains a reference anchor.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the given line contains a reference anchor.
   */
  protected boolean startsWithReferenceAnchor(Region line) {
    if (line != null) {
      String text = line.getText();
      if (text != null) {
        // Remove all whitespaces, to meet anchors like "[ 1 ]" (instead of
        // "[1]").
        text = text.replaceAll("\\s", "");

        Matcher m = REFERENCE_ANCHOR_PATTERN.matcher(text);
        return m.find() && m.group(2).length() > 3;
      }
    }
    return false;
  }

  /**
   * This method determines, if the given line starts with an author name.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the given string starts with an author name.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  protected boolean endsWithAuthor(Region line) throws IOException {
    // Finds all words (including diacritics) with length >=2 (except "and").
    Pattern p = Pattern.compile("[\\p{L}\\p{M}0-9]{2,}\\b(?<!\\band)");
    if (line != null) {
      String text = line.getText();
      if (text != null) {
        text = text.trim();
        if (!text.isEmpty()) {
          Matcher m = p.matcher(text);
          String lastWord = "";
          while (m.find()) {
            // Extract the last word.
            lastWord = text.substring(m.start(), m.end());
          }

          // Consider the word only when the first character is in uppercase.
          if (!lastWord.isEmpty()) {
            char firstChar = lastWord.charAt(0);
            if (Character.isUpperCase(firstChar)) { return isAuthor(lastWord); }
          }
        }
      }
    }
    return false;
  }

  /**
   * Returns true, if the text of the given line matches the given pattern.
   * 
   * @param line
   *          the line to analyze.
   * @param pattern
   *          the pattern to apply.
   * @return true, if the text of the given line matches the given pattern.
   */
  protected boolean matches(Region line, Pattern pattern) {
    if (line != null && pattern != null) {
      String text = line.getText();
      if (text != null) {
        Matcher m = pattern.matcher(text);
        return m.find();
      }
    }
    return false;
  }

  /**
   * Compares the horizontal position of two given lines. Returns -1, if line1
   * comes before line2 (with respect to the horizontal position); 1 if line2
   * comes before line1 and 0 if the horizontal positions of both lines are
   * equal.
   * 
   * @param line1
   *          the first line to analyze.
   * @param line2
   *          the second line to analyze.
   * @param useLineEnds
   *          if true, xOfLineEnd of both lines is used for comparison,
   *          otherwise x is used.
   * @return -1, if line1 comes before line2 (with respect to the horizontal
   *         position); 1 if line2 comes before line1 and 0 if the horizontal
   *         positions of both lines are equal.
   */
  public int compareLinePositions(Region line1, Region line2,
    boolean useLineEnds) {
    if (line1 == line2) { return 0; }
    if (line1 == null) { return 2; }
    if (line2 == null) { return -2; }

    // If compareLineEnds == true, reflect the line: (x=10,y=30) -> (x=30,y=50)
    double x1 = useLineEnds ? -1 * line2.getXOfLineEnd() : line1.getX();
    // y is the x-coordinate of the line end.
    double y1 = useLineEnds ? -1 * line2.getX() : line1.getXOfLineEnd();

    // If compareLineEnds == true, reflect the line: (x=10,y=30) -> (x=30,y=50)
    double x2 = useLineEnds ? -1 * line1.getXOfLineEnd() : line2.getX();
    // y is the x-coordinate of the line end.
    double y2 = useLineEnds ? -1 * line1.getX() : line2.getXOfLineEnd();

    // The tolerance that (x2 - x1) must exceed so that the line is identified
    // as advanced to nextLine (~ 2 * width of chars).
    double tolerance =
        Math.max(0.5, Math.abs(x1 - y1) / line1.getText().length());
    // x2 must be in range [x1 + tolerance, x1 + line.getWidth]. The upper
    // bound is introduced to ignore comparisons between lines of different
    // columns.
    double delta = Math.abs(x1 - x2);

    if (delta <= tolerance) {
      return 0;
    } else if (x2 > x1) {
      if (x2 > y1) { return -2; }
      return -1;
    } else if (x1 > x2) {
      if (x1 > y2) { return 2; }
      return 1;
    }
    return 0;
  }

  /**
   * Matches an extracted string to a record of the metadata knowledge base.
   * 
   * @param reference
   *          the string to match.
   * @return the matched metadata record.
   * @throws IOException
   *           if matching the given string fails.
   */
  public HasMetadata matchReference(String reference) throws IOException {
    LOG.debug("Matching reference: " + reference);
    if (reference != null && !reference.isEmpty()) {
      long start = System.currentTimeMillis();
      MetadataKnowledgeQuery query = createMetadataKnowledgeQuery(reference);
      long end = System.currentTimeMillis();

      runtimes[3] += (end - start);

      if (query != null) {
        LOG.debug(" Query: " + query);
        // Get leading records doesn't return a null value.
        HasMetadata match = getLeadingRecord(query, reference);
        if (match.getKey() == null) {
          LOG.debug("  No match found.");
          // No leading match found. Retry the matching process without
          // others.
          if (query.contains(MetadataKnowledgeQueryType.OTHER)) {
            LOG.debug("  Remove other-parameter.");
            query.remove(MetadataKnowledgeQueryType.OTHER);
            LOG.debug(" Query: " + query);
            match = getLeadingRecord(query, reference);
          }

          if (match.getKey() == null) {
            LOG.debug("  No match found.");
            // No leading match found. Retry the matching process without
            // authors.
            // if (query.contains(MetadataKnowledgeQueryType.AUTHORS)) {
            if (query.contains(MetadataKnowledgeQueryType.TITLE)) {
              LOG.debug("  Remove title-parameter.");
              // query.remove(MetadataKnowledgeQueryType.AUTHORS);
              query.remove(MetadataKnowledgeQueryType.TITLE);
              match = getLeadingRecord(query, reference);
            }
          }
        }
        return match;
      }
    }
    return null;
  }

  /**
   * Creates the query for the given reference to query the metadata knowledge
   * query.
   * 
   * @param reference
   *          the reference to process.
   * @return the metadata knowledge query.
   * @throws IOException
   *           if creating the query fails.
   */
  protected MetadataKnowledgeQuery createMetadataKnowledgeQuery(
    String reference) throws IOException {
    if (reference != null) {
      MetadataKnowledgeQuery query = new MetadataKnowledgeQuery();

      Matcher m = LONG_WORDS_PATTERN.matcher(reference);
//      int numOfAuthorWords = 0;
      int numOfTitleWords = 0;
      int numOfOtherWords = 0;

      // Pattern p = Pattern.compile("[A-Z]{1}[a-z]{1,}");
      // Matcher m2 = p.matcher(reference);
      // while (m2.find()) {
      // String word = m2.group().trim();
      // if (!word.isEmpty()) {
      // int type = getType(word);
      //
      // if (type == 2 && numOfTitleWords == 0) {
      // query.add(MetadataKnowledgeQueryType.AUTHORS, word);
      // numOfAuthorWords++;
      // }
      // }
      // }

      while (m.find()) {
        String word = m.group().trim();
        if (!word.isEmpty()) {
          char firstChar = word.charAt(0);

          // int numOfTitleHits =
          // mk.getNumOfHits(MetadataKnowledgeQueryType.NUMOFHITS_TITLE, word);
          // int numOfAuthorHits =
          // mk.getNumOfHits(MetadataKnowledgeQueryType.NUMOFHITS_AUTHORS,
          // word);
          //
          // boolean isTitle = numOfTitleHits > 0 && numOfAuthorHits < 50 &&
          // numOfTitleHits > numOfAuthorHits;
          // boolean isAuthor = numOfAuthorHits > 0;
          int type = getType(word);
          if (type == 3) {
            if (word.length() > 3 /* && numOfTitleHits < 20000 */) {
              query.add(MetadataKnowledgeQueryType.AUTHORS, word);
              query.add(MetadataKnowledgeQueryType.TITLE, word);
              numOfTitleWords++;
//              numOfAuthorWords++;
            }
          } else if (type == 1) {
            if (word.length() > 3 /* && numOfTitleHits < 20000 */) {
              query.add(MetadataKnowledgeQueryType.TITLE, word);
              numOfTitleWords++;
            }
          } else if (type == 2) {
            if (numOfTitleWords == 0 && Character.isUpperCase(firstChar)) {
              query.add(MetadataKnowledgeQueryType.AUTHORS, word);
//              numOfAuthorWords++;
            }
          }
        }
        if (numOfTitleWords + numOfTitleWords + numOfOtherWords >= 10) {
          break;
        }
      }

      query.create();

      return query;
    }
    return null;
  }

  /**
   * Returns the matching record, if exists (that means there is a record, whose
   * score is large enough to be consodered as match).
   * 
   * @param query
   *          the metadata knowledge query.
   * @param reference
   *          the extracted reference.
   * @return the matching record if exists. Null otherwise.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  protected HasMetadata getLeadingRecord(MetadataKnowledgeQuery query,
    String reference) throws IOException {
    if (query != null && reference != null) {
      long start = System.currentTimeMillis();
      List<HasMetadata> records = mk.query(query, 0);
      long end = System.currentTimeMillis();

      runtimes[4] += (end - start);

      HasMetadata match = new DblpRecord();

      if (records != null) {
        // Score the records and return the record with the highest score.
        for (int i = 0; i < Math.min(records.size(), 1000); i++) {
          HasMetadata record = records.get(i);

          start = System.currentTimeMillis();
          Score score = scoreRecord(reference, record);
          end = System.currentTimeMillis();
          runtimes[5] += (end - start);

          if (score != null) {
            float titleScore = score.titleScore;
            float authorsScore = score.authorScore;
            float yearScore = score.yearScore;
            float journalScore = score.journalScore;
            float pageScore = score.pageScore;

            // float totalScore = metadataScore + publicationScore + pageScore;

            LOG.debug("   " + record);
            LOG.debug("     t: " + titleScore + " a: " + authorsScore + " y: "
                + yearScore + ", j: " + journalScore + ", p: " + pageScore);

            float totalScore =
                titleScore + authorsScore + yearScore + journalScore
                    + pageScore;

            boolean isLeading = false;
            if (yearScore > 0) {
              if ((titleScore > 0.75 && (titleScore * authorsScore) > 0.35)
                  || totalScore > 3.5) {
                isLeading = true;
              }
              // if (titleScore > 0.9) { isLeading = true; }
              // // if (firstHalfTitleScore > 0.9 && secondHalfTitleScore > 0.2
              // && authorScore > 0.5) { isLeading = true; }
              // if (titleScore > 0.75 && authorScore > 0.5) { isLeading = true;
              // }
            }

            // Check, if the current score exceeds the maxScore.
            if (isLeading && totalScore > match.getScore()) { // MAYBE:
                                                              // titleScore?
              record.setScore(totalScore);
              match = record;
            }
          }
        }
      }
      match.setRaw(reference);
      return match;
    }
    return null;
  }

  /**
   * Scores a record against a extracted reference.
   * 
   * @param reference
   *          the extracted reference.
   * @param record
   *          the record to score.
   * @return the score fort he record.
   */
  protected Score scoreRecord(String reference, HasMetadata record) {
    if (record != null && reference != null) {
      float authorsScore = 0;
      float startPageScore = 0;
      float endPageScore = 0;

      /** The numbers contained in the first page */
      List<Integer> numbers = new ArrayList<Integer>();
      Pattern p = Patterns.NUMBERS_PATTERN;
      Matcher m = p.matcher(reference);

      while (m.find()) {
        try {
          int number = Integer.parseInt(m.group());
          numbers.add(number);
        } catch (Exception e) {
          // Nothing to do.
        }
      }

      if (record.getStartPage() > 0) {
        if (numbers.contains(record.getStartPage())) {
          startPageScore = 1;
        } else {
          startPageScore = -1;
        }
      }

      if (record.getEndPage() > 0) {
        if (numbers.contains(record.getEndPage())) {
          endPageScore = 1;
        } else {
          endPageScore = -1;
        }
      }
      float pageScore = 0;
      if (startPageScore < 0 && endPageScore < 0) {
        pageScore = -1;
      } else if (startPageScore > 0 || endPageScore > 0) {
        pageScore = 1;
      }

      // Compute the authorsScore.
      List<String> authors = record.getAuthors();
      int numAuthors = 0;
      if (authors != null) {
        for (int i = 0; i < authors.size(); i++) {
          String author = authors.get(i);
          // Score the lastname of each author
          String[] authorWords = author.split(" ");
          String lastname = authorWords[authorWords.length - 1];

          if (!lastname.isEmpty()) {
            float[] simResult =
                StringSimilarity.smithWaterman(lastname,
                    reference.substring(0, reference.length() / 2));
            float maxAuthorScore =
                StringSimilarity.getMaxSmithWatermanScore(lastname);
            float authorScore = simResult[0] / maxAuthorScore;

            // if (i == 0) {
            // LOG.info("    score of firstAuthor: " + authorScore);
            // }
            // if (i == 0 && authorScore < 0.5f) {
            // break;
            // }
            authorsScore += authorScore;

            numAuthors++;
          }
        }
        if (numAuthors != 0) {
          authorsScore /= numAuthors;
        }
      }

      // Compute the titleScore.
      float titleScore = 0;
      String title = record.getTitle();
      if (title != null && !title.isEmpty()) {
        // String[] titleFragments = title.split("\\s{1,}-\\s{1,}");
        // title = titleFragments[0];

        float[] simResult = StringSimilarity.smithWaterman(reference, title);
        titleScore = simResult[0];
        float maxTitleScore = StringSimilarity.getMaxSmithWatermanScore(title);
        titleScore = titleScore / maxTitleScore;
      }

      // Compute the journalScore.
      float journalScore = 0;
      String journal = record.getJournal();
      if (journal != null && !journal.isEmpty()) {
        float[] simResult = StringSimilarity.smithWaterman(reference, journal);
        journalScore = simResult[0];
        float maxJournalScore =
            StringSimilarity.getMaxSmithWatermanScore(journal);
        journalScore = journalScore / maxJournalScore;
      }

      float yearScore = 1;
      m = YEAR_PATTERN.matcher(reference);
      if (m.find()) {
        int year = Integer.parseInt(m.group(0));

        if (year > 2015 || year < record.getYear() - 1
            || year > record.getYear() + 1) {
          yearScore = 0;
        }
      }

      return new Score(titleScore, authorsScore, yearScore, journalScore,
          pageScore);
    }
    return null;
  }

  /**
   * Filters all words from the given text, whose first chars are in uppercase.
   * 
   * @param text
   *          the text to process.
   * @return A string, containing all words from the given text; whose first
   *         chars are in uppercase.
   */
  protected Map<MetadataKnowledgeQueryType, String> createQuery(String text) {
    // if (text != null && !text.isEmpty()) {
    // Map<QueryType, String> query = new HashMap<QueryType, String>();
    // Matcher m = FIRST_PUNCTUATION_MARK_PATTERN.matcher(text);
    //
    // String authorQuery = "";
    // String titleQuery = text;
    //
    // if (m.find()) {
    // String fuzzyAuthorQuery = text.substring(0, m.start());
    // titleQuery = text.substring(m.end());
    //
    // LOG.debug("FUZZY: " + fuzzyAuthorQuery);
    // LOG.debug("TITLE: " + titleQuery);
    //
    // StringBuilder authorSb = new StringBuilder();
    // m = UPPERCASED_WORD_PATTERN.matcher(fuzzyAuthorQuery);
    // while (m.find()) {
    // authorSb.append(fuzzyAuthorQuery.substring(m.start(), m.end()));
    // authorSb.append(" ");
    // }
    // authorQuery = authorSb.toString();
    // }
    //
    // query.put(QueryType.AUTHORS, authorQuery);
    // query.put(QueryType.TITLE, titleQuery);
    //
    // LOG.debug("**QUERY: " + query);
    //
    // return query;
    // }
    // return null;
    if (text != null && !text.isEmpty()) {
      Map<MetadataKnowledgeQueryType, String> query =
          new HashMap<MetadataKnowledgeQueryType, String>();

      Matcher m = LONG_WORDS_PATTERN.matcher(text);

      StringBuilder titleQuery = new StringBuilder();
      while (m.find()) {
        titleQuery.append(m.group());
        titleQuery.append(" ");
      }

      // Check, if there is a year available.
      m = YEAR_PATTERN.matcher(text);
      if (m.find()) {
        // Year is available.
        query.put(MetadataKnowledgeQueryType.YEAR, m.group(1));
        query.put(MetadataKnowledgeQueryType.TITLE, titleQuery.toString());
        return query;
      } else {
        // Year isn't available.
        String authorQuery = "";

        m = FIRST_PUNCTUATION_MARK_PATTERN.matcher(text);

        if (m.find()) {
          String fuzzyAuthorQuery = text.substring(0, m.start());

          StringBuilder authorSb = new StringBuilder();
          m = UPPERCASED_WORD_PATTERN.matcher(fuzzyAuthorQuery);
          while (m.find()) {
            authorSb.append(fuzzyAuthorQuery.substring(m.start(), m.end()));
            authorSb.append(" ");
          }
          authorQuery = authorSb.toString();
        }

        query.put(MetadataKnowledgeQueryType.AUTHORS, authorQuery);
        query.put(MetadataKnowledgeQueryType.TITLE, titleQuery.toString());

        return query;
      }
    }
    return null;
  }

  /**
   * Creates a query for metadata knowledge.
   * 
   * @param text
   *          the query text.
   * @param useYear
   *          if the year should be included into the query.
   * @return the query.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  protected Map<MetadataKnowledgeQueryType, String> createQuery(String text,
    boolean useYear) throws IOException {
    if (text != null && !text.isEmpty()) {
      Map<MetadataKnowledgeQueryType, String> query =
          new HashMap<MetadataKnowledgeQueryType, String>();

      Matcher m = YEAR_PATTERN.matcher(text);
      if (m.find()) {
        query.put(MetadataKnowledgeQueryType.YEAR, m.group(1));
      }

      Pattern p = Pattern.compile("[;:\\.\\(\\)]");
      String[] fragments = p.split(text);
      for (int i = 0; i < Math.min(2, fragments.length); i++) {
        query.remove(MetadataKnowledgeQueryType.TITLE);

        String fragment = fragments[i];

        m = UPPERCASED_WORD_PATTERN.matcher(fragment);
        StringBuilder sb = new StringBuilder();
        int k = 0;
        while (m.find()) {
          int numHits =
              mk.getNumOfHits(MetadataKnowledgeQueryType.NUMOFHITS_AUTHORS,
                  m.group(), 0);
          if (numHits > 0) {
            sb.append(m.group());
            sb.append(" ");
            if (++k > 5) {
              break;
            }
          }
        }

        if (sb.length() > 0) {
          query.put(MetadataKnowledgeQueryType.TITLE, sb.toString());
        }
      }
    }
    return null;
  }

  // protected Map<MetadataKnowledgeQueryType, String> createQuery2(
  // String reference) throws IOException {
  // if (reference != null) {
  // Map<MetadataKnowledgeQueryType, String> query =
  // new HashMap<MetadataKnowledgeQueryType, String>();
  //
  // Matcher m = LONG_WORDS_PATTERN.matcher(reference);
  // StringBuilder authors = new StringBuilder();
  // StringBuilder title = new StringBuilder();
  // StringBuilder other = new StringBuilder();
  // int numOfAuthorWords = 0;
  // int numOfTitleWords = 0;
  // int numOfOtherWords = 0;
  //
  // while (m.find()) {
  // String word = m.group();
  // if (!word.isEmpty()) {
  // char firstChar = word.charAt(0);
  // int type = getType(word);
  //
  // if (type == 1 && word.length() >= 4) {
  // title.append(word);
  // title.append(" ");
  // numOfTitleWords++;
  // }
  //
  // if (type == 2 && numOfTitleWords == 0
  // && Character.isUpperCase(firstChar)) {
  // authors.append(word);
  // authors.append(" ");
  // numOfAuthorWords++;
  // }
  //
  // if (type == 3 && word.length() >= 4) {
  // other.append(word);
  // other.append(" ");
  // numOfOtherWords++;
  // }
  // }
  // }
  // query.put(MetadataKnowledgeQueryType.TITLE, title.toString());
  // query.put(MetadataKnowledgeQueryType.AUTHORS, authors.toString());
  // query.put(MetadataKnowledgeQueryType.OTHER, other.toString());
  //
  // return query;
  // }
  // return null;
  // }

  /**
   * This method determines, if the given line starts with an author name.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the given string starts with an author name.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  protected boolean startsWithAuthor(Region line) throws IOException {
    // \p{L} matches a single character that has a given Unicode property. L
    // stands for letter
    // Finds all words (including diacritics) with length >=2.
    Pattern p = Pattern.compile("(^|\\s|\\.)([\\p{L}\\p{M}]{2,})");
    if (line != null) {
      String text = line.getText();
      if (text != null) {
        text = text.trim();
        if (!text.isEmpty()) {
          Matcher m = p.matcher(text);

          if (m.find()) {
            // Extract the first word.
            text = m.group(2);
            // Consider the word only when the first character is in uppercase.
            char firstChar = text.charAt(0);
            if (Character.isUpperCase(firstChar)) { return isAuthor(text); }
          }
        }
      }
    }
    return false;
  }

  /**
   * Returns true, if the given text describes an author.
   * 
   * @param word
   *          the text to analyze (without punctuation marks).
   * @return true, if the given text describes an author.
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  protected boolean isAuthor(String word) throws IOException {
    if (word != null && !word.trim().isEmpty()) {
      // Query the metadata knowledge.
      int numOfAuthorHits =
          mk.getNumOfHits(MetadataKnowledgeQueryType.NUMOFHITS_AUTHORS, word, 0);
      int numOfTitleHits =
          mk.getNumOfHits(MetadataKnowledgeQueryType.NUMOFHITS_TITLE, word, 0);

      LOG.debug("numOfAuthorHits: " + numOfAuthorHits);
      LOG.debug("numOfTitleHits: " + numOfTitleHits);
      LOG.debug("isAuthor: " + (numOfAuthorHits >= numOfTitleHits));
      return (numOfAuthorHits > 0)
          && (numOfAuthorHits >= 0.5 * numOfTitleHits);
    }
    return false;
  }

  /**
   * Enumeration of various types for a line.
   * 
   * @author Claudius Korzen
   * 
   */
  public enum ReferenceLineType {
    /** The type of a reference header */
    HEADER(),
    /** THe type of a reference body. */
    BODY(),
    /** The type of a reference end. */
    END();
  }

  /**
   * The class pair to store two arbitrary values together.
   * 
   * @author Claudius Korzen
   * 
   * @param <S>
   *          the type of first value.
   * @param <T>
   *          the type of second value.
   */
  public class Pair<S, T> {
    /** The first value */
    public S first;
    /** The second value */
    public T second;

    /**
     * The constructor.
     * 
     * @param first
     *          the first value.
     * @param second
     *          the second value.
     */
    public Pair(S first, T second) {
      this.first = first;
      this.second = second;
    }
  }

  /**
   * A comparator to compare two pairs.
   * 
   * @author Claudius Korzen.
   * 
   */
  public class PairComparator implements Comparator<Pair<String, Integer>> {
    @Override
    public int compare(Pair<String, Integer> o1, Pair<String, Integer> o2) {
      if (o1 == o2) { return 0; }
      if (o1 == null) { return 1; }
      if (o2 == null) { return -1; }
      if (o1.second > o2.second) { return 1; }
      if (o1.second < o2.second) { return -1; }
      return 0;
    }
  }

  /**
   * Returns the extracted fulltext.
   * 
   * @return the extracted fulltext.
   */
  public String getFulltext() {
    return fulltext.toString();
  }

  @Override
  public long[] getRuntimes() {
    return runtimes;
  }
  
  public void setLines(List<Region> lines) {
    this.lines = lines;
  }
  
  @Override
  public List<Region> getLines() {
    return lines;
  }
}