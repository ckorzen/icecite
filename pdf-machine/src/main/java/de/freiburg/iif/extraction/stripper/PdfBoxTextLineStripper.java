package de.freiburg.iif.extraction.stripper;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.util.TextNormalize;
import org.apache.pdfbox.util.TextPosition;

import de.freiburg.iif.model.Region;


/**
 * The class TextLineStripper, that extracts textlines from a PDF-file.
 * 
 * @author Claudius Korzen
 * 
 */
public class PdfBoxTextLineStripper extends PdfBoxTextStripper {
  /** The lines of the whole pdf file */
  protected List<Region> lines;

  /** The lines of the current page */
  protected List<Region> linesOfPage;

  // TODO: Move pattern to a separate class.
  /** Pattern to identify captions */
  protected static Pattern CAPTION_PATTERN = Pattern
      .compile("^(Fig.|FIG.|Figure|FIGURE|Table|TABLE)");

  /**
   * Pattern for identifying reference anchors. Instead of "\d" (digit
   * character), "\w" (word character) is used to meet anchors like "[l]"
   * instead of "[1]" (resulting from extraction failures). The pattern will
   * find anchors like "[1]" and "1."
   */
  // TODO: Move pattern to a separate class.
  protected static final Pattern REFERENCE_ANCHOR_PATTERN = Pattern
      .compile("(^\\[\\w{1,3}\\]|^\\d{1,3}\\.\\D)(.+)");

  // TODO: Move pattern to a separate class.
  /** Pattern to identify the header of a bibliography. */
  protected static Pattern BIB_HEADER_PATTERN =
      Pattern
          .compile(
              "^\\(?[A-Za-z0-9]{0,3}(\\)|\\.)?\\s?(Reference|References|Bibliography)\\s?[:punct:]?\\s*$",
              Pattern.MULTILINE + Pattern.CASE_INSENSITIVE);

  // TODO: Move pattern to a separate class.
  /** The charPattern */
  protected static Pattern charPattern = Pattern.compile("[A-Za-z0-9]");

  /** The StringBuilder to build the fulltext of the pdf */
  protected StringBuilder fulltext;

  /** The log4j-logger */
  protected Log LOG = LogFactory.getLog(PdfBoxTextLineStripper.class);

  /** Flag to decide if lines should be checked, if the have to be splitted */
  protected boolean splitLines;

  /**
   * Constructor of TextLineStripper.
   * 
   * @param doc
   *          the PDDocument.
   * @throws IOException
   *           if loading of the properties fails.
   */
  public PdfBoxTextLineStripper(PDDocument doc) throws IOException {
    super();
    this.document = doc;
    this.lines = new ArrayList<Region>();
    this.linesOfPage = new ArrayList<Region>();
    this.fulltext = new StringBuilder();
    this.normalize = new TextNormalize(this.outputEncoding);
  }

  /**
   * Processes the TextPositions of an extracted line. It may happen, that
   * columns weren't detected, such that an extracted line contains the
   * TextPositions of multiple columns. This method tries to handle such cases
   * by splitting lines, if the gap between to words is too large.
   */
  @Override
  protected void onLineExtracted(List<TextPosition> positions, int pageNumber) {
    if (!splitLines) {
      Region line = processTextLine(positions, pageNumber);
      linesOfPage.add(line);
      return;
    }

    // TODO: Extract to a separate method.
    // Enrich WordSeparators with x- and y-values to be able to sort the line.
    TextPosition lastNonWordSeparator = null;
    for (TextPosition pos : positions) {
      if (pos != null) {
        if (pos instanceof WordSeparator) {
          if (lastNonWordSeparator != null) {
            WordSeparator sep = (WordSeparator) pos;
            sep.setX(lastNonWordSeparator.getX()
                + lastNonWordSeparator.getWidth());
            sep.setY(lastNonWordSeparator.getY());
          }
        } else {
          lastNonWordSeparator = pos;
        }
      }
    }

    Collections.sort(positions, new HorizontalTextPositionComparator3());

    // Split the line if necessary (if the line won't be splitted, the whole
    // line is positioned in splitLine[0].
    List<Region> splitLine = splitLine(positions, pageNumber);

    if (splitLine != null) {
      for (int i = 0; i < splitLine.size(); i++) {
        Region line = splitLine.get(i);
        // Consider only lines, whose height is > 0.
        if (line != null && line.getHeight() > 0) {
          // Decide, if the line is meaningful.
          line.setIsMeaningful(isMeaningful(line));
          linesOfPage.add(line);
        }
      }
    }
  }

  /**
   * End a page. Default implementation is to do nothing. Subclasses may provide
   * additional information.
   * 
   * @param page
   *          The page we are about to process.
   * 
   * @throws IOException
   *           If there is any error writing to the stream.
   */
  protected void endPage(PDPage page, int pageNumber) throws IOException {
    if (!splitLines) {
      lines.addAll(linesOfPage);
      linesOfPage.clear();
      return;
    }

    LOG.debug("*****************");
    LOG.debug("* LINES OF PAGE *");
    LOG.debug("*****************");
    for (Region line : linesOfPage) {
      LOG.debug(line);
    }
    LOG.debug("*****************");

    // All lines of the page are stored in pendingLines.
    // Sort pendingLines by their meaningfulness.
    Collections.sort(linesOfPage, new MeaningfulComparator());

    LOG.debug("*****************************************");
    LOG.debug("* LINES AFTER SORTING BY MEANINGFULNESS *");
    LOG.debug("*****************************************");
    for (Region line : linesOfPage) {
      LOG.debug(line);
    }
    LOG.debug("*****************************************");

    // Classify the lines into columns.
    List<List<Region>> columns = fillColumns(linesOfPage);

    // Group the lines to identify regions, which we can ignore (like captions,
    // tables, etc.).
    List<Region> group = new ArrayList<Region>();

    Region prevLine = null;
    for (int i = 0; i < columns.size(); i++) {
      List<Region> column = columns.get(i);
      LOG.debug("*********************");
      LOG.debug("* LINES OF COLUMN " + i + "*");
      LOG.debug("*********************");
      for (int j = 0; j < column.size(); j++) {
        Region line = column.get(j);

        // Add the line to the current group, until the distance to prevLine is
        // "too" large (until Math.abs(compareY) > 1).
        int compareY = compareY(prevLine, line);
        if (Math.abs(compareY) > 1) {
          LOG.debug("----- " + consider(group) + " -----");
          if (consider(group)) {
            lines.addAll(group);
          }
          group = new ArrayList<Region>();
        }

        // It may happen, that a line was split erroneously. Merge the line with
        // nextLine, if they share the same y-value.
        Region nextLine = j < column.size() - 1 ? column.get(j + 1) : null;
        while (nextLine != null && compareY(line, nextLine) == 0) {
          // Using line.getX() doesn't work for 01307287.pdf (9th reference).
          LOG.debug(">>> merging " + line + " and " + nextLine);
          if (line.getX() <= nextLine.getX()) {
            LOG.debug("line nextLine");
            line = merge(line, nextLine);
          } else {
            LOG.debug("nextLine line");
            line = merge(nextLine, line);
          }
          j++;
          nextLine = j < column.size() - 1 ? column.get(j + 1) : null;
        }
        LOG.debug(line + ", " + line.isMeaningful());
        // Add the line to the current group.
        group.add(line);

        prevLine = line;
      }
      LOG.debug("*********************");
    }

    LOG.debug("----- " + consider(group) + " -----");
    // Don't forget to process the last group.
    if (consider(group)) {
      lines.addAll(group);
    }

    linesOfPage.clear();
  }

  /**
   * Splits a line (if necessary) and return all split lines. Because PDFBox
   * extracts line over multiple columns from time to time, we have to check, if
   * the line must be splitted (because it contains multiple lines from various
   * columns). The gap-widths within a line are analyzed and the line is split
   * if the gap-widths alters.
   * 
   * @param line
   *          the line to analyze.
   * @param pageNumber
   *          the pagenumber of line.
   * @return the split lines.
   */
  protected List<Region> splitLine(List<TextPosition> line, int pageNumber) {
    // The list of split lines to return.
    List<Region> splitLines = new ArrayList<Region>();
    // Compute the splitPoints for the line.
    List<Integer> splitPoints = getSplitPoints(line);

    // Split the line on every splitPoint.
    int prevSplitPoint = 0;
    for (int splitPoint : splitPoints) {
      List<TextPosition> subList =
          new ArrayList<TextPosition>(line.subList(prevSplitPoint, splitPoint + 1));
      // Collections.sort(subList, new HorizontalTextPositionComparator3());
      // Process the split list.
      Region splitLine = processTextLine(subList, pageNumber);
      if (splitLine != null) {
        splitLines.add(splitLine);
      }
      prevSplitPoint = splitPoint + 1;
    }

    // Don't forget to process the rest of the line.
    List<TextPosition> subList = new ArrayList<TextPosition>(line.subList(prevSplitPoint, line.size()));
    // Collections.sort(subList, new HorizontalTextPositionComparator3());
    // Process the split list.
    Region splitLine = processTextLine(subList, pageNumber);
    if (splitLine != null) {
      splitLines.add(splitLine);
    }

    return splitLines;
  }

  /**
   * Tries to find the splitPoints for a line. For that, the gap sizes of the
   * line are analyzed. A splitPoint is the position, where gap-size alters
   * within a line.
   * 
   * @param line
   *          the line to analyze.
   * @return the computed splitPoints.
   */
  protected List<Integer> getSplitPoints(List<TextPosition> line) {
    List<Integer> splitPoints = new ArrayList<Integer>();

    if (line != null) {
      // Store all the gaps in a map of the form "gapWidth -> <positions>"
      Map<Integer, List<Integer>> gaps = new HashMap<Integer, List<Integer>>();

      for (int i = 0; i < line.size(); i++) {
        TextPosition pos = line.get(i);

        // // ********
        // // HACK for 01307287.pdf, reference [9]: A string of previous column
        // // is added to a string of the current column without a whitespace.
        // // Hence, split the line, if the gap between 2 chars is too large.
        // // TODO: Implement it more reasonable.
        // int prevGap = 0;
        // TextPosition prevPos = i > 0 ? line.get(i - 1) : null;
        // if (prevPos != null && prevPos.getCharacter() != null && pos != null
        // && pos.getCharacter() != null) {
        // prevGap = (int) (pos.getX() - (prevPos.getX() + prevPos.getWidth()));
        // if (prevGap > 50 || prevGap < 0) {
        // splitPoints.add(i - 1);
        // }
        // }
        // // ********

        String text = pos != null ? pos.getCharacter() : null;
        // Search for potential splitpoints, i.e. whitespaces.
        if (pos instanceof WordSeparator || " ".equals(text)) {
          // Search for the first preceding TextPosition != null.
          TextPosition prevPos = null;
          int left = i - 1;
          while (prevPos == null && left >= 0) {
            TextPosition tmpPos = line.get(left);
            if (tmpPos != null && tmpPos.getCharacter() != null) {
              prevPos = tmpPos;
            }
            left--;
          }

          // Search for the first succeeding TextPosition != null.
          TextPosition nextPos = null;
          int right = i + 1;
          while (nextPos == null && right < line.size()) {
            TextPosition tmpPos = line.get(right);
            if (tmpPos != null && tmpPos.getCharacter() != null) {
              nextPos = tmpPos;
            }
            right++;
          }

          // Compute the gap between prevPos and nextPos.
          if (prevPos != null && nextPos != null) {
            float prevBorder = prevPos.getX() + prevPos.getWidth();
            float nextBorder = nextPos.getX();
            int gap = Math.round(nextBorder - prevBorder);
            // Add the gap with the current position to the gaps-map.
            if (gaps.containsKey(gap)) {
              gaps.get(gap).add(i);
            } else {
              List<Integer> positions = new ArrayList<Integer>();
              positions.add(i);
              gaps.put(gap, positions);
            }
          }
        }
      }

      // Compute the splitPoints.
      if (gaps.size() > 1) {
        int prevGap = Integer.MAX_VALUE;

        // Sort the gaps by their sizes.
        List<Integer> gapsList = new ArrayList<Integer>();
        gapsList.addAll(gaps.keySet());
        Collections.sort(gapsList);

        // Iterate over the sorted gapsList and write out the last position of
        // those gaps, which are significantly larger than its preceding gap.
        for (int gap : gapsList) {
          List<Integer> positions = gaps.get(gap);
          if (gap - 7 > prevGap) { // TODO: Parameterize the 7.
            splitPoints.add(positions.get(positions.size() - 1));
          }
          prevGap = gap;
        }

        Collections.sort(splitPoints);
      }
    }
    return splitPoints;
  }

  /**
   * Sorts the given lines into columns.
   * 
   * @param pendingLines
   *          the lines to process.
   * @return the list of columns, each column contains a list of lines.
   */
  private List<List<Region>> fillColumns(List<Region> pendingLines) {
    List<List<Region>> columns = new ArrayList<List<Region>>();
    List<Region> column = new ArrayList<Region>();
    int numOfMeaningFulLinesInColumn = 0;

    LOG.debug("****************");
    LOG.debug("* FILL COLUMNS *");
    LOG.debug("****************");

    if (pendingLines != null) {
      for (int i = 0; i < pendingLines.size(); i++) {
        Region line = pendingLines.get(i);
        LOG.debug(line);
        // Grab the next pending line.
        if (line == null || !line.isPending()) {
          continue;
        }
        column.add(line);
        line.setIsPending(false);
        if (line.isMeaningful()) {
          numOfMeaningFulLinesInColumn++;
        }

        for (int j = 0; j < pendingLines.size(); j++) {
          Region nextLine = pendingLines.get(j);
          // Search for all lines, which are pending and overlap with the
          // grabbed line.

          if (nextLine == null || !nextLine.isPending()) {
            continue;
          }

          int compareX = compareX(line, nextLine, false);
          if (Math.abs(compareX) < 2) {
            LOG.debug("  " + nextLine);
            LOG.debug("    reference line: " + line);
            column.add(nextLine);
            nextLine.setIsPending(false);
            if (nextLine.isMeaningful()) {
              numOfMeaningFulLinesInColumn++;
            }

            // Grab a new line as the representative for the current column.
            // But don't grab simply the previous meaningful line. If the
            // previous meaningful line in a column is the header of page
            // (which overlaps usually all columns), the lines of all further
            // columns will be assigned to the current column. To avoid this
            // scenario, take always the line in the middle of the column.
            // If this line isn't meaningful, iterate over the line reverseley
            // int the first quarter of lines as long as a meaningful line is
            // found or the first line of the column is reached.
            int k = numOfMeaningFulLinesInColumn / 2;
            Region tmpLine = column.get(k);
            // If tmpLine != null, tmpLine is definitely meaningful!
            if (tmpLine != null) {
              line = tmpLine;
            }

            // // Replace line nextLine, if nextLine is meaningful.
            // if (nextLine.isMeaningful()) {

            // float lineWidth = line.getXOfLineEnd() - line.getX();
            // float nextLineWidth = nextLine.getXOfLineEnd() - nextLine.getX();
            // line = nextLineWidth < lineWidth ? nextLine : line;
            // // line = nextLine;
            // }
          }
        }

        // Sort the line in the column by their y-values.
        Collections.sort(column, new VerticalRegionComparator3());

        columns.add(column);
        column = new ArrayList<Region>();
        numOfMeaningFulLinesInColumn = 0;
      }
    }
    LOG.debug("****************");

    // Sort the columns by the x-values of the first line in column.
    Collections.sort(columns, new ColumnsComparator());

    return columns;
  }

  /**
   * Processes a textline.
   * 
   * @param line
   *          the TextPositions of line
   * @param pageNumber
   *          the pagenumber of line.
   * @return the line as an Region.
   */
  protected Region processTextLine(List<TextPosition> line, int pageNumber) {
    Map<PDFont, Integer> fontmap = new HashMap<PDFont, Integer>();
    StringBuilder lineBuilder = new StringBuilder();
    float lineX = Float.MAX_VALUE;
    float lineY = Float.MAX_VALUE;
    float lineYLowerLeft = Float.MAX_VALUE;
    float lineHeight = 0;
    float lineWidth = 0;
    // float sumOfFontsizes = 0;
    // float numOfFontsizes = 0;
    Map<Integer, Integer> fontsizes = new HashMap<Integer, Integer>();
    int numOfUpperCases = 0;
//    int numOfLowerCases = 0;
    float numOfChars = 0;
    int fontFlag = 0;
    String fontname = null;

    if (line != null) {
      LOG.debug("size: " + line.size());
      for (int i = 0; i < line.size(); i++) {
        TextPosition pos = line.get(i);
        LOG.debug("pos " + pos);
        if (pos != null) {
          String text = pos.getCharacter();
          LOG.debug("text " + text);
          // Build the line: Add whitespaces at the correct positions
          if (pos instanceof WordSeparator) {
            lineBuilder.append(getWordSeparator());
            fulltext.append(getWordSeparator());
          } else {
            text = normalize.normalizePres(text);
            lineBuilder.append(text);
            fulltext.append(text);
          }

          if (text != null) {
            LOG.debug("text != null");
            LOG.debug(pos.getDir());
            // Don't consider lines, which are rotated.
            // if (pos.getDir() != 0) { return null; }

            // Calculate the x-value and the y-value for the line.
            if (pos.getX() < lineX) {
              lineX = pos.getX();
              lineY = pos.getY();
              lineYLowerLeft = pos.getTextPos().getValue(2, 1);
            }

            LOG.debug(pos + " " + pos.getX() + " " + pos.getY() + " "
                + pos.getHeight());

            if (charPattern.matcher(text).matches()) {
              // Calculate the fontsize
              int fontsize = Math.round(pos.getFontSizeInPt());
              if (fontsizes.containsKey(fontsize)) {
                fontsizes.put(fontsize, fontsizes.get(fontsize) + 1);
              } else {
                fontsizes.put(fontsize, 1);
              }

              // Calculate the height of the line = the height of the heighest
              // TextPosition)
              if (pos.getHeight() > lineHeight) lineHeight = pos.getHeight();

              // Calculate the font and put it into fontmap (to compute the most
              // common font).
              PDFont font = pos.getFont();
             
              if (fontmap.containsKey(font)) {
                fontmap.put(font, new Integer(fontmap.get(font) + 1));
              } else {
                fontmap.put(font, new Integer(1));
              }

              // Count the number of uppercased characters as well as the number
              // of lowercased words.
              for (char ch : text.toCharArray()) {
                if (Character.isLetter(ch)) {
                  if (Character.isUpperCase(ch)) {
                    numOfUpperCases++;
                  } else {
//                    numOfLowerCases++;
                  }
                  numOfChars++;
                }
              }
            }
          }
        }
      }

      // If the line ends with "-", delete "-" and append the nextLine without
      // an wordSeparator.
      if (lineBuilder.length() > 0) {
        char lastChar = lineBuilder.charAt(lineBuilder.length() - 1);

        if (lastChar == '-') {
          lineBuilder.deleteCharAt(lineBuilder.length() - 1);
        } else {
          // Separate line with a line separator.
          lineBuilder.append(getLineSeparator());
        }
      }

      // Compute the most common font.
      int occMostCommonFont = 0;
      PDFont mostCommonFont = null;
      for (Entry<PDFont, Integer> entry : fontmap.entrySet()) {
        if (entry.getValue() > occMostCommonFont) {
          occMostCommonFont = entry.getValue();
          mostCommonFont = entry.getKey();
        }
      }

      // Compute the x-value of the line end.
      float lineEndX = 0;

      // Collections.sort(line, new HorizontalTextPositionComparator());

      if (!line.isEmpty()) {
        // // Find the first non-whitespace in line.
        // int i = 0;
        // TextPosition firstPos = null;
        // while ((firstPos == null || firstPos.getCharacter() == null ||
        // firstPos
        // .getCharacter().matches("\\s+")) && i < line.size()) {
        // firstPos = line.get(i);
        // i++;
        // }
        //
        // if (firstPos != null && firstPos.getCharacter() != null) {
        // lineX = firstPos.getX();
        // lineY = firstPos.getY();
        // }

        int i = line.size() - 1;
        TextPosition lastPos = null;
        // Find the last, non-whitespace in line.
        while ((lastPos == null || lastPos.getCharacter() == null || lastPos
            .getCharacter().matches("\\s+")) && i >= 0) {
          lastPos = line.get(i);
          i--;
        }

        if (lastPos != null && lastPos.getCharacter() != null) {
          lineEndX = lastPos.getX() + lastPos.getWidth();
          lineWidth = lineEndX - lineX;
        }
      }

      // Compute the fontFlag for the line.
      if (mostCommonFont != null) {
        fontname = mostCommonFont.getBaseFont();
        if (fontname != null) {
          fontname = fontname.toLowerCase();

          if (fontname.indexOf("italic") > -1) fontFlag += 1;
          if (fontname.indexOf("bold") > -1) fontFlag += 2;
        }
      }

      // Compute most common fontsize
      int mostCommontFontsize = 0;
      int mostCommontFontsizeNum = 0;
      // Iterate over the stats to determine the most common fontsize.
      for (Entry<Integer, Integer> stat : fontsizes.entrySet()) {
        // Don't consider the fontsize 0.
        if (stat.getKey() > 0 && stat.getValue() > mostCommontFontsizeNum) {
          mostCommontFontsizeNum = stat.getValue();
          mostCommontFontsize = stat.getKey();
        }
      }

      // Create the object for the line.
      Region region = new Region(lineX, lineY, lineWidth, lineHeight);
      region.setYLowerLeft(lineYLowerLeft);
      region.setXOfLineEnd(lineEndX);
      region.setFontsize(mostCommontFontsize);
      region.setPageNumber(pageNumber);
      region.setText(lineBuilder.toString());
      region.setFont(mostCommonFont);
//      region.setIsInUpperCases(numOfUpperCases > numOfLowerCases ? true
//          : false);
      region.setIsInUpperCases(numOfChars > 0 && numOfUpperCases == numOfChars);
      region.setFontFlag(fontFlag);
      region.setTextPositions(line);
      
      return region;
    }
    return null;
  }

  /**
   * Merges two lines. To get a reasonable result, nextLine must be succeed the
   * line logically.
   * 
   * @param line
   *          the first line
   * @param nextLine
   *          the second line
   * @return the merged line.
   */
  private Region merge(Region line, Region nextLine) {
    if (line != null && nextLine != null) {
      // Combine both texts.
      StringBuilder sb = new StringBuilder();
      sb.append(line.getText());
      sb.append(nextLine.getText());
      line.setText(sb.toString());
      // Adjust xOfLineEnd.
      line.setX(Math.min(line.getX(), nextLine.getX()));
      line.setXOfLineEnd(Math.max(line.getXOfLineEnd(),
          nextLine.getXOfLineEnd()));
      line.setWidth(line.getXOfLineEnd() - line.getX());
      line.setIsMeaningful(isMeaningful(line)); // FIXME
    }
    return line;
  }

  /**
   * Returns true, if the given line is meaningful.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the line is meaningful.
   */
  protected boolean isMeaningful(Region line) {
    if (line != null) {
      if (line.getPageNumber() == 1) { return true; }

      String text = line.getText();

      if (isBibliographyHeader(text)) { return true; }
      // if (startsWithReferenceAnchor(line)) { return true; }

      if (text != null) {
        text = text.trim();
        // TODO: Parameterize.
        // 35 is the maximum. Don't decrease the value.
        if (text.length() < 35) { return false; }

        int numOfLetters = 0;
        int numOfDigits = 0;

        for (int i = 0; i < text.length(); i++) {
          char ch = line.getText().charAt(i);
          if (Character.isLetter(ch)) {
            numOfLetters++;
          } else if (Character.isDigit(ch)) {
            numOfDigits++;
          }
        }

        return numOfLetters > numOfDigits;
      }
    }
    return false;
  }

  /**
   * Returns true, if the given group of lines should be considered on the
   * extraction of lines.
   * 
   * @param group
   *          the group of lines.
   * @return true, if the group should be considered, otherwise false.
   */
  protected boolean consider(List<Region> group) {
    if (group != null) {
      // If the group only contains one line consider it only if it is the
      // bibliography header.
      if (group.size() == 1) {
        Region line = group.get(0);
        if (line != null) {
          if (line.getPageNumber() == 1) { return true; }

          String text = line.getText();
          if (text != null) {
            // Delete all whitespace to find headers like "REF E RE N C E S  "
            // Move replaceAll to isBibliographyHeader
            text = text.replaceAll("\\s", "");
            return startsWithReferenceAnchor(line)
                || isBibliographyHeader(text);
          }
        }
      }

      int numOfMeaningfulLines = 0;
      for (Region line : group) {
        if (line != null) {
          if (line.getPageNumber() == 1) { return true; }
          // Return false, if the group contains a caption.
          if (isCaption(line.getText())) { return false; }
          // Return true, if the group contains the bibliography header.
          if (isBibliographyHeader(line.getText())) { return true; }
          // Count the number of meaningful lines in the group.
          if (line != null && line.isMeaningful()) {
            numOfMeaningfulLines++;
          }
        }
      }
      // Return true, if the group contains at least one meaningful line.
      // return numOfMeaningfulLines > 0; // isn't sufficient for 00885788.pdf
      // The majority of lines must be meaningful.
      return numOfMeaningfulLines >= 0.5 * group.size();
    }
    return false;
  }

  /**
   * Returns true, if the given text is a caption.
   * 
   * @param text
   *          the text to analyze.
   * @return true, if the text is a caption, false otherwise.
   */
  protected boolean isCaption(String text) {
    if (text != null) {
      Matcher m = CAPTION_PATTERN.matcher(text);
      return m.find();
    }
    return false;
  }

  /**
   * Returns true, if the given text is the bibliography header.
   * 
   * @param text
   *          the text to analyze.
   * @return true, if the text is the bibliography header, false otherwise.
   */
  protected boolean isBibliographyHeader(String text) {
    if (text != null) {
      Matcher m = BIB_HEADER_PATTERN.matcher(text);
      return m.find();
    }
    return false;
  }

  /**
   * Returns the lines of the pdf-file.
   * 
   * @return the lines of the pdf-file.
   * @throws IOException
   *           if the extraction of lines fails.
   */
  public List<Region> getLines() throws IOException {
    getText(document);
    return lines;
  }

  /**
   * Returns the fulltext of the pdf file as a string. The fulltext is only
   * available after calling getLines().
   * 
   * @return the fulltext of the pdf file.
   */
  public String getFulltext() {
    return fulltext.toString();
  }

  /**
   * Returns the line separator.
   */
  public String getLineSeparator() {
    return " ";
  }

  /**
   * Compares the horizontal position of two given lines. Returns -1, if line1
   * comes before line2 (with respect to the horizontal position); 1 if line2
   * comes before line1 and 0 if the horizontal positions of both lines are
   * equal.
   * 
   * @param line1
   *          the first line to analyze.
   * @param line2
   *          the second line to analyze.
   * @param useLineEnds
   *          if true, xOfLineEnd of both lines is used for comparison,
   *          otherwise x is used.
   * @return -1, if line1 comes before line2 (with respect to the horizontal
   *         position); 1 if line2 comes before line1 and 0 if the horizontal
   *         positions of both lines are equal.
   */
  // TODO: Move to a separate class.
  protected int compareX(Region line1, Region line2, boolean useLineEnds) {
    if (line1 == line2) { return 0; }
    // TODO: Decide, what to do if one of the line == null.
    if (line1 == null) { return 0; }
    if (line2 == null) { return 0; }

    // If compareLineEnds == true, reflect the line: (x=10,y=30) -> (x=30,y=50)
    float x1 = useLineEnds ? -1 * line2.getXOfLineEnd() : line1.getX();
    // y is the x-coordinate of the line end.
    float y1 = useLineEnds ? -1 * line2.getX() : line1.getXOfLineEnd();

    // If compareLineEnds == true, reflect the line: (x=10,y=30) -> (x=30,y=50)
    float x2 = useLineEnds ? -1 * line1.getXOfLineEnd() : line2.getX();
    // y is the x-coordinate of the line end.
    float y2 = useLineEnds ? -1 * line1.getX() : line2.getXOfLineEnd();

    // The tolerance that (x2 - x1) must exceed so that the line is identified
    // as advanced to nextLine (~ 2 * width of chars).
    float tolerance = Math.abs(x1 - y1) / line1.getText().length();
    // x2 must be in range [x1 + tolerance, x1 + line.getWidth]. The upper
    // bound is introduced to ignore comparisons between lines of different
    // columns.
    float delta = Math.abs(x1 - x2);

    if (delta <= tolerance) {
      return 0;
    } else if (x2 > x1) {
      if (x2 > y1) { return -2; }
      return -1;
    } else if (x1 > x2) {
      if (x1 > y2) { return 2; }
      return 1;
    }
    return 0;
  }

  /**
   * Compares the vertical position of two given lines. Returns -1, if line1
   * comes before line2 (with respect to the vertical position); 1 if line2
   * comes before line1 and 0 if the horizontal positions of both lines are
   * equal.
   * 
   * @param line1
   *          the first line to analyze.
   * @param line2
   *          the second line to analyze.
   * @return -1, if line1 comes before line2 (with respect to the vertical
   *         position); 1 if line2 comes before line1 and 0 if the vertical
   *         positions of both lines are equal.
   */
  // TODO: Move to a separate class.
  public int compareY(Region line1, Region line2) {
    if (line1 == line2) { return 0; }
    // TODO: Decide, what to do if one of the line == null.
    if (line1 == null) { return 1; }
    if (line2 == null) { return -1; }

    float x1 = line1.getY() - line1.getHeight();
    float y1 = line1.getY();

    float x2 = line2.getY() - line2.getHeight();
    float y2 = line2.getY();

    float tolerance = 2 * line1.getHeight();
    float delta = Math.abs(x2 - y1);

    // Check, if line1 and line2 overlap vertically. Allow a minimal tolerance
    // of 0.5 to keep lines like "3^(rd)" in one line.
    if ((x2 >= (x1 - 0.5) && x2 <= (y1 + 0.5))
        || (y2 >= (x1 - 0.5) && y2 <= (y1 + 0.5))) {
      return 0;
    } else {
      if (delta <= tolerance) {
        if (y1 < y2) { return -1; }
        if (y1 > y2) { return 1; }
        return 0;
      } else {
        if (y1 < y2) { return -2; }
        if (y1 > y2) { return 2; }
        return 0;
      }
    }
  }

  /**
   * Returns true, if the given line contains a reference anchor.
   * 
   * @param line
   *          the line to analyze.
   * @return true, if the given line contains a reference anchor.
   */
  // TODO: Move to a separate class.
  protected boolean startsWithReferenceAnchor(Region line) {
    if (line != null) {
      String text = line.getText();
      if (text != null) {
        // Remove all whitespaces, to meet anchors like "[ 1 ]" (instead of
        // "[1]").
        text = text.replaceAll("\\s", "");

        Matcher m = REFERENCE_ANCHOR_PATTERN.matcher(text);
        return m.find() && m.group(2).length() > 3;
      }
    }
    return false;
  }

  /**
   * Sets the flaf splitLines.
   * 
   * @param splitLines
   *          true, if lines should be checked if they have to be splitted.
   */
  public void setSplitLine(boolean splitLines) {
    this.splitLines = splitLines;
  }
}

/**
 * A comparator, that compares Regions by their y-values.
 * 
 * @author Claudius Korzen
 * 
 */
// MAYBE: Move to a separate class.
class VerticalRegionComparator3 implements Comparator<Region> {
  @Override
  public int compare(Region o1, Region o2) {
    if (o1 == o2) { return 0; }
    if (o1 == null) { return 1; }
    if (o2 == null) { return -1; }

    // If both y-values are equal, sort by the x-values.
    if (o1.getY() == o2.getY()) { return Float.compare(o1.getX(), o2.getX()); }
    return Float.compare(o1.getY(), o2.getY());
  }
}

/**
 * A comparator, that compares Regions by their x-values.
 * 
 * @author Claudius Korzen
 * 
 */
// MAYBE: Move to a separate class.
class HorizontalTextPositionComparator3 implements Comparator<TextPosition> {
  @Override
  public int compare(TextPosition o1, TextPosition o2) {
    if (o1 == o2) { return 0; }
    if (o1 == null) { return 1; }
    if (o2 == null) { return -1; }
    // if (o1.getCharacter() == o2.getCharacter()) { return 0; }
    // if (o1.getCharacter() == null) { return 1; }
    // if (o2.getCharacter() == null) { return -1; }

    // If both x-values are equal, sort by the y-values.
    if (o1.getX() == o2.getX()) { return Float.compare(o1.getY(), o2.getY()); }
    return Float.compare(o1.getX(), o2.getX());
  }
}

/**
 * A comparator, that compares the isMeaningful-property of lines.
 * 
 * @author Claudius Korzen
 * 
 */
// MAYBE: Move to a separate class.
class MeaningfulComparator implements Comparator<Region> {
  @Override
  public int compare(Region o1, Region o2) {
    if (o1 == o2) { return 0; }
    if (o1 == null) { return 1; }
    if (o2 == null) { return -1; }
    if (o1.isMeaningful() == o2.isMeaningful()) { return 0; }
    if (o1.isMeaningful()) { return -1; }
    if (o2.isMeaningful()) { return 1; }
    return 0;
  }
}

/**
 * A comparator, that compares columns by the x-value of their first lines.
 * 
 * @author Claudius Korzen
 * 
 */
// MAYBE: Move to a separate class.
class ColumnsComparator implements Comparator<List<Region>> {
  @Override
  public int compare(List<Region> o1, List<Region> o2) {
    if (o1 == o2) { return 0; }
    if (o1 == null) { return 1; }
    if (o2 == null) { return -1; }
    if (o1.isEmpty() && o2.isEmpty()) { return 0; }
    if (o1.isEmpty()) { return 1; }
    if (o2.isEmpty()) { return -1; }

    Region firstLine1 = o1.get(0);
    Region firstLine2 = o2.get(0);

    if (firstLine1 == firstLine2) { return 0; }
    if (firstLine1 == null) { return 1; }
    if (firstLine2 == null) { return -1; }

    if (firstLine1.getX() > firstLine2.getX()) { return 1; }
    if (firstLine1.getX() < firstLine2.getX()) { return -1; }

    return 0;
  }
}
