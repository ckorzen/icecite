package de.freiburg.iif.model;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.util.TextPosition;

import de.freiburg.iif.extraction.references.ReferencesMetadataMatcher.ReferenceLineType;

// FIXME: Refactor it.
public class Region implements Comparable<Region> {
  protected float x;
  protected float y;
  protected float yLowerLeft;
  protected float width;
  protected float height;
  protected float fontsize;
  protected String text;
  protected int pageNumber, columnNumber;
  protected float decorationScore;
  protected boolean isFirstLineInBib = false;
  protected boolean isIndented = false;
  protected boolean isInUppercase = false;
  protected int fontFlag = 0;
  protected float dir;
  protected String dblpMatching;
  protected PDFont font;
  protected float numOfUpperCases = 0;
  protected float xOfLineEnd;
  protected Log LOG = LogFactory.getLog(Region.class);
  protected List<Region> includedLines;
  protected ReferenceLineType type;
  protected boolean isMeaningful;
  protected boolean isPending = true;
  protected int index;
  protected List<TextPosition> textPositions;
  
  public Region() {
    this.x = -1;

    this.includedLines = new ArrayList<Region>();
    this.includedLines.add(this);
  }

  public Region(float x, float y, float width, float height) {
    this();

    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  public Region(float x, float y, float width, float height, float fontsize,
      int pageNumber, int columnNumber, String text) {
    this();

    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.pageNumber = pageNumber;
    this.columnNumber = columnNumber;
    this.fontsize = fontsize;
  }

  @Override
  public String toString() {
    return String
        .format(
            "Region[x:%f, y:%f, w:%f, h:%f, X:%f, fs:%f, fn: %s, p:%d, c:%d,  ds:%f, iuc:%b, ff:%d, \"%s\" :]",
            x, y, width, height, xOfLineEnd, fontsize,
            font != null ? font.getBaseFont() : null, pageNumber,
            columnNumber, decorationScore, isInUppercase, fontFlag, text);

  }

  public void setX(float x) {
    this.x = x;
  }

  public void setY(float y) {
    this.y = y;
  }

  public void setYLowerLeft(float yLowerLeft) {
    this.yLowerLeft = yLowerLeft;
  }
  
  public void setWidth(float width) {
    this.width = width;
  }

  public void setHeight(float height) {
    this.height = height;
  }

  public void setPageNumber(int pageNumber) {
    this.pageNumber = pageNumber;
  }

  public int getPageNumber() {
    return pageNumber;
  }

  public float getX() {
    return x;
  }

  public float getY() {
    return y;
  }

  public float getYLowerLeft() {
    return yLowerLeft;
  }
  
  public float getWidth() {
    return width;
  }

  public float getHeight() {
    return height;
  }

  public void setText(String text) {
    this.text = text;
  }

  public String getText() {
    return text;
  }

  public int getColumnNumber() {
    return columnNumber;
  }

  public void setColumnNumber(int columnNumber) {
    this.columnNumber = columnNumber;
  }

  public boolean isMemberOf(Region... regions) {
    for (Region region : regions) {
      LOG.debug("Determining, if region [" + getX() + "," + getY() + " : "
          + getWidth() + "," + getHeight() + "] is Member of ["
          + region.getX() + "," + region.getY() + " : " + region.getWidth()
          + "," + region.getHeight() + "]");
      if (region != null) {
        float x = region.getX();
        float y = region.getY();
        // float height = region.getHeight();
        // float x2 = region.getX() + region.getWidth();
        float width = region.getWidth();
        float height = region.getHeight();

        if ((compare(this.y, y, 5f) != 1)
            && (compare(this.y, y + height, 5f) != -1)
            && (compare(this.x, x, 5f) != 1)
            && (compare(this.x, x + width, 5f) != -1)) {
          LOG.debug("Determining Membership of region finished: is member.");
          return true;
        }

        // if (this.x >= x1 && this.y >= y1 &&
        // (this.x + this.width <= x2) &&
        // (this.y + this.height <= y2)) {
        // return true;
        // }
      }
    }
    LOG.debug("Determining Membership of region finished: isn't member.");
    return false;
  }

  public void expand(Region expandingRegion) {
//    includedLines.addAll(expandingRegion.getIncludedLines());

    LOG.debug("Expanding " + this + " with " + expandingRegion);
    setX(Math.min(getX(), expandingRegion.getX()));
    setY(Math.min(getY(), expandingRegion.getY()));

    float upperBorder =
        Math.max(getY() + getHeight(), expandingRegion.getY()
            + expandingRegion.getHeight());

    setHeight(upperBorder - getY());
    setWidth(Math.max(getWidth(), expandingRegion.getWidth()));

    StringBuilder sb = new StringBuilder();
    sb.append(getText());
    sb.append(expandingRegion.getText());
    setText(sb.toString());
    
    setIndex(Math.max(getIndex(), expandingRegion.getIndex()));
    
    // StringBuilder sb = new StringBuilder();
    // for (Region line : includedLines) {
    // sb.append(line.getText());
    // }
    // setText(sb.toString());
    // appendText(expandingRegion.getText());

    // setFontsize((getFontsize() + expandingRegion.getFontsize()) / 2.0f);
    setFontsize(Math.max(getFontsize(), expandingRegion.getFontsize()));

    numOfUpperCases += expandingRegion.getNumOfUpperCases();
    LOG.debug("Expanding finished. Resulting region: " + this);

  }

  public List<Region> getIncludedLines() {
    return includedLines;
  }

  public boolean isFirstLineInBib() {
    return isFirstLineInBib;
  }

  public void setIsFirstLineInBib(boolean isFirstLineInBib) {
    this.isFirstLineInBib = isFirstLineInBib;
  }

  public float getFontsize() {
    return fontsize;
  }

  public void setFontsize(float fontsize) {
    this.fontsize = fontsize;
  }

  /**
   * This will determine of two floating point numbers are within a specified
   * variance.
   * 
   * @param first
   *          The first number to compare to.
   * @param second
   *          The second number to compare to.
   * @param variance
   *          The allowed variance.
   */
  public static int compare(float first, float second, float variance) {
    if (second > first + variance) return 1;
    if (second < first - variance) return -1;
    return 0;
  }

  @Override
  public int compareTo(Region reg2) {
    Region reg1 = this;

    /* Only compare text that is in the same direction. */
    if (reg1.getPageNumber() < reg2.getPageNumber()) {
      return -1;
    } else if (reg1.getPageNumber() > reg2.getPageNumber()) {
      return 1;
    } else if (compare(reg1.getX(), reg2.getX(), reg1.getWidth()) == -1) {
      return 1;
    } else if (compare(reg1.getX(), reg2.getX(), reg1.getWidth()) == 1) { return -1; }

    if (compare(reg1.getY(), reg2.getY(), 5f) == -1) {
      return 1;
    } else if (compare(reg1.getY(), reg2.getY(), 5f) == -1) { return -1; }

    return 0;
    // // Get the text direction adjusted coordinates
    // float y1 = reg1.getY();
    // float y2 = reg2.getY();
    //
    // if (y1 > y2) {
    // return 1;
    // } else if (y1 < y2) {
    // return -1;
    // }
    // return 0;
  }

  public boolean isIndented() {
    return isIndented;
  }

  public void setIsIndented(boolean isIndented) {
    this.isIndented = isIndented;
  }

  public float getDir() {
    return dir;
  }

  public void setDir(float dir) {
    this.dir = dir;
  }

  public void setDblpMatching(String dblpMatching) {
    this.dblpMatching = dblpMatching;
  }

  public String getDblpMatching() {
    return dblpMatching;
  }

  public void setDecorationScore(float score) {
    decorationScore = score;
  }

  public float getDecorationScore() {
    return decorationScore;
  }

  public PDFont getFont() {
    return font;
  }

  public void setFont(PDFont font) {
    this.font = font;
  }

  public boolean isInUpperCase() {
    return isInUppercase;
  }

  public void setIsInUpperCases(boolean isInUppercase) {
    this.isInUppercase = isInUppercase;
  }

  public void setNumOfUpperCases(float numOfUpperCases) {
    this.numOfUpperCases = numOfUpperCases;
  }

  public float getNumOfUpperCases() {
    return numOfUpperCases;
  }

  public float getXOfLineEnd() {
    return xOfLineEnd;
  }

  public void setXOfLineEnd(float xOfLineEnd) {
    this.xOfLineEnd = xOfLineEnd;
  }

  public int getFontFlag() {
    return fontFlag;
  }

  public void setFontFlag(int fontFlag) {
    this.fontFlag = fontFlag;
  }

  public boolean equalsFontStyle(Object o) {
    if (o instanceof Region) {
      Region r = (Region) o;
      if (font != null && r.font != null) {
        // Compare baseFonts (and not only "fonts"), because there are different
        // font-objects with the same basefont.
        String baseFont1 = font.getBaseFont();
        String baseFont2 = r.font.getBaseFont();
        if (baseFont1 != null) {
          boolean equals = baseFont1.equals(baseFont2);
          if (equals) {
            if (r.fontsize - 1.0 <= fontsize && r.fontsize + 1.0 >= fontsize) { return (fontFlag == r.fontFlag); }
          }
        }
      }
    }
    return false;
  }

  public
    void
    setType(
      de.freiburg.iif.extraction.references.ReferencesMetadataMatcher.ReferenceLineType type) {
    this.type = type;
  }

  public ReferenceLineType getType() {
    return type;
  }

  public boolean isMeaningful() {
    return isMeaningful;
  }

  public void setIsMeaningful(boolean isMeaningful) {
    this.isMeaningful = isMeaningful;
  }

  public boolean isPending() {
    return isPending;
  }

  public void setIsPending(boolean isPending) {
    this.isPending = isPending;
  }
  
  public int getIndex() {
    return index;
  }

  public void setIndex(int index) {
    this.index = index;
  }
  
  public void setTextPositions(List<TextPosition> textPositions) {
    this.textPositions = textPositions;
  }
  
  public List<TextPosition> getTextPositions() {
    return textPositions;
  }
}