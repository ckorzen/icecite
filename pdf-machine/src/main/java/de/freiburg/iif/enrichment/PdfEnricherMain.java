package de.freiburg.iif.enrichment;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import org.apache.commons.io.output.ByteArrayOutputStream;

import de.freiburg.iif.enrichment.CitationsDetector.Citation;
import de.freiburg.iif.extraction.PaperMatcher;

/** 
 * Class to start the PdfEnricher
 *
 * @author Claudius Korzen.
 */
public class PdfEnricherMain {
  /**
   * The main method to start the PdfEnricher.
   * @param args the input arguments.
   * @throws IOException 
   */
  public static void main(String[] args) throws IOException {
    PdfEnricher enricher = new PdfEnricher();
    PaperMatcher matcher = new PaperMatcher();
    
    if (args.length != 1) {
      printUsage();
      System.exit(1);
    }
    
    File pdfFile = new File(args[0]);
    try (FileInputStream fis = new FileInputStream(pdfFile)) {
      byte[] byteArray = toByteArray(fis);
      
      try (InputStream is1 = new ByteArrayInputStream(byteArray)) { 
        matcher.match(is1, true, true, true);
      }
      List<Citation> citations = matcher.getCitations();
              
      // Enrich the pdf file.
      try (InputStream is2 = new ByteArrayInputStream(byteArray)) {
        enricher.enrich(is2, citations);
      }
    }
  }
  
  /** 
   * Prints the usage.
   */
  private static void printUsage() {
    System.err.println("Usage: java PdfEnricherMain <pdf-file>");
  }
  
  /**
   * Converts the given InputStream into byte array.
   */
  public static byte[] toByteArray(InputStream stream) throws IOException {
    try (ByteArrayOutputStream b = new ByteArrayOutputStream()) {
      byte[] buffer = new byte[1024];
      int len;
      while ((len = stream.read(buffer)) > -1 ) {
          b.write(buffer, 0, len);
      }
      b.flush();
  
      return b.toByteArray();
    }
  }
}
