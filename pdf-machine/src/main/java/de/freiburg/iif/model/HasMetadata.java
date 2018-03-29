package de.freiburg.iif.model;

import java.util.List;

/**
 * The interface HasMetadata.
 * 
 * @author Claudius Korzen
 * 
 */
public interface HasMetadata {
  /**
   * Returns the score of the metadata knowledge base record
   * 
   * @return the score.
   */
  public double getScore();

  /**
   * Changes the score of the metadata knowledge base record
   * 
   * @param score
   *          the new score.
   */
  public void setScore(double score);

  /**
   * Returns the extracted raw string for this metadata record.
   * 
   * @return the extracted raw string for this metadata record.
   */
  public String getRaw();

  /**
   * Sets the extracted raw string for this metadata record.
   * 
   * @param raw
   *          the raw string to set.
   */
  public void setRaw(String raw);

  /**
   * Returns the extracted abstract for this metadata record.
   * 
   * @return the extracted abstract.
   */
  public String getAbstract();

  /**
   * Sets the extracted abstract for this metadata record.
   * 
   * @param abstractText
   *          the abstract to set.
   */
  public void setAbstract(String abstractText);

  /**
   * Returns an unique identifier of the metadata knowledge base record
   * 
   * @return the unique identifier.
   */
  public String getKey();

  /**
   * Returns the title of the metadata knowledge base record
   * 
   * @return the title.
   */
  public String getTitle();

  /**
   * Returns the authors of the metadata knowledge base record
   * 
   * @return the authors.
   */
  public List<String> getAuthors();

  /**
   * Returns the year of the metadata knowledge base record
   * 
   * @return the year.
   */
  public int getYear();

  /**
   * Returns the journal of the metadata knowledge base record
   * 
   * @return the journal.
   */
  public String getJournal();

  /**
   * Sets the journal of the metadata knowledge base record
   * 
   * @param journal
   *          the journal.
   */
  public void setJournal(String journal);

  /**
   * Returns the start page of this metadata record.
   * 
   * @return the start page of this metadata record.
   */
  public int getStartPage();

  /**
   * Returns the end page of this metadata record.
   * 
   * @return the end page of this metadata record.
   */
  public int getEndPage();
  
  /**
   * Returns the url of this metadata record.
   * 
   * @return the url of this metadata record.
   */
  public String getUrl();
  
  /**
   * Returns the ee of this metadata record.
   * 
   * @return the ee of this metadata record.
   */
  public String getEe();
  
  /**
   * Returns the list of coordinates of each line of this record. Each list entry
   * is a array of length 5: [pageNumber, lowerLeftX, lowerLeftY, upperRightX, 
   * upperRightY];
   * 
   * @return the x position of this metadata record in the pdf.
   */
  public List<Object[]> getLineCoordinates();
  
  /**
   * Sets the list of coordinates of each line of this record. Each list entry
   * is a array of length 5: [pageNumber, lowerLeftX, lowerLeftY, upperRightX, 
   * upperRightY];
   * 
   * @param coordinates the coordinates.
   */
  public void setLineCoordinates(List<Object[]> coordinates);
  
  /**
   * Returns the metadata record as json.
   * 
   * Returns the metadata record as json.
   */
  public String toJson();
}
