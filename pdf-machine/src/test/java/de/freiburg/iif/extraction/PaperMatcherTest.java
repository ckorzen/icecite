package de.freiburg.iif.extraction;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import org.junit.Test;

import de.freiburg.iif.model.HasMetadata;

/**
 * Class to test PaperMatcher.
 * 
 * @author Claudius Korzen
 *
 */
public class PaperMatcherTest {

  /**
   * Test the methods of PapaerMatcher.
   * 
   * @throws IOException if matching fails.
   */
  @Test
  public void testPaperMatcher() throws IOException {
    String USER_DIR = System.getProperty("user.dir");
    String BASE_DIR = USER_DIR + "/src/test/resources/de/freiburg/iif/pdfextraction";
    String PDF_DIR = BASE_DIR + "/pdfs";

    String filename = "broccoli.pdf";
    File pdfFile = new File(PDF_DIR + File.separatorChar + filename);
    
    PaperMatcher paperMatcher = new PaperMatcher();
    
    FileInputStream is = new FileInputStream(pdfFile);
    paperMatcher.match(is, true, true, true);
    is.close();
    
    System.out.println("METADATA:");
    System.out.println(paperMatcher.getMetadata());
    System.out.println();
    System.out.println("REFERENCES:");
    if (paperMatcher.getReferences() != null) {
      for (HasMetadata reference : paperMatcher.getReferences()) {
        System.out.println(reference);
      }
    } else {
      System.out.println(paperMatcher.getReferences());
    }
  }
}
