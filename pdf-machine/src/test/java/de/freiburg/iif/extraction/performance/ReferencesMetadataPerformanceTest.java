package de.freiburg.iif.extraction.performance;

import org.apache.commons.logging.LogFactory;

import de.freiburg.iif.extraction.references.ReferencesMetadataMatcher;

/**
 * The class TitlePerformanceTest that can be used to evaluate the performance
 * of the references extraction.
 * 
 * @author Claudius Korzen
 * 
 */
public class ReferencesMetadataPerformanceTest extends BasePerformanceTest {

  /**
   * The constructor of ReferencesPerformanceTest
   */
  public ReferencesMetadataPerformanceTest() {
    super();
    this.matcher = new ReferencesMetadataMatcher();
    this.LOG = LogFactory.getLog(ReferencesMetadataPerformanceTest.class);
  }

  @Override
  protected GroundTruthElement getGroundTruthElement(String line) {
    if (line != null) {
      // Split the line on tab-characters;
      String[] elements = line.split("\\t");
      
      if (elements.length > 0 && !elements[0].isEmpty()) {
        return new GroundTruthElement(elements[0].trim(), null, null);
      } else {
        if (elements.length > 2) {                
          String expectedTitle = elements[1].trim();
          String expectedKey = elements[2].trim();
          return new GroundTruthElement(null, expectedTitle, expectedKey);
        }
      }
    }
    return null;
  }
}
