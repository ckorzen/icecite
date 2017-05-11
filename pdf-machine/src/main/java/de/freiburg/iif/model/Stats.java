package de.freiburg.iif.model;
/**
   * Class stats, that holds the most common fontsize and the most common pitch
   * size of lines.
   * 
   * @author Claudius Korzen.
   * 
   */
  public class Stats {
    /** The most common font size */
    public double mostCommonFontSize;
    /** The most common pitch size */
    public double mostCommontPitchSize;
    /** The number of reference anchors (for references extraction only). */
    public int numOfReferenceAnchors;
    /**
     * The number of advanced reference headers (for references extraction
     * only).
     */
    public int numOfAdvancedReferenceHeader;

    /**
     * The constructor.
     * 
     * @param mostCommonFontsize
     *          the most common fontsize
     * @param mostCommonPitchSize
     *          the most common pitch size.
     */
    public Stats(double mostCommonFontsize, double mostCommonPitchSize) {
      this.mostCommonFontSize = mostCommonFontsize;
      this.mostCommontPitchSize = mostCommonPitchSize;
    }
  }