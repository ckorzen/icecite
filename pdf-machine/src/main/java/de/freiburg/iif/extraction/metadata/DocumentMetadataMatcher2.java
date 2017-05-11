package de.freiburg.iif.extraction.metadata;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.pdfbox.pdmodel.PDDocument;

import de.freiburg.iif.extraction.MetadataMatcher;
import de.freiburg.iif.extraction.metadataknowledge.InvertedIndexMetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQuery;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQueryType;
import de.freiburg.iif.extraction.stripper.PdfBoxStripper;
import de.freiburg.iif.extraction.stripper.PdfStripper;
import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;
import de.freiburg.iif.utils.Patterns;
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
public class DocumentMetadataMatcher2 implements MetadataMatcher {
  /** The interface to the metadata knowledge base */
  protected MetadataKnowledge mk;
  /** The interface to the pdf extraction tool */
  protected PdfStripper ex;
  /** The text of the first page */
  protected StringBuilder textOfFirstPage;
  /** The numbers contained in the first page */
  protected List<Integer> numbers;
  /** The stop titles (titles of candidates, that we won't consider). */
  protected Set<String> stopTitles;
  /** The StringBuilder for the fulltext */
  protected StringBuilder fulltext;
  /** The log4j logger */
  protected Log LOG;
  /** The extracted lines */
  protected List<Region> lines;
  
  /**
   * The constructor.
   */
  public DocumentMetadataMatcher2() {
    this.mk = new InvertedIndexMetadataKnowledge();
    this.ex = new PdfBoxStripper();
    this.textOfFirstPage = new StringBuilder();
    this.numbers = new ArrayList<Integer>();
    this.stopTitles = readStopTitlesFile();
    this.LOG = LogFactory.getLog(DocumentMetadataMatcher2.class);
    this.fulltext = new StringBuilder();
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
    textOfFirstPage.setLength(0);
    numbers.clear();

    // Fetch only the line of the first page.
    lines = filterFirstPageLines(lines);
    
    // Compute the most common fontsize in the first page.
    Stats stats = computeStats(lines);
    
    LOG.debug("FULLTEXT: " + textOfFirstPage);
    
    // Sort the lines by fontsizes
    Collections.sort(lines, new FontsizeComparator());

    // Compute the metadata knowledge-query
    MetadataKnowledgeQuery query = createMetadataKnowledgeQuery(lines, stats);

    // Get the best scored record for the query.
    HasMetadata leadingCandidate = getLeadingCandidate(query);

    // If there is no such query, remove the authors-parameter and repeat.
    if (leadingCandidate == null) {
      query.remove(MetadataKnowledgeQueryType.AUTHORS);
      leadingCandidate = getLeadingCandidate(query);
    }

    return wrap(leadingCandidate);
  }

  /**
   * Filters the given lines and returns a new list, containing only the lines
   * of the first page.
   * 
   * @param lines
   *          the lines to filter.
   * @return new list, containing only the lines of the first page.
   */
  protected List<Region> filterFirstPageLines(List<Region> lines) {
    if (lines != null) {
      List<Region> filtered = new ArrayList<Region>();
      for (Region line : lines) {
        if (line != null) {
          if (line.getPageNumber() == 1) {
            filtered.add(line);
          }
          fulltext.append(line.getText());
          fulltext.append(" ");
        }
      }
      return filtered;
    }
    return null;
  }

  /**
   * Iterates over the given lines and computes the most common fontsize and the
   * mist common line pitch.
   * 
   * @param lines
   *          the textlines to analyze.
   * @return the average (rounded) fontsize
   */
  protected Stats computeStats(List<Region> lines) {
    int mostCommontFontsize = -1;
    int mostCommontPitchsize = -1;

    if (lines != null && lines.size() > 0) {
      // Count the various fontsizes.
      Map<Integer, Integer> fontsizes = new HashMap<Integer, Integer>();
      Map<Integer, Integer> linepitches = new HashMap<Integer, Integer>();

      for (int i = 0; i < lines.size(); i++) {
        Region line = lines.get(i);
        LOG.debug(line);
        int fontsize = Math.round(line.getFontsize());
        // Increment the counter for the fontsize
        int count =
            fontsizes.containsKey(fontsize) ? fontsizes.get(fontsize) : 0;
        fontsizes.put(fontsize, count + 1);

        if (i > 0) {
          // Create stats for the vertical distances of text lines.
          Region prevLine = lines.get(i - 1);
          float prevYBottom = prevLine.getY() + prevLine.getHeight();
          float curTop = line.getY();
          int yDiff = Math.round(Math.abs(prevYBottom - curTop));
          int count2 =
              linepitches.containsKey(yDiff) ? linepitches.get(yDiff) : 0;
          linepitches.put(yDiff, count2 + 1);
        }

        textOfFirstPage.append(line.getText());
        textOfFirstPage.append(" ");

        Pattern p = Patterns.NUMBERS_PATTERN;
        Matcher m = p.matcher(line.getText());

        while (m.find()) {
          try {
            int number = Integer.parseInt(m.group());
            numbers.add(number);
          } catch (Exception e) {
            // Nothing to do.
          }
        }
      }

      int mostCommontFontsizeNum = 0;
      // Iterate over the stats to determine the most common fontsize.
      for (Entry<Integer, Integer> stat : fontsizes.entrySet()) {
        // Don't consider the fontsize 0.
        if (stat.getKey() > 0 && stat.getValue() > mostCommontFontsizeNum) {
          mostCommontFontsizeNum = stat.getValue();
          mostCommontFontsize = stat.getKey();
        }
      }

      int mostCommontPitchSizeNum = 0;
      // Iterate over the stats to determine the most common fontsize.
      for (Entry<Integer, Integer> stat : linepitches.entrySet()) {
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
   * Creates the metadata knowledge query for the given lines.
   * 
   * @param lines
   *          the lines
   * @param stats
   *          the stats
   * @return the query.
   * @throws IOException
   *           if querying the mkb fails.
   */
  protected MetadataKnowledgeQuery createMetadataKnowledgeQuery(
    List<Region> lines, Stats stats) throws IOException {
    int numOfTitleWords = 0;
    int numOfAuthorWords = 0;

    MetadataKnowledgeQuery query = new MetadataKnowledgeQuery();

    for (int i = 0; i < lines.size(); i++) {
      Region prevLine = i > 0 ? lines.get(i - 1) : null;
      Region line = lines.get(i);

      float emphasis = computeEmphasis(line);
      float linePitch = computeLinePitch(prevLine, line);

      if (emphasis >= stats.mostCommonFontSize) {
        if (emphasis > stats.mostCommonFontSize
            || linePitch > 1.5 * stats.mostCommontPitchSize) {
          Pattern p = Patterns.LONG_WORDS_PATTERN; // TODO: Check vaidity
          Matcher m = p.matcher(line.getText());

          while (m.find()) {
            String word = m.group().trim();
            int numTitleHits = 0;
            if (numOfTitleWords < 10) {
              numTitleHits =
                  mk.getNumOfHits(MetadataKnowledgeQueryType.TITLE, word, 0);
            }
            int numAuthorHits = 0;
            char firstChar = word.charAt(0);
            if (Character.isUpperCase(firstChar) && numOfAuthorWords < 10) {
              numAuthorHits =
                  mk.getNumOfHits(MetadataKnowledgeQueryType.AUTHORS, word, 0);
            }

            if (numAuthorHits > 0) {
              query.add(MetadataKnowledgeQueryType.AUTHORS, word);
              numOfAuthorWords++;
            }

            if (numTitleHits > 0) {
              query.add(MetadataKnowledgeQueryType.TITLE, word);
              numOfTitleWords++;
            }
          }
        }
      }
    }

    query.create();
    return query;
  }

  /**
   * Computes the emphasis of the given line.
   * 
   * @param line
   *          the line to process.
   * @return the emphasis of the line.
   */
  protected float computeEmphasis(Region line) {
    if (line != null) {
      float emphasis = Math.round(line.getFontsize());
      emphasis += ((float) line.getFontFlag()) / 10;
      if (line.isInUpperCase()) {
        emphasis += .1;
      }
      return emphasis;
    }
    return 0;
  }

  /**
   * Computes the linepitch between the given lines.
   * 
   * @param prevLine
   *          the first line to process.
   * @param line
   *          the second line to process.
   * @return the line pitch between the lines.
   */
  protected float computeLinePitch(Region prevLine, Region line) {
    if (prevLine != null && line != null) {
      float prevYBottom = prevLine.getY() + prevLine.getHeight();
      float curTop = line.getY();
      return Math.round(Math.abs(prevYBottom - curTop));
    }
    return -1;
  }

  /**
   * Determines the best scored candidate for a given query.
   * 
   * @param query
   *          the query to analyze.
   * @return the best scored candidate
   * @throws IOException
   *           if quering the mkb fails.
   */
  protected HasMetadata getLeadingCandidate(MetadataKnowledgeQuery query)
    throws IOException {
    List<HasMetadata> candidates = mk.query(query, 0);
    LOG.debug(query);
    float maxScore = 0;
    HasMetadata mostLikelyCandidate = null;
    if (candidates != null) {
      for (int i = 0; i < Math.min(10, candidates.size()); i++) {
        HasMetadata candidate = candidates.get(i);
        if (candidate != null && !isStopTitle(candidate.getTitle())) {
          float score = scoreCandidate(candidate);
          LOG.debug(score + " - " + candidate);
          if (score > .5 && score > maxScore) {
            mostLikelyCandidate = candidate;
            maxScore = score;
          }
        }
      }
    }
    return mostLikelyCandidate;
  }

  /**
   * Wraps a given record into a list.
   * 
   * @param record
   *          the record to wrap.
   * @return a list containing the giveb record.
   */
  protected List<HasMetadata> wrap(HasMetadata record) {
    List<HasMetadata> wrapper = new ArrayList<HasMetadata>();
    wrapper.add(record);
    return wrapper;
  }

  /**
   * Scores a matching candidate.
   * 
   * @param candidate
   *          the candidate to score.
   * @return the score of the candidate.
   */
  protected float scoreCandidate(HasMetadata candidate) {
    float titleScore = 0;
    float authorsScore = 0;
    float yearScore = 0;
    float pageScore = 0;
    float venueScore = 0;
    
    if (candidate != null) {
      LOG.debug("CAND : " + candidate);
      float[] simResult =
          StringSimilarity.smithWaterman(candidate.getTitle(),
              textOfFirstPage.toString());
      titleScore =
          simResult[0]
              / StringSimilarity
                  .getMaxSmithWatermanScore(candidate.getTitle());
      
      // Compute the authorsScore.
      List<String> authors = candidate.getAuthors();
      int numAuthors = 0;

      if (authors != null) {
        for (int i = 0; i < authors.size(); i++) {
          String author = authors.get(i);
          // Score the lastname of each author
          String[] authorWords = author.split(" ");
          String lastname = authorWords[authorWords.length - 1];

          if (!lastname.isEmpty()) {
            simResult =
                StringSimilarity.smithWaterman(lastname,
                    textOfFirstPage.toString());
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

      simResult = StringSimilarity.smithWaterman(candidate.getJournal(),
              textOfFirstPage.toString());
      float maxVenueScore =
          StringSimilarity.getMaxSmithWatermanScore(candidate.getJournal());
      
      if ((simResult[0] / maxVenueScore) == 1) {
        venueScore = 0.1f;
      }

      if (numbers.contains(candidate.getYear())) {
        yearScore = 0.1f;
      }
      if (numbers.contains(candidate.getStartPage())) {
        pageScore = 0.1f;
      }
    }

    LOG.debug("  t: " + titleScore + " a:" + authorsScore + " y: " + yearScore + " p: " + pageScore + " v: " + venueScore);
    
    return (titleScore * authorsScore) + yearScore + pageScore + venueScore;
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
      return stopTitles;
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
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
    return fulltext.toString();
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