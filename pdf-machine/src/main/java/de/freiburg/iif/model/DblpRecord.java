package de.freiburg.iif.model;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import com.cedarsoftware.util.io.JsonReader;


/**
 * The class DblpRecord that represents an record of the digital library DBLP.
 * 
 * @author Claudius Korzen
 * 
 */
public class DblpRecord implements HasMetadata {
  /** The score of the record. */
  private double score;
  /** The key of the record */
  private String key;
  /** The title of the record */
  private String title;
  /** The authors of the record */
  private List<String> authors;
  /** The year of the record */
  private int year;
  /** The journal of the record */
  private String journal;
  /** The extracted string */
  private String raw;
  /** The start page */
  private int startPage = -1;
  /** The end page */
  private int endPage = -1;
  /** The abstract */
  private String abstractText;
  /** The url */
  private String url;
  /** The ee */
  private String ee;
  /** The coordinates of line. */
  private List<Object[]> lineCoordinates;
  /** The json parser */
  private JsonReader jsonReader;
  
  /**
   * Constructor of DblpRecord.
   */
  public DblpRecord() {
    this.authors = new ArrayList<String>();
  }
  
  /**
   * Constructs a DblpRecord from JSON.
   * 
   * @param json json as InputStream
   */
  @SuppressWarnings("rawtypes")
  public DblpRecord(InputStream json)  {
    this();
    
    try {
      jsonReader = new JsonReader(json);
      Map map = (Map) jsonReader.readObject();
      // Parse the external key.
      key = (String) map.get("externalKey");
      // Parse the title.
      title = (String) map.get("title");
      // Parse the authors.
      Object rawAuthors = map.get("authors");
      if (rawAuthors instanceof String[]) {
        String[] rawAuthorsArray = (String[]) rawAuthors;
        this.authors = Arrays.asList(rawAuthorsArray);
      } else if (raw instanceof String) {
        String rawAuthorsString = (String) rawAuthors;
        List<String> authors = new ArrayList<String>();
        authors.add(rawAuthorsString);
        this.authors = authors;
      }
      // Parse the year.
      String year = (String) map.get("year");
      if (year != null) this.year = Integer.parseInt(year);
      // Parse the journal.
      journal = (String) map.get("journal");
      // Parse the url.
      url = (String) map.get("url");
      // Parse the ee.
      ee = (String) map.get("ee");
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  
  @Override
  public double getScore() {
    return score;
  }
  
  @Override
  public String getKey() {
    return key;
  }
  
  @Override
  public String getTitle() {
    return title;
  }
  
  @Override
  public List<String> getAuthors() {
    return authors;
  }
  
  @Override
  public int getYear() {
    return year;
  }
  
  @Override
  public String getJournal() {
    return journal;
  }
  
  @Override
  public String getRaw() {
    return raw;
  }

  @Override
  public void setRaw(String raw) {
    this.raw = raw;
  }
  
  @Override
  public int getStartPage() {
    return startPage;
  }

  @Override
  public int getEndPage() {
    return endPage;
  }
  
  @Override
  public List<Object[]> getLineCoordinates() {
    return lineCoordinates;
  }
  
  @Override
  public void setLineCoordinates(List<Object[]> lineCoordinates) {
    this.lineCoordinates = lineCoordinates;
  }
  
  /**
   * Sets the score.
   * 
   * @param score the score
   */
  public void setScore(double score) {
    this.score = score;
  }

  /**
   * Sets the key.
   * 
   * @param key the key
   */
  public void setKey(String key) {
    this.key = key;
  }

  /**
   * Sets the title.
   * 
   * @param title the title
   */
  public void setTitle(String title) {
    this.title = title;
  }

  /**
   * Sets the authors.
   * 
   * @param authors the authors
   */
  public void setAuthors(List<String> authors) {
    this.authors = authors;
  }
  
  /**
   * Sets the year.
   * 
   * @param year the year.
   */
  public void setYear(int year) {
    this.year = year;
  }
  
  /**
   * Sets the journal.
   * 
   * @param journal the journal.
   */
  public void setJournal(String journal) {
    this.journal = journal;
  }
  
  /**
   * Sets the start page
   * 
   * @param startPage the start page.
   */
  public void setStartPage(int startPage) {
    this.startPage = startPage;
  }

  /**
   * Sets the end page
   * 
   * @param endPage the end page.
   */
  public void setEndPage(int endPage) {
    this.endPage = endPage;
  }
    
  @Override
  public String toString() {
    return title + "\t" + authors + "\t" + year + "\t" + journal + "\t" + abstractText;
//    return "[" + key + "] \"" + title + "\" " + Arrays.toString(authors.toArray()) + " " + journal + " " + raw;
//    return key + " " + Arrays.toString(authors.toArray()) + " : " + title + " : " + year + " : " + journal + " " + startPage + "-" + endPage + " [" + score + "]";
  }

  /**
   * Outputs the given entry in a json representation.
   * 
   * @param entry the entry to output.
   * @return the json representation of the entry.
   */
  @Override
  public String toJson() {
    StringBuilder sb = new StringBuilder();
    sb.append("{\n");
    if (getKey() != null) {
      sb.append("\"externalKey\": \"" + getKey() + "\",\n"); 
    }
    if (getTitle() != null) {
      sb.append("\"title\": \"" + getTitle() + "\",\n"); 
    }
    if (getAuthors() != null) {
      sb.append("\"authors\": [\n"); 
      for (int i = 0; i < getAuthors().size(); i++) {  
        sb.append("\"" + getAuthors().get(i) + "\"");
        if (i < getAuthors().size() - 1) sb.append(", \n"); 
      }
      sb.append(" ],"); 
    }
    if (getJournal() != null) {
      sb.append("\"journal\": \"" + getJournal() + "\",\n");
    }
    if (getEe() != null) {
      sb.append("\"ee\": \"" + getEe() + "\",\n");
    }
    if (getUrl() != null) {
      sb.append("\"url\": \"" + getUrl() + "\",\n");
    }
    if (getStartPage() != -1) {
      sb.append("\"startPage\": \"" + getStartPage() + "\",\n");
    }
//    if (getRaw() != null) {
//      sb.append("\"raw\": " + toJsonUtf8String(getRaw())+",");
//    }
    sb.append("\"year\": \"" + getYear() + "\"\n");
    sb.append("}");
  return sb.toString(); 
}

  /**
   * Sets the abstract.
   * 
   * @param abstractText the abstract to set.
   */
  public void setAbstract(String abstractText) {
    this.abstractText = abstractText;
  }

  /**
   * Returns the abstract.
   * 
   * @return the abstract.
   */
  public String getAbstract() {
    return abstractText;
  }

  /**
   * Returns the url.
   */
  public String getUrl() {
    return url;
  }

  /**
   * Sets the url.
   * 
   * @param url the url.
   */
  public void setUrl(String url) {
    this.url = url;
  }

  /**
   * Gets the ee.
   */
  public String getEe() {
    return ee;
  }

  /**
   * Sets the ee.
   * 
   * @param ee the ee.
   */
  public void setEe(String ee) {
    this.ee = ee;
  }
}
