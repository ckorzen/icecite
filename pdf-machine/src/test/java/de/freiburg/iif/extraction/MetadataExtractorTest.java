package de.freiburg.iif.extraction;

import junit.framework.Assert;

import org.junit.Test;

import de.freiburg.iif.extraction.MetadataExtractor;

/**
 * Class to test the methods of MetadataExtractor.
 * 
 * @author Claudius Korzen
 * 
 */
public class MetadataExtractorTest {
  /**
   * Test the method getBaseName()
   */
  @Test
  public void testGetBaseName() {
    Assert.assertEquals(MetadataExtractor.getBaseName("/path/to/file.pdf"),
        "/path/to/file");
  }
}
