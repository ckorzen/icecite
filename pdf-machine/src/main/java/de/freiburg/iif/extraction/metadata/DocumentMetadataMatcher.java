package de.freiburg.iif.extraction.metadata;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.pdfbox.pdmodel.PDDocument;

import de.freiburg.iif.extraction.MetadataMatcher;
import de.freiburg.iif.extraction.metadataknowledge.InvertedIndexMetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQueryType;
import de.freiburg.iif.extraction.stripper.PdfBoxStripper;
import de.freiburg.iif.extraction.stripper.PdfStripper;
import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;
import de.freiburg.iif.utils.StringSimilarity;

/**
 * The class DocumentMetadataMatcher, that implements MetadataMatcher and can be
 * used to find the record in the metadata knowledge base, referred by a
 * document. The matching process uses an inverted index, which is implemented
 * in C++. The inverted index provides a socket, which can be queried by sending
 * ordinary HTTP requests to it. The result is a xml file, containing the
 * result.
 * 
 * @author Claudius Korzen
 * 
 */
public class DocumentMetadataMatcher implements MetadataMatcher {
  // TODO: Move constants to a properties file.
  /** The maximal length of a title */
  private static final int TITLEEXTRACTION_MAX_LENGTH_TITLE = 300;

  /** The log4j logger */
  protected Log LOG;
  /** The interface to the metadata knowledge base */
  protected MetadataKnowledge mk;
  /** The interface to the pdf extraction tool */
  protected PdfStripper ex;
  /** The header lines of the PDF document as string */
  protected String header;
  /** The stop titles (titles of candidates, that we won't consider). */
  protected Set<String> stopTitles;
  /** The extracted lines */
  protected List<Region> lines;
  
  /**
   * The constructor.
   */
  public DocumentMetadataMatcher() {
    this.mk = new InvertedIndexMetadataKnowledge();
    this.ex = new PdfBoxStripper();
    this.stopTitles = readStopTitlesFile();
    this.LOG = LogFactory.getLog(DocumentMetadataMatcher.class);
  }

  @Override
  public List<HasMetadata> match(String filepath, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException {
    return match(PDDocument.load(filepath), strict, disableMK, minWaitInterval);
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
    lines = ex.extractLines(doc, 1, 1, false);
    return match(lines, strict, disableMK, minWaitInterval);
  }

  /**
   * Tries to find the referred metadata record on the basis of the given
   * textlines.
   * 
   * @param lines
   *          the textlines to analyze.
   * @return the matched metadata record.
   * @throws IOException
   *           if the matching process fails.
   */
  public List<HasMetadata> match(List<Region> lines, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException {
    // Compute the most common fontsize in the first page.
    Stats stats = getMostCommonFontSize(lines);

    // Filter out all lines, which are smaller than the most common fontsize.
    List<Region> relevantLines = getRelevantLines(lines, stats);

    // Group the relevant lines into logical blocks.
    List<Region> groups = group(relevantLines);

    for (int i = 0; i < groups.size(); i++) {
      Region g = groups.get(i);
      for (Region line : g.getIncludedLines()) {
        LOG.debug("GROUP" + i + ": " + line);
      }
    }

    groups = group(groups);

    for (int i = 0; i < groups.size(); i++) {
      Region g = groups.get(i);
      for (Region line : g.getIncludedLines()) {
        LOG.debug("2GROUP" + i + ": " + line);
      }
    }

    // Build the header string.
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < lines.size(); i++) {
      sb.append(lines.get(i).getText());
    }
    this.header = sb.toString();

    double maxScore = 0;
    HasMetadata mostLikelyCandidate = null;

    // Iterate over the groups: Try to find the best matching metadata record by
    // querying the metadata knowledge with all line combinations.
    for (int i = 0; i < groups.size(); i++) { // Iterate over the groups
      Region group = groups.get(i);
      int y = Math.min(5, group.getIncludedLines().size());
      for (int j = 0; j < y; j++) { // Iterate over any line combinations.
        sb = new StringBuffer();
        double size = group.getIncludedLines().get(j).getFontsize();
        for (int k = j; k < y; k++) {
          Region line = group.getIncludedLines().get(k);

          sb.append(line.getText());
          String query = clearSpecialChars(sb.toString()).trim();

          LOG.debug("*******************************************");
          LOG.debug("QUERY : " + query);
          LOG.debug("LINE  : " + line);

          // Query the metadata knowledge for candidates.
          List<HasMetadata> candidates =
              mk.query(MetadataKnowledgeQueryType.TITLE, query, 0);

          // Evaluate the candidates.
          for (int l = 0; l < Math.min(10, candidates.size()); l++) {
            HasMetadata candidate = candidates.get(l);
            if (!isStopTitle(candidate.getTitle())) {
              double score = scoreCandidate(candidate, query, size);

              if (score > maxScore) {
                LOG.debug("CAND : " + candidate + " " + score);
                mostLikelyCandidate = candidate;
                maxScore = score;
              }
            }
          }

          // We assume a maximal length for title. Abort, if the query is larger
          // than the maximal length.
          if (query.length() > TITLEEXTRACTION_MAX_LENGTH_TITLE) {
            break;
          }
        }
      }
    }

    List<HasMetadata> wrapperList = new ArrayList<HasMetadata>();
    wrapperList.add(mostLikelyCandidate);
    LOG.debug("maxScore: " + maxScore);
    return wrapperList;
  }

  /**
   * Computes the average (rounded) fontsize of the given text lines.
   * 
   * @param lines
   *          the textlines to analyze.
   * @return the average (rounded) fontsize
   */
  protected Stats getMostCommonFontSize(List<Region> lines) {
    int mostCommontFontsize = -1;
    int mostCommontPitchsize = -1;

    if (lines != null && lines.size() > 0) {
      // Count the various fontsizes.
      Map<Integer, Integer> stats = new HashMap<Integer, Integer>();
      Map<Integer, Integer> stats2 = new HashMap<Integer, Integer>();

      for (int i = 0; i < lines.size(); i++) {
        Region line = lines.get(i);
        int fontsize = Math.round(line.getFontsize());
        // Increment the counter for the fontsize
        int count = stats.containsKey(fontsize) ? stats.get(fontsize) : 0;
        stats.put(fontsize, count + 1);

        if (i > 0) {
          // Create stats for the vertical distances of text lines.
          Region prevLine = lines.get(i - 1);
          float prevYBottom = prevLine.getY() + prevLine.getHeight();
          float curTop = line.getY();
          int yDiff = Math.round(Math.abs(prevYBottom - curTop));
          int count2 = stats2.containsKey(yDiff) ? stats2.get(yDiff) : 0;
          stats2.put(yDiff, count2 + 1);
        }
      }

      int mostCommontFontsizeNum = 0;
      // Iterate over the stats to determine the most common fontsize.
      for (Entry<Integer, Integer> stat : stats.entrySet()) {
        // Don't consider the fontsize 0.
        if (stat.getKey() > 0 && stat.getValue() > mostCommontFontsizeNum) {
          mostCommontFontsizeNum = stat.getValue();
          mostCommontFontsize = stat.getKey();
        }
      }

      int mostCommontPitchSizeNum = 0;
      // Iterate over the stats to determine the most common fontsize.
      for (Entry<Integer, Integer> stat : stats2.entrySet()) {
        // Don't consider the pitch 0.
        if (stat.getKey() > 0 && stat.getValue() > mostCommontPitchSizeNum) {
          mostCommontPitchSizeNum = stat.getValue();
          mostCommontPitchsize = stat.getKey();
        }
      }
    }
    LOG.debug("Most common fontsize: " + mostCommontFontsize);
    LOG.debug("Most common pitchsize: " + mostCommontPitchsize);

    return new Stats(mostCommontFontsize, mostCommontPitchsize);
  }

  /**
   * Returns the lines, which are relevant. That means all lines, which are
   * larger than the given fontsize and whose length of text is large enough.
   * 
   * @param lines
   *          the text lines to analyze.
   * @param stats
   *          the style stats of lines (containing the most common fontsize and
   *          the most common line pitch).
   * @return list of lines, which are larger than the given fontsize. The lines
   *         are sorted by their reading order.
   */
  protected List<Region> getRelevantLines(List<Region> lines, Stats stats) {
    List<Region> relevantLines = new ArrayList<Region>();
    double mostCommonFontsize = stats.mostCommonFontSize;
    double mostCommonLinePitch = stats.mostCommontPitchSize;

    int sectionLength = 0;
    boolean isSectionRelevant = true;
    for (int i = 0; i < lines.size(); i++) {
      Region line = lines.get(i);
      // Line is relevant, if its fontsize is larger than the most common one.
      double fontsize = Math.round(line.getFontsize());
      // Add a bonus to the fontsize, if the text is bold, italic, or uppercase.
      // natural order of importance factors: fontsize, bold, italic, uppercase.
      double bonus = ((double) line.getFontFlag()) / 10;
      if (line.isInUpperCase()) {
        bonus += .1;
      }
      fontsize += bonus;
      boolean isFontsizeRelevant = fontsize > mostCommonFontsize;

      // Line is relevant, if the line is the first one or if the pitch to the
      // previous line is larger than the most common one.
      if (i > 0) {
        // Measure the pitch to the previous line.
        Region prevLine = lines.get(i - 1);
        float prevYBottom = prevLine.getY() + prevLine.getHeight();
        float curTop = line.getY();
        int yDiff = Math.round(Math.abs(prevYBottom - curTop));

        // System.out.println(yDiff + ">" + 1.5 * mostCommonLinePitch + "; " +
        // fontsize +" > "+ mostCommonFontsize + "; " + isSectionRelevant +"&&"+
        // sectionLength);

        if (yDiff > 1.5 * mostCommonLinePitch) {
          isSectionRelevant = true;
          sectionLength = line.getText().length();
        } else if (isSectionRelevant
            && sectionLength < TITLEEXTRACTION_MAX_LENGTH_TITLE) {
          sectionLength += line.getText().length();
        } else {
          isSectionRelevant = false;
          sectionLength = 0;
        }
        // System.out.println("isSectionRelevant: " + isSectionRelevant +
        // ", isFontsizeRelevant: " + isFontsizeRelevant);
      }

      if (consider(line) && (isFontsizeRelevant || isSectionRelevant)) {
        relevantLines.add(line);
        LOG.debug("R");
        if (isFontsizeRelevant) {
          LOG.debug("F");
        } else {
          LOG.debug(" ");
        }
        if (isSectionRelevant) {
          LOG.debug("S");
        } else {
          LOG.debug(" ");
        }
        LOG.debug(" ");
      } else {
        LOG.debug("XXX ");
      }
      LOG.debug("LINE: " + line);
    }

    // Collections.sort(relevantLines, new ReadingOrderComparator());
    return relevantLines;
  }

  /**
   * Groups the given text lines into logical blocks.
   * 
   * @param lines
   *          the lines to group.
   * @return the lsit of groups.
   */
  public List<Region> group(List<Region> lines) {
    List<Region> groups = new ArrayList<Region>();

    if (lines != null && lines.size() > 0) {
      Region group = lines.get(0);
      Region prevLine = lines.get(0);
      int groupLength = prevLine.getText().length();

      for (int i = 1; i < lines.size(); i++) {
        Region line = lines.get(i);
        // Take the vertical distance between the current and the previous line.
        float amount = Math.max(prevLine.getHeight(), prevLine.getFontsize());
        float prevBottom = prevLine.getY() + amount;
        float top = line.getY();
        float yDiff = Math.abs(prevBottom - top);

        // Expand the current group with the current line, if the distance is
        // small enough.
        if (yDiff <= 2 * amount) {
          // Expand the group only, if the length of the group doesn't exceed
          // the maximal length for a title.
          if (groupLength < TITLEEXTRACTION_MAX_LENGTH_TITLE) {
            group.expand(line);
          }
        } else {
          // Create a new group.
          groups.add(group);
          group = line;
        }
        prevLine = line;
      }

      // Don't forget to add the last group.
      groups.add(group);
    }
    Collections.sort(groups, new ReadingOrderComparator());

    return groups;
  }

  /**
   * Returns true, if the given line should be considered on the matching
   * process.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the line should be considered on the matching process,
   *         false otherwise.
   */
  protected boolean consider(Region line) {
    if (line != null && line.getText() != null) { return line.getText()
        .replaceAll("[^a-zA-Z0-9]+", "").length() > 2
        && !line.getText().contains("http://")
        && !line.getText().contains("@"); }
    return false;
  }

  /**
   * Scores a matching candidate.
   * 
   * @param candidate
   *          the candidate to score.
   * @param query
   *          the query, from which the candidate resulted.
   * @param fontSize
   *          the fontsize of the query.
   * @return the score of the candidate.
   */
  protected double scoreCandidate(HasMetadata candidate, String query,
    double fontSize) {
    double score = -1;

    if (candidate != null && query != null) {
      LOG.debug("CAND : " + candidate);
      // Only procced, if the score of the metadata knowlege is large enough.
      // System.out.println("indexscore: " + candidate.getScore());
      // System.out.println("|C| " + candidate.getTitle().length());
      // System.out.println("|Q| " + query.length());
      // System.out.println("min/max " + ((double)
      // Math.min(candidate.getTitle().length(), query.length()) /
      // Math.max(candidate.getTitle().length(), query.length())));
      double titleScore =
          StringSimilarity.levenshtein(candidate.getTitle(), query);
      titleScore =
          -1
              * (titleScore / Math.max(candidate.getTitle().length(),
                  query.length())) + 1;

      if (candidate.getScore() > .5) {
        // MAYBE: double titleScore = candidate.getScore /
        double authorScore = scoreAuthors(candidate);
        double yearScore = header.contains("" + candidate.getYear()) ? 1 : 0;
        double journalScore = header.contains(candidate.getJournal()) ? 2 : 0;
        score =
            (authorScore * titleScore * titleScore * fontSize) + yearScore
                + journalScore;

        LOG.debug("HEADER: " + header);
        LOG.debug("TSCORE: " + titleScore);
        LOG.debug("ASCORE: " + authorScore);
        LOG.debug("YSCORE: " + yearScore);
        LOG.debug("JSCORE: " + journalScore);
        LOG.debug("SIZE  : " + fontSize);
        LOG.debug("TOTAL : " + score);
      }
    }

    return score;
  }

  /**
   * Computes a score for the authors of the given candidate.
   * 
   * @param candidate
   *          the candidate to process.
   * @return the score for the authors.
   */
  protected double scoreAuthors(HasMetadata candidate) {
    double authorScore = 0;

    for (String author : candidate.getAuthors()) {
      String[] authorWords = author.split(" ");
      String[] headerWords = header.split(" ");
      double maxAuthorScore = 0;
      for (String headerWord : headerWords) {
        // Compute the coverage of the author's lastname by the header.
        float[] simResult =
            StringSimilarity.smithWaterman(
                authorWords[authorWords.length - 1], headerWord);
        float s = simResult[0];
        if (s > maxAuthorScore) {
          maxAuthorScore = s;
        }
      }
      authorScore += maxAuthorScore;
    }

    // Compute a relative score.
    authorScore /= candidate.getAuthors().size();

    return authorScore;
  }

  /**
   * Removes all special characters and digits from a given string.
   * 
   * @param text
   *          the text to process.
   * @return the simplified string.
   */
  protected String clearSpecialChars(String text) {
    // return text.replaceAll("[^a-zA-Z-,.]+", " ");
    return text.replaceAll("[^a-zA-Z0-9]+", " ");
  }

  /**
   * Returns true, if the given title should be ignored.
   * 
   * @param title
   *          the title to check.
   * @return true, if the given title should be ignored.
   */
  protected boolean isStopTitle(String title) {
    if (stopTitles != null) { return stopTitles.contains(clearSpecialChars(
        title).trim().toLowerCase()); }
    return false;
  }

  /**
   * Reads the stoptitles file and fills the stoptitles into a set.
   * 
   * @return as set containing the stoptitles in stoptitles file.
   */
  protected Set<String> readStopTitlesFile() {
    try (BufferedReader br = new BufferedReader(new InputStreamReader(
        this.getClass().getResourceAsStream("stoptitles")))) {
      Set<String> stopTitles = new HashSet<String>();
  
      String line = null;
      try {
        while ((line = br.readLine()) != null) {
          stopTitles.add(clearSpecialChars(line).trim().toLowerCase());
        }
      } catch (Exception e) {
        e.printStackTrace();
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    return stopTitles;
  }

  /**
   * Class stats, that holds the most common fontsize and the most common pitch
   * size of lines.
   * 
   * @author Claudius Korzen.
   * 
   */
  public class Stats {
    /** The most common font size */
    public double mostCommonFontSize;
    /** The most common pitch size */
    public double mostCommontPitchSize;
    /** The number of reference anchors (for references extraction only). */
    public int numOfReferenceAnchors;
    /**
     * The number of advanced reference headers (for references extraction
     * only).
     */
    public int numOfAdvancedReferenceHeader;

    /**
     * The constructor.
     * 
     * @param mostCommonFontsize
     *          the most common fontsize
     * @param mostCommonPitchSize
     *          the most common pitch size.
     */
    public Stats(double mostCommonFontsize, double mostCommonPitchSize) {
      this.mostCommonFontSize = mostCommonFontsize;
      this.mostCommontPitchSize = mostCommonPitchSize;
    }
  }

  @Override
  public String getFulltext() {
    // TODO Auto-generated method stub
    return null;
  }

  @Override
  public long[] getRuntimes() {
    // TODO Auto-generated method stub
    return null;
  }
  
  @Override
  public List<Region> getLines() {
    return lines;
  }
}

/**
 * Comparator to sort text lines by their reading order.
 * 
 * @author Claudius Korzen
 */
class ReadingOrderComparator implements Comparator<Region> {
  @Override
  public int compare(Region r1, Region r2) {
    int compare = Region.compare(r1.getY(), r2.getY(), 10f);
    if (compare != 0) { return -1 * compare; }

    compare = Region.compare(r1.getX(), r2.getX(), 3f);
    if (compare != 0) { return -1 * compare; }

    return 0;
  }
}

/**
 * Comparator to sort text lines by their reading order.
 * 
 * @author Claudius Korzen
 */
class FontsizeComparator implements Comparator<Region> {
  @Override
  public int compare(Region r1, Region r2) {
    return -1 * Float.compare(r1.getFontsize(), r2.getFontsize());
  }
}