package rules;

import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import de.freiburg.iif.math.MathUtils;
import de.freiburg.iif.model.HasRectangle;
import de.freiburg.iif.model.Rectangle;
import de.freiburg.iif.text.StringUtils;
import model.Characters;
import model.Patterns;
import model.PdfArea;
import model.PdfCharacter;
import model.PdfDocument;
import model.PdfFont;
import model.PdfPage;
import model.PdfTextAlignment;
import model.PdfTextLine;
import model.PdfTextParagraph;
import model.PdfWord;
import model.TextLineStatistics;
import model.TextStatistics;
import statistics.TextLineStatistician;

/**
 * Rules to paragraphs identification.
 *
 * @author Claudius Korzen
 *
 */
public class ParagraphifyRule {
  protected static final Pattern REFERENCE_ANCHOR =
      Pattern.compile("^\\[(.*)\\]\\s+");

  protected static void log(Object text) {
//    System.out.println(text);
  }
  
  /**
   * Returns true, if the given parameters introduces a new paragraph.
   */
  public static boolean introducesNewParagraph(PdfArea block,
      PdfTextParagraph paragraph, PdfTextLine prevLine, PdfTextLine line,
      PdfTextLine nextLine) {
    
    log(line);
    
    // The line doesn't introduce a new paragraph, if the paragraph is empty.
    if (paragraph.getTextLines().isEmpty()) {
      log(1);
      return false;
    }

    // The line doesn't introduce a new paragraph, if the previous and the
    // current line have a overlapped element in common.
    if (haveOverlappedElementInCommon(prevLine, line)) {
      log(2);
      return false;
    }

    // The line introduces a new paragraph, if it doesn't overlap the paragraph
    // horizontally.
    if (!overlapsHorizontally(paragraph, line)) {
      log(3);
      return true;
    }
    
    if (haveSameSpecialFontFace(paragraph, line)) {
      log(4);
      return false;
    }

    if (isItemizeStart(block, paragraph, line)) {
      log(5);
      return true;
    }
    
    if (differInAlignment(block, paragraph, line)) {
      log(6);
      return true;
    }
    
    // TODO: Doesn't work if text is not justified.
    if (prevLineIsTooShort(block, line, prevLine)) {
      log(7);
      return true;
    }

//    if (differInIndentation(block, paragraph, line)) {
//      return true;
//    }
    
    if (prevAndCurrentLineStartsWithReferenceAnchor(prevLine, line)) {
      log(8);
      return true;
    }

//    // The line introduces a new paragraph, if the font size of the line and the
//    // fontsize of the previous line aren't almost equal.
//    if (fontsizesAreTooDifferent(prevLine, line)) {
//      log(7);
//      System.out.println(line.getPage().getPageNumber() + " "  + line);
//      return true;
//    }
    
//    // The line introduces a new paragraph, if the height of the line and the
//    // height of the previous line aren't almost equal.
//    if (lineHeightsAreTooDifferent(prevLine, line)) {
//      log(8);
//      return true;
//    }

    // The line introduces a new paragraph, if the pitch to the previous line
    // is larger than the most common line pitch in the paragraph.
    if (linepitchIsTooLarge(paragraph, prevLine, line)) {
      log(9);
      return true;
    }

    // TODO: Experimental. Identify headings, which have same fontsize as
    // body.
    if (isProbablyHeading(paragraph, prevLine, line)) {
      log(10);
      return true;
    }

    // TODO: Experimental. Identify page numbers.
    if (isProbablyPageNumber(line)) {
      log(11);
      return true;
    }
    
    log(12);
    return false;
  }

  /**
   * Returns true, if the previous line is too short.
   */
  protected static boolean prevLineIsTooShort(PdfArea block,
      PdfTextLine line, PdfTextLine prevLine) {
    if (prevLine == null) {
      return false;
    }

    PdfDocument document = block.getPdfDocument();

    if (document.getTextAlignment() != PdfTextAlignment.JUSTIFIED) {
      return false;
    }

    if (block.getTextLineAlignment() == PdfTextAlignment.CENTERED) {
      return false;
    }
        
    float tolerance = block.getDimensionStatistics().getMostCommonWidth();
    float prevLineMaxX = prevLine.getRectangle().getMaxX();
    float blockMaxX = block.getRectangle().getMaxX();
        
    return MathUtils.isSmaller(prevLineMaxX, blockMaxX, 10 * tolerance);
  }

  /**
   * Returns true, if the indentation of the line differ from the indentation in
   * the given paragraph.
   */
  protected static boolean differInIndentation(PdfArea block,
      PdfTextParagraph para, PdfTextLine line) {
    if (para == null) {
      return false;
    }
    
    if (para.getTextLines() == null || para.getTextLines().size() < 2) {
      return false;
    }

    if (block.getTextLineAlignment() == PdfTextAlignment.CENTERED) {
      return false;
    }

    PdfTextLine lastLine = para.getLastTextLine();
    float tolerance = para.getDimensionStatistics().getMostCommonWidth();

    float lastLineMinX = lastLine.getRectangle().getMinX();
    float lineMinX = line.getRectangle().getMinX();
    
    return !MathUtils.isEqual(lineMinX, lastLineMinX, tolerance);
  }

  protected static boolean haveSameSpecialFontFace(PdfArea block,
      PdfTextLine line) {
    if (block == null) {
      return false;
    }
        
    if (line == null) {
      return false;
    }
    
    TextStatistics docStats = block.getPdfDocument().getTextStatistics();
    PdfFont mostCommonDocFont = docStats.getMostCommonFont();
    float mostCommonDocFontsize = docStats.getMostCommonFontsize();
    
    TextStatistics lineStats = line.getTextStatistics();
    PdfFont mostCommonLineFont = lineStats.getMostCommonFont();
    float mostCommonLineFontsize = lineStats.getMostCommonFontsize();
    
    TextStatistics blockStats = block.getTextStatistics();
    PdfFont mostCommonBlockFont = blockStats.getMostCommonFont();
    float mostCommonBlockFontsize = blockStats.getMostCommonFontsize();
    
    if (mostCommonLineFont == mostCommonBlockFont
        && mostCommonLineFontsize == mostCommonBlockFontsize) {
      
      if (mostCommonLineFont != mostCommonDocFont 
          && mostCommonLineFontsize > mostCommonDocFontsize) {
        return true;
      }
      
      // Check, if block and line are printed in uppercase letters.
      boolean isBlockUpperCase = true;
      for (PdfCharacter character : block.getTextCharacters()) {
        if (Characters.isLatinLetter(character) 
            && !Characters.isUppercase(character)) {
          isBlockUpperCase = false;
          break;
        }
      }
      
      boolean isLineUpperCase = true;
      for (PdfCharacter character : line.getTextCharacters()) {
        if (Characters.isLatinLetter(character) 
            && !Characters.isUppercase(character)) {
          isLineUpperCase = false;
          break;
        }
      }
      
      return isBlockUpperCase && isLineUpperCase;
    }
    return false;
  }
  
  /**
   * Returns true, if the alignment of the line differ from the alignment in
   * the given paragraph.
   */
  protected static boolean differInAlignment(PdfArea block,
      PdfTextParagraph para, PdfTextLine line) {
    if (para == null) {
      return false;
    }
    
    if (line == null) {
      return false;
    }
    
    if (para.getTextLines() == null || para.getTextLines().isEmpty()) {
      return false;
    }

    PdfTextLine lastLine = para.getLastTextLine();
    
    if (lastLine == null) {
      return false;
    }
              
    if (!lastLine.isIndented() && line.isIndented()) {
      return true;
    }
    
    if (lastLine.getAlignment() == PdfTextAlignment.CENTERED 
        && line.getAlignment() != PdfTextAlignment.CENTERED) {
      return true;
    }
    
    if (line.getAlignment() == PdfTextAlignment.CENTERED 
        && lastLine.getAlignment() != PdfTextAlignment.CENTERED) {
      return true;
    }
    
    if (line.getAlignment() == PdfTextAlignment.RIGHT 
        && lastLine.getAlignment() != PdfTextAlignment.RIGHT) {
      return true;
    }
    return false;
  }
  
  protected static boolean prevAndCurrentLineStartsWithReferenceAnchor(
      PdfTextLine prevLine, PdfTextLine line) {
    if (prevLine == null || line == null) {
      return false;
    }

    String prevLineStr = prevLine.getUnicode();
    String lineStr = line.getUnicode();

    if (prevLineStr == null || lineStr == null) {
      return false;
    }

    Matcher prevLineMatcher = REFERENCE_ANCHOR.matcher(prevLineStr);
    Matcher lineMatcher = REFERENCE_ANCHOR.matcher(lineStr);

    return prevLineMatcher.find() && lineMatcher.find();
  }

  /**
   * Returns true, if the given two lines are overlapped by a same third
   * element.
   */
  protected static boolean haveOverlappedElementInCommon(PdfTextLine prevLine,
      PdfTextLine line) {
    PdfPage page = line.getPage();
    // The line doesn't introduce a new paragraph, if it is located in the same
    // non text elements as the previous text element.
    List<? extends HasRectangle> prevAreas = null;
    if (prevLine != null) {
      Rectangle prevRectangle = prevLine.getRectangle();
      prevAreas = page.getNonTextElementsOverlapping(prevRectangle);
      
      List<? extends HasRectangle> areas = null;
      if (line != null) {
        Rectangle rectangle = line.getRectangle();
        areas = page.getElementsOverlapping(rectangle);

        areas.retainAll(prevAreas);

        if (!areas.isEmpty()) {          
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Returns true, if the given elements overlaps horizontally.
   */
  protected static boolean overlapsHorizontally(PdfArea area,
      PdfTextLine line2) {
    return area.getColumnXRange().equals(line2.getColumnXRange());
//    return hr1.getRectangle().overlapsHorizontally(hr2.getRectangle());
  }

  /**
   * Analyzes the fontsizes of the given lines and returns true, if the
   * fontsizes "are too different".
   */
  protected static boolean fontsizesAreTooDifferent(PdfTextLine prevLine,
      PdfTextLine line) {
    float lineFontsize = line != null ? line.getFontsize() : 0;
    float prevLineFontsize = prevLine != null ? prevLine.getFontsize() : 0;
    
    return MathUtils.isLarger(lineFontsize, prevLineFontsize, 0.49f)
        || MathUtils.isSmaller(lineFontsize, prevLineFontsize, 0.49f);
  }

  /**
   * Analyzes the heights of the given lines and returns true, if the
   * heights "are too different".
   */
  protected static boolean lineHeightsAreTooDifferent(PdfTextLine prevLine,
      PdfTextLine line) {
    float lineHeight = line != null ? line.getRectangle().getHeight() : 0;
    float prevLineHeight = prevLine != null 
        ? prevLine.getRectangle().getHeight() : 0;

    float largerLineHeight = Math.max(lineHeight, prevLineHeight);
    float smallerLineHeight = Math.min(lineHeight, prevLineHeight);
    
    return !MathUtils.isEqual(largerLineHeight, smallerLineHeight,
        smallerLineHeight);
  }
  
  // /**
  // * Analyzes the linepitch and returns true, if the linepitch is too large.
  // */
  // protected static boolean linepitchIsTooLarge(PdfPage page,
  // PdfTextParagraph paragraph, PdfTextLine prevLine, PdfTextLine line) {
  //
  // float pitch = TextLineStatistician.computeLinePitch(prevLine, line);
  // TextLineStatistics pageLineStatistics = page.getTextLineStatistics();
  // float pageLinePitch = pageLineStatistics.getMostCommonLinePitch();
  //
  // if (MathUtils.isLarger(pitch, pageLinePitch, pageLinePitch)) {
  // return true;
  // }
  //
  // if (paragraph.getTextLines().size() > 1) {
  // TextLineStatistics paraStatistics = paragraph.getTextLineStatistics();
  // float paragraphPitch = paraStatistics.getMostCommonLinePitch();
  //
  // // The line introduces a new paragraph, if the pitch to the previous line
  // // is larger than the most common line pitch in the paragraph.
  // if (MathUtils.isLarger(pitch, paragraphPitch, 0.5f * paragraphPitch)) {
  // return true;
  // }
  // }
  //
  // return false;
  // }

  /**
   * Analyzes the linepitch and returns true, if the linepitch is too large.
   */
  protected static boolean linepitchIsTooLarge(PdfTextParagraph paragraph,
      PdfTextLine prevLine, PdfTextLine line) {
    PdfPage page = line.getPage();

    float pitch = TextLineStatistician.computeLinePitch(prevLine, line);
    float basePitch = TextLineStatistician.computeBaseLinePitch(prevLine, line);

    TextLineStatistics pageLineStatistics = page.getTextLineStatistics();
    float pageLinePitch = pageLineStatistics.getSmallestSignificantLinepitch();
    float pageBaselinePitch =
        pageLineStatistics.getSmallestSignificantBaselinepitch();

    if (MathUtils.isLarger(pitch, pageLinePitch, pageLinePitch)
        && MathUtils.isLarger(basePitch, pageBaselinePitch, 2f)) {

      return true;
    }

    if (paragraph.getTextLines().size() > 1) {
      TextLineStatistics paraStatistics = paragraph.getTextLineStatistics();
      float paragraphPitch = paraStatistics.getMostCommonLinePitch();
      float paragraphBasePitch = paraStatistics.getMostCommonBaselinePitch();

      // The line introduces a new paragraph, if the pitch to the previous line
      // is larger than the most common line pitch in the paragraph.
      if (MathUtils.isLarger(pitch, paragraphPitch, 0.5f * paragraphPitch)
          && MathUtils.isLarger(basePitch, paragraphBasePitch, 2f)) {
        return true;
      }
    }

    return false;
  }

  /**
   * Returns true, if the given line is probably a heading. EXPERIMENTAL.
   */
  protected static boolean isProbablyHeading(PdfTextParagraph paragraph,
      PdfTextLine prevLine, PdfTextLine line) {
    PdfPage page = line.getPage();
    PdfFont pageFont = page.getFont();
    PdfFont prevLineFont = prevLine != null ? prevLine.getFont() : null;
    PdfWord firstWord = line != null ? line.getFirstWord() : null;
    PdfWord lastWord = prevLine != null ? prevLine.getLastWord() : null;
    PdfFont lastWordFont = lastWord != null ? lastWord.getFont() : null;
    PdfFont firstWordFont = firstWord != null ? firstWord.getFont() : null;

    if (prevLine != null
        && prevLineFont != null
        && !prevLineFont.equals(pageFont)
        && lastWordFont != null
        && !lastWordFont.equals(firstWordFont)
        && MathUtils.isSmaller(prevLine.getRectangle().getMaxX(),
            line.getRectangle().getMaxX(), 5f)
        && paragraph.getTextLines().size() == 1) {
      return true;
    }
    return false;
  }
  
  /**
   * Returns true, if the given line is probably a page number. EXPERIMENTAL.
   * TO be more exact: This method returns true when the given paragraph 
   * represents an integer value and when the paragraph is centered in page. 
   */
  protected static boolean isProbablyPageNumber(PdfTextLine line) {
    if (line == null) {
      return false;
    }
    
    String text = line.getUnicode(); 
    boolean isNumber = StringUtils.isInteger(text);
           
    if (isNumber) {
      PdfPage page = line.getPage();
      Rectangle pageRect = page.getRectangle();
      Rectangle paraRect = line.getRectangle();
      
      float leftMargin = paraRect.getMinX() - pageRect.getMinX();
      float rightMargin = pageRect.getMaxX() - paraRect.getMaxX();
            
      return MathUtils.isEqual(leftMargin, rightMargin, 5f);
    }
    
    return false;
  }
  
  protected static boolean isItemizeStart(PdfArea block, 
      PdfTextParagraph paragraph, PdfTextLine line) {
    // Check if the line is a heading or itemize (i.e. preceded by a 
    // numbering). 
    
    List<Pattern> itemizeStartPatterns = Patterns.ITEMIZE_START_PATTERNS;
    
    boolean matches = false;
    for (Pattern pattern : itemizeStartPatterns) {
      Matcher m = pattern.matcher(line.getFirstWord().getUnicode());
        
      if (m.matches() && !m.group(1).isEmpty() && line.getWords().size() > 1) {
        matches = true;
        break;
      }
    }
    
    if (!matches) {
      return false;
    }
        
    if (paragraph != null) {
      // "Normal" lines could be started by a numbering, too. So, take also 
      // the line pitch into account (headings and itemizes must have a 
      // larger linepitch to previous line.
      PdfDocument doc = line.getPdfDocument();
      float mcPitch = doc.getTextLineStatistics().getMostCommonLinePitch();
      float linePitch = Float.MAX_VALUE;
      PdfTextLine prevLine = paragraph.getLastTextLine();
      if (prevLine != null) {
        linePitch = TextLineStatistician.computeLinePitch(prevLine, line);  
      }
                
      return MathUtils.isLarger(linePitch, mcPitch, 1f);
    }
    
    return false;
  }
}
