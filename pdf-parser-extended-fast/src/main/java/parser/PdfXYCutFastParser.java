package parser;

import java.awt.Color;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import drawer.PdfDrawer;
import drawer.pdfbox.PdfBoxDrawer;
import icecite.models.PdfTextBlock;
import model.PdfDocument;
import model.PdfPage;
import xy.XYCutIntoTextBlocks;

/**
 * An implementation of a PdfExtendedParser, mainly based on the xy-cut 
 * algorithm.
 *
 * @author Claudius Korzen
 */
public class PdfXYCutFastParser implements PdfExtendedFastParser {
  /**
   * The text block identifier.
   */
  protected XYCutIntoTextBlocks xyCutIntoTextBlocks;
  
  /**
   * Creates a new PdfXYCutParser.
   */
  public PdfXYCutFastParser() {
    this.xyCutIntoTextBlocks = new XYCutIntoTextBlocks();
  }
  
  @Override
  public void parse(PdfDocument document) {
    long start = System.currentTimeMillis();
    for (PdfPage page : document.getPages()) {
      identifyTextBlocks(page);
      identifyTextLines(page);
      identifyTextWords(page);
    }
    long end = System.currentTimeMillis();
    System.out.println("Time needed to identify blocks: " + (end - start));
    
    // Visualize:
    try {
      visualize(document);
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
  
  /**
   * Identifies text blocks in the given page.
   *  
   * @param page the page to process.
   * 
   * @return the identified text blocks.
   */
  protected void identifyTextBlocks(PdfPage page) {
    page.setTextBlocks(this.xyCutIntoTextBlocks.cut(page));
  }

  /**
   * Identifies text lines in the given page.
   *  
   * @param page the page to process.
   */
  protected void identifyTextLines(PdfPage page) {

  }
  
  /**
   * Identifies text words in the given page.
   *  
   * @param page the page to process.
   */
  protected void identifyTextWords(PdfPage page) {
    
  }
  
  // TODO: Remove.
  protected void visualize(PdfDocument document) throws IOException {
    PdfDrawer drawer = new PdfBoxDrawer(document.getPdfFile());
    
    for (PdfPage page : document.getPages()) {
      for (PdfTextBlock block : page.getTextBlocks()) {
        drawer.drawRectangle(block.getBoundingBox(), page.getPageNumber(), Color.RED, 1f);
      }
    }
    
    // Write the visualization to file.
    File file = new File("/home/korzen/Downloads/blocks.pdf");
    FileOutputStream stream = new FileOutputStream(file);
    drawer.writeTo(stream);
    stream.close();
  }
}
