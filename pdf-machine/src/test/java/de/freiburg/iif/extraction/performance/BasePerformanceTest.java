package de.freiburg.iif.extraction.performance;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import de.freiburg.iif.extraction.MetadataMatcher;
import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.utils.StringSimilarity;

/**
 * The abstract class BasePerformanceTest.
 * 
 * @author Claudius Korzen.
 */
public abstract class BasePerformanceTest {
  /** The log4j logger */
  protected Log LOG;

  /** The user directory */
  protected static final String USER_DIR = System.getProperty("user.dir");
  /** The base directory */
  protected static final String BASE_DIR = USER_DIR
      + "/src/test/resources/de/freiburg/iif/pdfextraction";
  /** The pdf directory */
  protected static final String PDF_DIR = BASE_DIR + "/pdfs";
  /** The file extension of groundtruth files */
  protected static final String FILEEXT_GROUNDTRUTH = ".qrels";
  /** The file extension of groundtruth for failures */
  protected static final String FILEEXT_GROUNDTRUTH_FAILS = ".fails.qrels";

  /** The overall time to execute the action to evaluate */
  protected long overallTime;
  /** The number of correct extraction results */
  protected int numCorrectExtractionResults;
  /** The number of correct extraction results */
  protected int numCorrectMatchingResults;
  /** The number of correct results */
  protected int numWrongExtractionResults;
  /** The number of correct results */
  protected int numWrongMatchingResults;
  /** The number of unexpected results */
  protected int numUnexpectedResults;
  /** The number of errors on executing the action to evaluate */
  protected int numErrors;
  /** The overall number of results */
  protected int numResults;

  /** sum of runtimes */
  protected long sumOfRuntime1;
  /** sum of runtimes */
  protected long sumOfRuntime2;
  /** sum of runtimes */
  protected long sumOfRuntime3;
  /** sum of runtimes */
  protected long sumOfRuntime4;
  /** sum of runtimes */
  protected long sumOfRuntime5;
  /** sum of runtimes */
  protected long sumOfRuntime6;

  /** The current filename */
  protected String currentFilename;

  /** The metadata matcher */
  protected MetadataMatcher matcher;

  /** The list of ground truth elements for the current document */
  protected List<GroundTruthElement> groundTruthElements;

  /**
   * The constructor of BasePerformanceTest.
   */
  public BasePerformanceTest() {
    this.LOG = LogFactory.getLog(BasePerformanceTest.class);
    this.groundTruthElements = new ArrayList<GroundTruthElement>();
  }

  /**
   * Reads the groundtruth file.
   * 
   * @param basename
   *          the basename of the groundtruth file.
   * @throws IOException
   *           if reading the groundtruth file fails.
   */
  public void evaluate(String basename) throws IOException {
    // Read from the groundtruth file.
    String path =
        BASE_DIR + File.separatorChar + basename + FILEEXT_GROUNDTRUTH;
    LOG.debug("path: " + path);
    File file = new File(path);
    try (Reader reader = new InputStreamReader(new FileInputStream(file), "UTF-8");
        BufferedReader buf = new BufferedReader(reader)) {

      // Write all failures on evaluation in an extra file.
      String failuresFilepath =
          BASE_DIR + File.separatorChar + basename + FILEEXT_GROUNDTRUTH_FAILS;
      File failuresFile = new File(failuresFilepath);
        
      String line = null;
      // Process groundtruth file line by line.
      while ((line = buf.readLine()) != null) {
        if (!line.startsWith("#")) {
          readGroundTruth(basename, line);
        }
      }
      processGroundTruth(groundTruthElements);
      printEvaluationSummary();
    }
  }

  /**
   * Reads a groundtruth line.
   * 
   * @param basename
   *          the basename.
   * @param line
   *          the line from the groundtruth file.
   * @throws IOException
   *           if the evaluation fails.
   */
  protected void readGroundTruth(String basename, String line)
    throws IOException {
    // Read an individual groundTruth record. In case of references extraction,
    // the record can hold several groundTruth elements (one for each
    // reference).
    GroundTruthElement groundTruthElement = getGroundTruthElement(line);
    if (groundTruthElement != null) {
      if (groundTruthElement.filename != null
          && groundTruthElement.key != null) {
        groundTruthElements.add(groundTruthElement);
        processGroundTruth(groundTruthElements);
        groundTruthElements.clear();
      } else {
        if (groundTruthElement.filename != null) {
          processGroundTruth(groundTruthElements);
          currentFilename = groundTruthElement.filename;
          groundTruthElements.clear();
        } else {
          groundTruthElement.filename = currentFilename;
          groundTruthElements.add(groundTruthElement);
        }
      }
    }
  }

  /**
   * Processes a groundtruth. This method checks, if the expected extracts
   * were extracted and if the expected records were found.
   * 
   * @param groundTruthElements the groundtruth.
   */
  protected void processGroundTruth(
      List<GroundTruthElement> groundTruthElements) {
    if (groundTruthElements != null && groundTruthElements.size() > 0) {
      long start = System.currentTimeMillis();
      // Take the filename of the first groundTruthElement.
      String filename = groundTruthElements.get(0).filename;
      System.out.println("|Input: " + filename + "|");

      // Perform the action to evaluate.
      List<HasMetadata> results = null;
      try {
        results =
            matcher.match(PDF_DIR + File.separatorChar + filename, false, false,
                0);
        sumOfRuntime1 += matcher.getRuntimes()[0];
        sumOfRuntime2 += matcher.getRuntimes()[1];
        sumOfRuntime3 += matcher.getRuntimes()[2];
        sumOfRuntime4 += matcher.getRuntimes()[3];
        sumOfRuntime5 += matcher.getRuntimes()[4];
        sumOfRuntime6 += matcher.getRuntimes()[5];
      } catch (Exception e) {
        System.err.println("Failure:  " + e.getMessage());
        e.printStackTrace();
        numErrors++;
      }
      long end = System.currentTimeMillis();
      overallTime += (end - start);
      System.out.println("|Input: " + filename + "|");

      if (results != null) {
        numResults += results.size();

        for (GroundTruthElement groundTruthElement : groundTruthElements) {
          String expectedExtract = groundTruthElement.extract;
          String expectedKey = groundTruthElement.key;
          boolean expectedKeyFound = false;
          boolean expectedExtractFound = false;

          LOG.info("Searching for groundTruthElement " + groundTruthElement
              + "...");

          // Search in the result for the expected key.
          Iterator<HasMetadata> it = results.iterator();
          while (it.hasNext()) {
            HasMetadata actual = it.next();
            if (actual != null) {
              String actualExtract = actual.getRaw();
              String actualKey = actual.getKey();

              if (actualKey != null && actualKey.equals(expectedKey)) {
                expectedKeyFound = true;
                numCorrectMatchingResults++;

                // Check, if the extract is correct.
                double treshold = 0.2 * expectedExtract.length();
                double dist =
                    StringSimilarity.levenshtein(expectedExtract,
                        actualExtract);

                if (dist <= treshold) {
                  expectedExtractFound = true;
                  numCorrectExtractionResults++;
                  LOG.info("  KEY OK & EXTRACT OK");
                } else {
                  numWrongExtractionResults++;
                  LOG.info("  KEY OK & EXTRACT FAIL");
                  LOG.info("    expected extract: " + expectedExtract);
                  LOG.info("    actual extract  : " + actualExtract);
                }
                it.remove();
              }
            }
          }

          // If the expected key wasn't found, search for the expected extract.
          if (!expectedKeyFound) {
            it = results.iterator();
            while (it.hasNext()) {
              HasMetadata actual = it.next();
              if (actual != null) {
                String actualExtract = actual.getRaw();
                String actualKey = actual.getKey();

                // Check, if the extract is correct.
                double treshold = 0.2 * expectedExtract.length();
                double dist =
                    StringSimilarity.levenshtein(expectedExtract,
                        actualExtract);

                if (dist <= treshold) {
                  expectedExtractFound = true;
                  numCorrectExtractionResults++;

                  // Check, if key == "NO_MATCH"
                  if ("NO_MATCH".equals(expectedKey) && actualKey == null) {
                    expectedKeyFound = true;
                    numCorrectMatchingResults++;
                    LOG.info("  EXTRACT OK + KEY OK");
                  } else {
                    numWrongMatchingResults++;
                    LOG.info("  EXTRACT OK + KEY FAIL");
                    LOG.info("    expected key: " + expectedKey);
                    LOG.info("    actual key  : " + actualKey);
                  }

                  it.remove();
                }
              }
            }
          }

          if (!expectedExtractFound && !expectedKeyFound) {
            // Both, the expected extract and the expected key wasn't found.
            numWrongExtractionResults++;
            numWrongMatchingResults++;
            LOG.info("  EXTRACT FAIL + KEY FAIL");
            LOG.info("    expected key: " + expectedKey);
            LOG.info("    expected extract: " + expectedExtract);
          }
        }

        // All remaining records in results are unexpected.
        for (HasMetadata unexpected : results) {
          LOG.info("  UNEXPECTED: " + unexpected);
          numUnexpectedResults++;
        }
      }
    }
  }

  /**
   * Prints a summary for the results of the evaluation.
   */
  protected void printEvaluationSummary() {
    LOG.info("************** SUMMARY **************");
    LOG.info("# Results                    : " + numResults);
    LOG.info("# Correct extraction results : " + numCorrectExtractionResults);
    LOG.info("# Wrong extraction results   : " + numWrongExtractionResults);
    LOG.info("# Correct matching results   : " + numCorrectMatchingResults);
    LOG.info("# Wrong matching results     : " + numWrongMatchingResults);
    LOG.info("# Unexpected results         : " + numUnexpectedResults);
    LOG.info("# Errors                     : " + numErrors);
    LOG.info("Time needed: " + overallTime + "ms. " + "(avg: "
        + (double) overallTime / numResults + "ms)");
    LOG.info(" " + (double) sumOfRuntime1 / numResults + "ms. "
        + (double) sumOfRuntime2 / numResults + "ms. "
        + (double) sumOfRuntime3 / numResults + "ms. "
        + (double) sumOfRuntime4 / numResults + "ms. "
        + (double) sumOfRuntime5 / numResults + "ms. "
        + (double) sumOfRuntime6 / numResults + "ms. ");
    LOG.info("*************************************");
  }

  /**
   * Returns a GroundTruthElement for the given line from groundtruth file.
   * 
   * @param line
   *          the line from the groundtruth file.
   * @return the GroundTruthElement.
   */
  protected abstract GroundTruthElement getGroundTruthElement(String line);
}

/**
 * The class GroundTruthElement, representing an element of groundtruth.
 * 
 * @author Claudius Korzen
 * 
 */
class GroundTruthElement {
  /** The input */
  public String filename;
  /** The expected extract */
  public String extract;
  /** The expected key */
  public String key;

  /**
   * The constructor of GroundTruthElement.
   * 
   * @param filename
   *          the filename of pdf file to evaluate.
   * @param extract
   *          the expected extract.
   * @param key
   *          the expected key.
   */
  public GroundTruthElement(String filename, String extract, String key) {
    this.filename = filename;
    this.extract = extract;
    this.key = key;
  }

  @Override
  public String toString() {
    return "[" + filename + ", " + key + ", " + extract + "]";
  }
}
