package xy;

import java.util.List;

import gnu.trove.TIntCollection;
import icecite.models.HasRectangleArrayList;
import icecite.models.HasRectangleList;
import icecite.models.PdfTextBlock;
import icecite.models.plain.PdfPlainTextBlock;
import model.PdfCharacter;
import model.PdfPage;

/**
 * A class that utilizes XYCut in order to identify text blocks in PDF 
 * documents.
 * 
 * @author Claudius Korzen
 */
public class XYCutIntoTextBlocks extends XYCut<PdfCharacter, PdfTextBlock> {
  /**
   * Cuts the given pdf page into text blocks.
   * 
   * @param page the PDF page.
   */
  public List<PdfTextBlock> cut(PdfPage page) {
    // TODO: Avoid wrapping into HasRectangleArrayList.
    return cut(new HasRectangleArrayList<>(page.getTextCharacters()));
  }
    
  @Override
  public float getVerticalLaneWidth(HasRectangleList<PdfCharacter> chars) {
    return 2f * chars.getMostCommonWidth();
  }

  @Override
  public boolean isValidVerticalLane(HasRectangleList<PdfCharacter> elements,
      float leftBoundary, float rightBoundary, TIntCollection indexes) {    
    return indexes.isEmpty();
  }

  @Override
  public float getHorizontalLaneHeight(HasRectangleList<PdfCharacter> chars) {
    return 2f * chars.getMostCommonHeight();
  }

  @Override
  public boolean isValidHorizontalLane(HasRectangleList<PdfCharacter> elements,
      float lowerBoundary, float upperBoundary, TIntCollection indexes) {
    return indexes.isEmpty();
  }

  @Override
  public PdfTextBlock wrap(HasRectangleList<PdfCharacter> elements) {
    return new PdfPlainTextBlock(elements);
  }
}
