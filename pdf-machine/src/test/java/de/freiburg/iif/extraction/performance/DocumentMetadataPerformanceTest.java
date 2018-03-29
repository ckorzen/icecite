package de.freiburg.iif.extraction.performance;

import com.google.inject.Inject;

import de.freiburg.iif.extraction.MetadataMatcher;

/**
 * The class TitlePerformanceTest that can be used to evaluate the performance
 * of the title extraction.
 * 
 * @author Claudius Korzen
 * 
 */
public class DocumentMetadataPerformanceTest extends BasePerformanceTest {  
  /**
   * The constructor of TitlePerformanceTest
   * 
   * @param matcher the implementation of MetadataMatcher. 
   */
  @Inject
  public DocumentMetadataPerformanceTest(MetadataMatcher matcher) {
    super();
    this.matcher = matcher;
  }
  
  @Override
  protected GroundTruthElement getGroundTruthElement(String line) {
    String[] elements = line.split("\t");
    return new GroundTruthElement(elements[0], elements[1], elements[2]);
  }
}
