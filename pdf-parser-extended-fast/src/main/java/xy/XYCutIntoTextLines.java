package xy;

import java.util.List;

import gnu.trove.TIntCollection;
import icecite.models.HasRectangleList;
import icecite.models.PdfTextBlock;
import model.PdfCharacter;
import model.PdfPage;

/**
 * A class that utilizes XYCut in order to identify text lines in text blocks.
 * 
 * @author Claudius Korzen
 */
public class XYCutIntoTextLines extends XYCut<PdfCharacter, PdfTextBlock> {
  public List<PdfTextBlock> cut(PdfPage page) {
    // TODO
    return null;
  }
    
  @Override
  public float getVerticalLaneWidth() {
    // TODO
    return -1;
  }

  @Override
  public boolean isValidVerticalLane(TIntCollection overlappedElements) {
    // TODO
    return false;
  }

  @Override
  public float getHorizontalLaneHeight() {
    // TODO
    return -1;
  }

  @Override
  public boolean isValidHorizontalLane(TIntCollection overlappedElements) {
    // TODO
    return false;
  }

  @Override
  public PdfTextBlock wrap(HasRectangleList<PdfCharacter> elements) {
    // TODO
    return null;
  }
}

