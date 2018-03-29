package de.freiburg.iif.extraction.references;

import java.io.File;
import java.io.IOException;
import java.util.List;

import junit.framework.Assert;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.util.PDFTextStripper;
import org.junit.Test;

import de.freiburg.iif.extraction.stripper.PdfBoxTextLineStripper;
import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;

/**
 * Tests for the methods in ReferencesMetadataMatcher
 * 
 * @author Claudius Korzen
 * 
 */
public class ReferencesMetadataMatcherTest {

  /**
   * Test the method getUppercaseWords().
   * 
   * @throws IOException
   *           if executing the method fails.
   */
  @Test
  public void testCreateQuery() throws IOException {
    // String nfdNormalizedString = Normalizer.normalize("Hâjék",
    // Normalizer.Form.NFD);
    // Pattern pattern = Pattern.compile("\\p{InCombiningDiacriticalMarks}+");
    // System.out.println(pattern.matcher(nfdNormalizedString).replaceAll(""));
  }

  /**
   * Test the method getPosOfFirstAuthor()
   * 
   * @throws IOException
   *           if querying the metadata knowledge fails.
   */
  @Test
  public void testGetPosOfFirstAuthor() throws IOException {
    ReferencesMetadataMatcher matcher = new ReferencesMetadataMatcher();
    Region line = new Region();

    line.setText("(131 R. Miller, E. Pessa, and G. Resconi (1997), Non-");
    Assert.assertEquals(8, matcher.getPosOfFirstAuthor(line));

    line.setText("Fuzzy Modal Logic. In: Fuzzy Logic in Artificial  ");
    Assert.assertEquals(-1, matcher.getPosOfFirstAuthor(line));

    line.setText("“Research Report of Navigation Support ");
    Assert.assertEquals(-1, matcher.getPosOfFirstAuthor(line));
  }

  /**
   * Test the method compareLinePositions.
   */
  @Test
  public void testCompareX() {
    ReferencesMetadataMatcher matcher = new ReferencesMetadataMatcher();

    Region line1 =
        new Region(343.399902f, 653.959473f, 215.542358f, 6.000000f);
    line1.setXOfLineEnd(558.942261f);
    line1.setText("MMSE multiuser detection,” IEEE Trans. Inform.  ");

    Region line2 =
        new Region(343.899994f, 664.359741f, 161.859528f, 5.937500f);
    line2.setXOfLineEnd(505.759521f);
    line2.setText("theory, vol. 43, pp. 858-871, May 1997.  ");

    Assert.assertEquals(0, matcher.compareLinePositions(line1, line2, false));

    Region r1 = new Region(50, 0, 50, 0);
    r1.setText("AAAAA");
    r1.setXOfLineEnd(r1.getX() + r1.getWidth());

    Region r2 = new Region(50, 0, 50, 0);
    r2.setText("AAAAA");
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());

    Assert.assertEquals(0, matcher.compareLinePositions(r1, r2, false));

    r2.setX(30);
    r2.setWidth(70);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(1, matcher.compareLinePositions(r1, r2, false));

    r2.setX(20);
    r2.setWidth(80);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(1, matcher.compareLinePositions(r1, r2, false));

    r2.setX(20);
    r2.setWidth(20);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(2, matcher.compareLinePositions(r1, r2, false));

    r2.setX(60);
    r2.setWidth(40);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(0, matcher.compareLinePositions(r1, r2, false));

    r2.setX(80);
    r2.setWidth(20);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(-1, matcher.compareLinePositions(r1, r2, false));

    r2.setX(110);
    r2.setWidth(10);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(-2, matcher.compareLinePositions(r1, r2, false));

    r2 = new Region(50, 0, 50, 0);
    r2.setText("AAAAA");
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());

    Assert.assertEquals(0, matcher.compareLinePositions(r1, r2, true));

    r2.setX(30);
    r2.setWidth(70);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(0, matcher.compareLinePositions(r1, r2, true));

    r2.setX(10);
    r2.setWidth(70);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(1, matcher.compareLinePositions(r1, r2, true));

    r2.setX(10);
    r2.setWidth(50);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(1, matcher.compareLinePositions(r1, r2, true));

    r2.setX(10);
    r2.setWidth(10);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(2, matcher.compareLinePositions(r1, r2, true));

    r2.setX(10);
    r2.setWidth(100);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(0, matcher.compareLinePositions(r1, r2, true));

    r2.setX(10);
    r2.setWidth(120);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(-1, matcher.compareLinePositions(r1, r2, true));

    r2.setX(110);
    r2.setWidth(200);
    r2.setXOfLineEnd(r2.getX() + r2.getWidth());
    Assert.assertEquals(-2, matcher.compareLinePositions(r1, r2, true));
  }

  /**
   * Test the method compareLinePositions.
   * 
   * @throws IOException if something fails.
   */
  @Test
  public void testCompareY() throws IOException {
    PdfBoxTextLineStripper stripper = new PdfBoxTextLineStripper(null);
    Region r1 = new Region(0, 200, 0, 10);
    Region r2 = new Region(0, 200, 0, 10);
    
    Assert.assertEquals(0, stripper.compareY(r1, r1));
    Assert.assertEquals(0, stripper.compareY(r1, r2));
    
    r2 = new Region(0, 195, 0, 10);
    Assert.assertEquals(0, stripper.compareY(r1, r2));
    
    r2 = new Region(0, 180, 0, 10);
    Assert.assertEquals(2, stripper.compareY(r1, r2));
    
    r2 = new Region(0, 10, 0, 10);
    Assert.assertEquals(2, stripper.compareY(r1, r2));
    
    r2 = new Region(0, 220, 0, 10);
    Assert.assertEquals(-1, stripper.compareY(r1, r2));
    
    r2 = new Region(0, 500, 0, 10);
    Assert.assertEquals(-2, stripper.compareY(r1, r2));
  }
     
  /**
   * Test something
   * 
   * @throws IOException wtf?
   */
  @Test
  public void testSomething() throws IOException {    
    String USER_DIR = System.getProperty("user.dir");
    /** The base directory */
    String BASE_DIR =
        USER_DIR + "/src/test/resources/de/freiburg/iif/pdfextraction";
    /** The pdf directory */
    String PDF_DIR = BASE_DIR + "/pdfs";

    File pdfFile = new File(PDF_DIR + File.separatorChar + "53_979.pdf");

    PDFTextStripper s = new PDFTextStripper();
    System.out.println(s.getText(PDDocument.load(pdfFile)));
    
//    TextLineStripper3 stripper =
//        new TextLineStripper3(PDDocument.load(pdfFile));
//    List<Region> lines = stripper.getLines();
//    if (lines != null) {
//      for (Region line : lines) {
//        if (line != null) System.out.println("\""+line.getText()+"\" ");
//      }
//    }
    
    ReferencesMetadataMatcher matcher = new ReferencesMetadataMatcher();
    List<HasMetadata> records = matcher.match(PDDocument.load(pdfFile), false, false, 0);
    if (records != null) {
      for (HasMetadata record : records) {
        if (record != null) System.out.println(record);
      }
    }
  }
}
