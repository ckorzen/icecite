package de.freiburg.iif.extraction.metadataknowledge;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map.Entry;

import org.apache.commons.lang3.StringEscapeUtils;

import de.freiburg.iif.model.DblpRecord;
import de.freiburg.iif.model.HasMetadata;

/**
 * The interface MetadataKnowledge to communicate with a metadata knowledge
 * base.
 * 
 * @author Claudius Korzen
 * 
 */
public class InvertedIndexMetadataKnowledge implements MetadataKnowledge {
  // TODO: Move the properties to an properties-file.
  /** The hostname of socket of inverted index */
  protected static final String host =
      "http://stromboli.informatik.uni-freiburg.de";
  /** The port of socket of inverted index. */
  protected static final int port = 6200;
  /** The flag that indicates whether the verbose mode is enabled. */
  protected boolean verbose;

  @Override
  public List<HasMetadata> query(MetadataKnowledgeQueryType type,
    String value, int minWaitInterval) throws IOException {
    URL url = new URL(host + ":" + port + "/?" + type.paramKey + "=" + value);
    InputStream is = queryIndex(url);
    List<HasMetadata> response = parseIndexResponse(is);
    // Don't forget to close the stream.
    is.close();
    return response;
  }

  @Override
  public List<HasMetadata> query(MetadataKnowledgeQuery query,
    int minWaitInterval) throws IOException {
    InputStream is = queryIndex(query);
    List<HasMetadata> response = parseIndexResponse(is);
    // Don't forget to close the stream.
    is.close();
    return response;
  }

  @Override
  public int getNumOfHits(MetadataKnowledgeQueryType type, String value,
    int minWaitInterval) throws IOException {
    URL url = new URL(host + ":" + port + "/?" + type.paramKey + "=" + value);
    InputStream is = queryIndex(url);
    int numOfHits = parseNumOfHits(is);
    // Don't forget to close the stream.
    is.close();
    return numOfHits;
  }

  @Override
  public int getNumOfHits(MetadataKnowledgeQuery query, int minWaitInterval)
    throws IOException {
    InputStream is = queryIndex(query);
    int numOfHits = parseNumOfHits(is);
    // Don't forget to close the stream.
    is.close();
    return numOfHits;
  }

  /**
   * Queries the inverted index with the given paramKey and the given
   * paramValue.
   * 
   * @param query
   *          the query.
   * @return an instance of InputStream.
   * @throws IOException
   *           if querying the index fails.
   */
  protected InputStream queryIndex(MetadataKnowledgeQuery query)
    throws IOException {
    return queryIndex(prepareIndexUrl(query));
  }

  /**
   * Queries the inverted index with the given paramKey and the given
   * paramValue.
   * 
   * @param url
   *          the url to query the index.
   * @return an instance of InputStream.
   * @throws IOException
   *           if querying the index fails.
   */
  protected InputStream queryIndex(URL url) throws IOException {
    if (url != null) {
      InputStream is = url.openStream();
      return is;
    }
    return null;
  }

  /**
   * Prepares the url to query the index.
   * 
   * @param query
   *          the query.
   * @return the url to query the index.
   * @throws IOException
   *           if creating the url fails.
   */
  protected URL prepareIndexUrl(MetadataKnowledgeQuery query)
    throws IOException {
    if (query != null) {
      boolean isFirstParam = true;
      StringBuilder sb = new StringBuilder();
      for (Entry<MetadataKnowledgeQueryType, String> param : query.getParams()) {
        if (!isFirstParam) {
          sb.append("&");
        }
        sb.append(param.getKey().paramKey);
        sb.append("=");
        sb.append(param.getValue());
        isFirstParam = false;
      }

      return new URL(host + ":" + port + "/?" + sb.toString());
    }
    return null;
  }

  /**
   * Parses the response from the index.
   * 
   * @param is
   *          the response from the index.
   * @return list of records, that are included in the response.
   * @throws IOException
   *           if the parsing of the response fails.
   */
  protected List<HasMetadata> parseIndexResponse(InputStream is)
    throws IOException {
    List<HasMetadata> list = new ArrayList<HasMetadata>();
    try (BufferedReader br = new BufferedReader(new InputStreamReader(is))) {
      String line;
      // Parse the response line by line.
      while ((line = br.readLine()) != null) {
        int pos1 = line.indexOf("<record");
        int pos2;
  
        if (pos1 > -1) {
          // Extract the score of the record.
          pos1 = line.indexOf("score=\"", pos1) + 7;
          pos2 = line.indexOf("\"", pos1);
          double score = Double.parseDouble(line.substring(pos1, pos2));
  
          // Extract the key of the record.
          pos1 = line.indexOf("key=\"", pos2) + 5;
          pos2 = line.indexOf("\"", pos1);
          String key = line.substring(pos1, pos2);
  
          // Extract the title of the record.
          pos1 = line.indexOf("title=\"", pos2) + 7;
          pos2 = line.indexOf("\"", pos1);
          // Title can contain HTML character entities (like "&aacute;). Unescape
          // them.
          String title = line.substring(pos1, pos2);
          title = StringEscapeUtils.unescapeHtml4(title);
          title = StringEscapeUtils.unescapeXml(title);
  
          // Extract the authors of the record. The individual authors are
          // seperated by "$".
          pos1 = line.indexOf("authors=\"", pos2) + 9;
          pos2 = line.indexOf("\"", pos1);
          // Authors can contain HTML character entities (like "&aacute;).
          // Unescape them.
          String authorsValue = line.substring(pos1, pos2);
          authorsValue = StringEscapeUtils.unescapeHtml4(authorsValue);
          authorsValue = StringEscapeUtils.unescapeXml(authorsValue);
          String[] authorArr = authorsValue.split("\\$");
          List<String> authors = new ArrayList<String>(Arrays.asList(authorArr));
  
          // Extract the year of the record.
          pos1 = line.indexOf("year=\"", pos2) + 6;
          pos2 = line.indexOf("\"", pos1);
          String yearStr = line.substring(pos1, pos2);
          int year = -1;
          if (!yearStr.trim().isEmpty()) {
            year = Integer.parseInt(yearStr);
          }
  
          // Extract the journal of the record.
          pos1 = line.indexOf("journal=\"", pos2) + 9;
          pos2 = line.indexOf("\"", pos1);
          String journal = line.substring(pos1, pos2);
          journal = StringEscapeUtils.unescapeHtml4(journal);
          journal = StringEscapeUtils.unescapeXml(journal);
  
          // Extract the journal of the record.
          pos1 = line.indexOf("pages=\"", pos2) + 7;
          pos2 = line.indexOf("\"", pos1);
          String pages = line.substring(pos1, pos2);
          int startPage = -1;
          int endPage = -1;
          if (!pages.isEmpty()) {
            String[] fragments = pages.split("-");
            if (fragments.length >= 2) {
              if (!fragments[0].isEmpty()) {
                try {
                  startPage = Integer.parseInt(fragments[0]);
                } catch (Exception e) {
                  // TODO: Something to do?
                }
              }
  
              if (!fragments[1].isEmpty()) {
                try {
                  endPage = Integer.parseInt(fragments[1]);
                } catch (Exception e) {
                  // TODO: Something to do?
                }
              }
            }
          }
  
          // Extract the journal of the record.
          pos1 = line.indexOf("url=\"", pos2) + 5;
          pos2 = line.indexOf("\"", pos1);
          String url = line.substring(pos1, pos2);
          
          // Extract the journal of the record.
          pos1 = line.indexOf("ee=\"", pos2) + 4;
          pos2 = line.indexOf("\"", pos1);
          String ee = line.substring(pos1, pos2);
                  
          // Create a new record.
          DblpRecord record = new DblpRecord();
          record.setScore(score);
          record.setKey(key);
          record.setTitle(title);
          record.setAuthors(authors);
          record.setYear(year);
          record.setJournal(journal);
          record.setStartPage(startPage);
          record.setEndPage(endPage);
          record.setEe(ee);
          record.setUrl(url);
          
          list.add(record);
        }
      }
    }

    return list;
  }

  /**
   * Parses the response and returns the number of hits.
   * 
   * @param is
   *          the response from the index.
   * @return the number of hits.
   * @throws IOException
   *           if the parsing of the response fails.
   */
  private int parseNumOfHits(InputStream is) throws IOException {
    try (BufferedReader br = new BufferedReader(new InputStreamReader(is))) {
      int numOfHits = 0;
      String line;
      // Parse the response line by line.
      while ((line = br.readLine()) != null) {
        int pos1 = line.indexOf("<result");
        int pos2;
  
        if (pos1 > -1) {
          pos1 = line.indexOf("hits=\"") + 6;
          pos2 = line.indexOf("\"", pos1);
  
          numOfHits = Integer.parseInt(line.substring(pos1, pos2));
          break;
        }
      }
      return numOfHits;
    }
  }

  /**
   * Returns true, if the verbose mode is enabled.
   * 
   * @return true, if the verbose mode is enabled.
   */
  public boolean isVerbose() {
    return verbose;
  }

  /**
   * Sets the flag, that indicates if the verbose mode is enabled.
   * 
   * @param verbose
   *          true to enable the verbose mode.
   */
  public void setVerbose(boolean verbose) {
    this.verbose = verbose;
  }
}
