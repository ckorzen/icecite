package de.freiburg.iif.model;

import org.apache.pdfbox.util.TextPosition;

/**
 * wrapper of TextPosition that adds flags to track status as linestart and
 * paragraph start positions.
 * <p>
 * This is implemented as a wrapper since the TextPosition class doesn't provide
 * complete access to its state fields to subclasses. Also, conceptually
 * TextPosition is immutable while these flags need to be set post-creation so
 * it makes sense to put these flags in this separate class.
 * </p>
 * 
 * @author m.martinez@ll.mit.edu
 * 
 */
public class PositionWrapper {
  /** Flag to decide, if TextPosition is the first TextPosition in the line */
  private boolean isLineStart = false;
  /** Flag to decide, if TextPosition is the first TextPosition in paragraph */
  private boolean isParagraphStart = false;
  /** Flag to decide, if TextPosition is the first TextPosition on the page */
  private boolean isPageBreak = false;
  /** Flag to decide, if TextPosition is a hanging indent */
  private boolean isHangingIndent = false;
  /** Flag to decide, if TextPosition is first Textposition in the article */
  private boolean isArticleStart = false;
  /** The text position to wrap */
  private TextPosition position = null;

  /**
   * returns the underlying TextPosition object
   * 
   * @return text position
   */
  public TextPosition getTextPosition() {
    return position;
  }

  /**
   * 
   * @return is line start.
   */
  public boolean isLineStart() {
    return isLineStart;
  }

  /**
   * sets the isLineStart() flag to true
   */
  public void setLineStart() {
    this.isLineStart = true;
  }

  /**
   * 
   * @return is paragraph start.
   */
  public boolean isParagraphStart() {
    return isParagraphStart;
  }

  /**
   * sets the isParagraphStart() flag to true.
   */
  public void setParagraphStart() {
    this.isParagraphStart = true;
  }

  /**
   * 
   * @return is article start.
   */
  public boolean isArticleStart() {
    return isArticleStart;
  }

  /**
   * sets the isArticleStart() flag to true.
   */
  public void setArticleStart() {
    this.isArticleStart = true;
  }

  /**
   * 
   * @return is page break.
   */
  public boolean isPageBreak() {
    return isPageBreak;
  }

  /**
   * sets the isPageBreak() flag to true
   */
  public void setPageBreak() {
    this.isPageBreak = true;
  }

  /**
   * 
   * @return is hanging indent.
   */
  public boolean isHangingIndent() {
    return isHangingIndent;
  }

  /**
   * sets the isHangingIndent() flag to true
   */
  public void setHangingIndent() {
    this.isHangingIndent = true;
  }

  /**
   * constructs a PositionWrapper around the specified TextPosition object.
   * 
   * @param position the text position
   */
  public PositionWrapper(TextPosition position) {
    this.position = position;
  }

}
