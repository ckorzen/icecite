package de.freiburg.iif.extraction.metadataknowledge;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import de.freiburg.iif.model.HasMetadata;

/**
 * The interface to the metadata knowledge base.
 * 
 * @author Claudius Korzen.
 * 
 */
public interface MetadataKnowledge {
  /**
   * Query the metadata knowledge base.
   * 
   * @param type
   *          the type of the query parameter.
   * @param value
   *          the value of the query parameter.
   * @return the list of candidates from the metadata knowledge base.
   * @throws IOException
   *           if querying fails.
   */
  public List<HasMetadata>
    query(MetadataKnowledgeQueryType type, String value, int minWaitInterval) throws IOException;

  /**
   * Query the metadata knowledge base.
   * 
   * @param query
   *          the query.
   * @return the list of candidates from the metadata knowledge base.
   * @throws IOException
   *           if querying fails.
   */
  public List<HasMetadata> query(MetadataKnowledgeQuery query, int minWaitInterval)
    throws IOException;

  /**
   * Returns the number of hits for the given query.
   * 
   * @param type
   *          the type of the query parameter.
   * @param value
   *          the value of the query parameter.
   * @return the number of hits.
   * @throws IOException
   *           if querying fails.
   */
  public int getNumOfHits(MetadataKnowledgeQueryType type, String value, int minWaitInterval)
    throws IOException;

  /**
   * Returns the number of hits for the given query.
   * 
   * @param query
   *          the query.
   * @return the number of hits.
   * @throws IOException
   *           if querying fails.
   */
  public int getNumOfHits(MetadataKnowledgeQuery query, int minWaitInterval) throws IOException;

  /**
   * Class representing a query to the metadata knowledge.
   * 
   * @author Claudius Korzen
   * 
   */
  public class MetadataKnowledgeQuery {
    /** The map containing all key/value-pairs */
    protected Map<MetadataKnowledgeQueryType, String> query;
    /** The StringBuilder for the title-parameter */
    protected StringBuilder title;
    /** The StringBuilder for the author-parameter */
    protected StringBuilder author;
    /** The StringBuilder for the year-parameter */
    protected StringBuilder year;
    /** The StringBuilder for the other-parameter */
    protected StringBuilder other;

    /**
     * The constructor.
     */
    public MetadataKnowledgeQuery() {
      this.query = new HashMap<MetadataKnowledgeQueryType, String>();
      this.title = new StringBuilder();
      this.author = new StringBuilder();
      this.year = new StringBuilder();
      this.other = new StringBuilder();
    }

    /**
     * Adds an key/value-pair to the query.
     * 
     * @param key
     *          the key.
     * @param value
     *          the value.
     * @throws UnsupportedEncodingException
     *           if the encoding for url is unsupported.
     */
    public void add(MetadataKnowledgeQueryType key, String value)
      throws UnsupportedEncodingException {
//      value = URLEncoder.encode(value, "UTF-8");
      // query.put(key, value);
      switch (key) {
      case AUTHORS:
        author.append(value);
        author.append(" ");
        break;
      case TITLE:
        title.append(value);
        title.append(" ");
        break;
      case YEAR:
        year.append(value);
        year.append(" ");
        break;
      case OTHER:
        other.append(value);
        other.append(" ");
        break;
      }
    }

    /**
     * Assembles the query by putting the arguments together. 
     */
    public void create() {
      // query.put(key, value);
      if (title.length() > 0) {
        query.put(MetadataKnowledgeQueryType.TITLE, title.toString());
      }

      if (author.length() > 0) {
        query.put(MetadataKnowledgeQueryType.AUTHORS, author.toString());
      }

      if (year.length() > 0) {
        query.put(MetadataKnowledgeQueryType.YEAR, year.toString());
      }

      if (other.length() > 0) {
        query.put(MetadataKnowledgeQueryType.OTHER, other.toString());
      }
    }
    
    /***
     * Returns the parameter value for the given key.
     * 
     * @param type the key of parameter
     * @return the value of parameter.
     */
    public String getParam(MetadataKnowledgeQueryType type) {
      return query.get(type);
    }

    /**
     * Removes an key/value-pair from the query.
     * 
     * @param key
     *          the key.
     */
    public void remove(MetadataKnowledgeQueryType key) {
      query.remove(key);
    }

    /**
     * Returns the contained parameters.
     * 
     * @return the set of parameters.
     * 
     */
    public Set<Entry<MetadataKnowledgeQueryType, String>> getParams() {
      return query.entrySet();
    }

    /**
     * Returns true, if the query contains the parameter given by the key.
     * 
     * @param key
     *          the key to check.
     * @return true, if the query contains the parameter given by the key.
     * 
     */
    public boolean contains(MetadataKnowledgeQueryType key) {
      return query.containsKey(key);
    }

    @Override
    public String toString() {
      return query.toString();
    }
  }

  /**
   * Enumeration of query types.
   * 
   * @author Claudius Korzen
   * 
   */
  public enum MetadataKnowledgeQueryType {
    /** The query type "title" */
    TITLE("t"),
    /** The query type "reference" */
    REFERENCE("r"),
    /** The query type "authors" */
    AUTHORS("a"),
    /** The query type "year" */
    YEAR("y"),
    /** The query type "other" */
    OTHER("x"),
    /** The query type "number of hits for an author-word" */
    NUMOFHITS_AUTHORS("na"),
    /** The query type "number of hits for an title-word" */
    NUMOFHITS_TITLE("nt");

    /** The url-parameter key */
    public String paramKey;

    /**
     * The constructor.
     * 
     * @param paramKey
     *          the url-parameter key
     */
    private MetadataKnowledgeQueryType(String paramKey) {
      this.paramKey = paramKey;
    }
  }

}
