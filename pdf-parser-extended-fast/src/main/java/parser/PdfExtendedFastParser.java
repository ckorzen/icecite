package parser;

import model.PdfDocument;

/**
 * An extended PDF parser. 
 *
 * @author Claudius Korzen
 */
public interface PdfExtendedFastParser {
  /**
   * Parses the given PDF document.
   */
  public void parse(PdfDocument document);
}
