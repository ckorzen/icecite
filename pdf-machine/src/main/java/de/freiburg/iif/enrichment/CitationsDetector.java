package de.freiburg.iif.enrichment;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.util.TextPosition;

import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;

/**
 * Detects the positions of citations in pdf.
 *  
 * @author Claudius Korzen
 *
 */
public class CitationsDetector {
  /** The pattern to find citations in free text */
  protected Pattern citationsPattern = Pattern.compile("\\[(\\d{1,2})\\]");
  
  /**
   * Detects the citations in given text lines.
   * 
   * @param records the extracted references.
   * @param lines the extracted text lines.
   * @return Map, that maps the citation areas (given as PDRectangle) to a given
   * reference.
   */
  public List<Citation> detect(List<HasMetadata> records, List<Region> lines) {
    List<Citation> list = new ArrayList<Citation>();
    
    for (Region line : lines) {
      List<TextPosition> textPositions = line.getTextPositions();
      // Try to find the areas of all citations in free text.
      Matcher m = citationsPattern.matcher(line.getText());

      while (m.find()) {
        // The index of citation start in line.
        int start = Math.max(m.start(), 0);
        // The index of citation end in line.
        int end = Math.min(m.end(), textPositions.size());
        // The unique id, identifying the related reference. Subtract 1, because
        // the ids are 1-based.
        int referenceId = Integer.parseInt(m.group(1)) - 1;
        // The page number.
        int pageNum = line.getPageNumber();
        
        if (start < textPositions.size() && end - 1 < textPositions.size()) {
          // The first text position of citation.
          TextPosition startPosition = textPositions.get(start);
          // The last text position of citation.
          TextPosition endPosition = textPositions.get(end - 1);
              
          // Determine the citation area (i.e. the lower left and the upper right).
          PDRectangle rect = new PDRectangle();
          rect.setLowerLeftX(startPosition.getX());
          rect.setLowerLeftY(startPosition.getY() + 2);
          float width = endPosition.getCharacter() != null ? endPosition.getWidth() : 0;
          float height = startPosition.getCharacter() != null ? Math.max(startPosition.getHeight(), startPosition.getFontSize()) : 0;
          rect.setUpperRightX(endPosition.getX() + width);
          rect.setUpperRightY(endPosition.getY() - height);
          
          // Ensure that referenceId doesn't excced the number of references.
          if (referenceId < records.size()) {
            HasMetadata entry = records.get(referenceId);
            list.add(new Citation(pageNum - 1, rect, entry));
          }
        }
      }
    }
    
    return list;
  }
  
  public class Citation {
    public HasMetadata entry;
    public PDRectangle rectangle;
    public int page;
    /**
     * The constructor.
     */
    public Citation(int page, PDRectangle rectangle, HasMetadata entry) {
      this.page = page;
      this.rectangle = rectangle;
      this.entry = entry;
    }
    
    public String toString() {
      return "[" + page + ", " + rectangle + ", " + entry +"]";
    }
  }
}
