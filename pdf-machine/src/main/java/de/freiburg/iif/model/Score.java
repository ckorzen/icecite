package de.freiburg.iif.model;

/**
 * The class Score, represeting the score of a metadata knowledge record.
 * 
 * @author Claudius Korzen
 * 
 */
public class Score {
  /** The score for evaluating the title. */
  public float titleScore;
  /** The score for evaluating the authors. */
  public float authorScore;
  /** The score for evaluating the year. */
  public float yearScore;
  /** The score for evaluating the journal. */
  public float journalScore;
  /** The score for evaluating the page. */
  public float pageScore;

  /**
   * 
   * @param titleScore the title score
   * @param authorScore the author score
   * @param yearScore the year score
   * @param journalScore the journal score
   * @param pageScore the page score
   */
  public Score(float titleScore, float authorScore, float yearScore,
      float journalScore, float pageScore) {
    this.titleScore = titleScore;
    this.authorScore = authorScore;
    this.yearScore = yearScore;
    this.journalScore = journalScore;
    this.pageScore = pageScore;
  }
}