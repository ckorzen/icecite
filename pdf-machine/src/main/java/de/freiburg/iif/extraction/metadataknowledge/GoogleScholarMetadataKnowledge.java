package de.freiburg.iif.extraction.metadataknowledge;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;
import java.net.URL;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.Map.Entry;
import java.util.Random;

import org.apache.commons.lang3.StringEscapeUtils;
import org.apache.commons.logging.Log;

import com.google.inject.Inject;

import de.freiburg.iif.model.DblpRecord;
import de.freiburg.iif.model.HasMetadata;

/**
 * The class GoogleScholarMetadataKnowledge, using GoogleScholar as the metadata
 * knowledge.
 * 
 * @author Claudius Korzen
 * 
 */
public class GoogleScholarMetadataKnowledge implements MetadataKnowledge {
  /** The hostname for Google Scholar */
  protected static final String host = "http://scholar.google.com/scholar";
  /** The log */
  protected Log LOG;
  /** The number of requests */
  protected int numOfRequests;
  /** The minimum time interval to wait before sending the request */
  protected int minWaitInterval;
  /** The random generator */
  protected Random random;
  /** The cookie to send along to a Google Scholar query */
  protected String cookie;

  // The structure of an entry in Google Scholar:
  // <div class='gs_ri'>"
  // <h3 class="gs_rt">
  // <a href="#"><b>Hygroscopic </b>properties of carbon and <b>diesel </b>soot
  // particles</a>
  // </h3>
  // <div class="gs_a">
  // E Weingartner, H Burtscher, U Baltensperger - Atmospheric Environment, 1997
  // - Elsevier
  // </div>
  // </div>

  /** The identifier for the start of the title of an entry. */
  private static final String ENTRY_TITLE_START = "<h3 class=\"gs_rt\">";
  /** The identifier for the start of the metadata-section of an entry */
  private static final String ENTRY_METADATA_START = "<div class=\"gs_a\">";

  /**
   * The constructor.
   * 
   * @param log
   *          the implementation of Log.
   */
  @Inject
  public GoogleScholarMetadataKnowledge(Log log) {
    this.LOG = log;
    this.random = new Random();
  }

  @Override
  public List<HasMetadata> query(MetadataKnowledgeQueryType type,
    String value, int minWaitInterval) throws IOException {
    this.minWaitInterval = minWaitInterval;
    return queryGoogleScholar(value);
  }

  @Override
  public List<HasMetadata> query(MetadataKnowledgeQuery query,
    int minWaitInterval) throws IOException {
    this.minWaitInterval = minWaitInterval;
    return queryGoogleScholar(query.getParam(MetadataKnowledgeQueryType.TITLE));
  }

  @Override
  public int getNumOfHits(MetadataKnowledgeQueryType type, String value,
    int minWaitInterval) throws IOException {
    // Not supported.
    if (type == MetadataKnowledgeQueryType.TITLE) { return 1; }
    return 0;
  }

  @Override
  public int getNumOfHits(MetadataKnowledgeQuery query, int minWaitInterval)
    throws IOException {
    // Not supported.
    return 0;
  }

  /**
   * Query Google Scholar.
   * 
   * @param query
   *          the query.
   * @return an input stream containing the response.
   * @throws IOException
   *           if querying Google Scholar fails.
   */
  public List<HasMetadata> queryGoogleScholar(String query)
    throws IOException {
    
    int maxWaitInterval = 5 * minWaitInterval;
    int timeToWait = random.nextInt(maxWaitInterval - minWaitInterval + 1)
     + minWaitInterval;
    System.out.print("Time to wait: " + timeToWait + "ms...");
    
    String host = "scholar.google.com"; // TODO: Parameterize
    String get = "/scholar?q=" + URLEncoder.encode(query, "UTF-8"); // TODO:
                                                             // Parameterize
    int port = 80;

    try (Socket socket = new Socket(host, port);
        OutputStreamWriter osw = new OutputStreamWriter(socket.getOutputStream());
        PrintWriter writer = new PrintWriter(osw)) {   
      Thread.sleep(timeToWait);
      
      writer.println("GET " + get + " HTTP/1.1");
      writer.println("Host: " + host);
      writer.println("Accept: */*");
      writer.println("Accept-Encoding: Accept-Encoding:gzip,deflate,sdch");
      writer.println("Cache-Control: max-age=0");
      writer.println("Connection: keep-alive");
      if (cookie != null && !cookie.isEmpty()) {
        writer.println("Cookie: " + cookie);
      }
      writer.println("User-Agent: Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36");
      writer.println("");
      writer.flush();
      
      try (InputStream is = socket.getInputStream()) {
        return parseGoogleScholarResponse(is);  
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }

  // /**
  // * Queries Google Scholar with the given paramKey and the given paramValue.
  // *
  // * @param url
  // * the url to query the index.
  // * @return an instance of InputStream.
  // * @throws IOException
  // * if querying Google Scholar fails.
  // */
  // protected URLConnection queryGoogleScholar(URL url) throws IOException {
  // if (url != null) {
  // numOfRequests++;
  //
  // int maxWaitInterval = 5 * minWaitInterval;
  // int timeToWait =
  // random.nextInt(maxWaitInterval - minWaitInterval + 1)
  // + minWaitInterval;
  //
  // System.out.print("Time to wait: " + timeToWait + "ms...");
  //
  // try {
  // Thread.sleep(timeToWait);
  // } catch (InterruptedException e) {
  // // TODO: What to do?
  // }
  //
  // URLConnection conn = url.openConnection();
  // conn.setRequestProperty(
  // "User-Agent",
  // "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/26.0.1453.94 Safari/537.36");
  // return conn;
  // }
  // return null;
  // }

  /**
   * Prepares the url to query the index.
   * 
   * @param query
   *          the query.
   * @return the url to query the index.
   * @throws IOException
   *           if creating the url fails.
   */
  protected URL prepareGoogleScholarUrl(MetadataKnowledgeQuery query)
    throws IOException {
    if (query != null) {
      boolean isFirstParam = true;
      StringBuilder sb = new StringBuilder();
      for (Entry<MetadataKnowledgeQueryType, String> param : query.getParams()) {
        if (!isFirstParam) {
          sb.append("&");
        }

        String paramKey = "";
        switch (param.getKey()) {
        case AUTHORS:
          paramKey = "as_sauthors";
          break;
        default:
          paramKey = "as_q";
          break;
        }

        sb.append(paramKey);
        sb.append("=");
        sb.append(param.getValue());
        isFirstParam = false;
      }
      LOG.debug("Google Scholar: url: " + host + "?" + sb.toString());
      return new URL(host + "?" + sb.toString());
    }
    return null;
  }

  /**
   * Parses the response from the index.
   * 
   * @param is
   *          the input to parse.
   * @return list of records, that are included in the response.
   * @throws IOException
   *           if the parsing of the response fails.
   */
  protected List<HasMetadata> parseGoogleScholarResponse(InputStream is)
    throws IOException {
    List<HasMetadata> list = new ArrayList<HasMetadata>();
    String enc = "UTF-8";
    // TODO: Parse the response for encoding.
    // String enc = conn.getContentEncoding();
    // if (enc == null) {
    // enc = extractContentEncoding(conn.getContentType());
    // }
    // if (enc == null) {
    // enc = "UTF-8";
    // }

    try (BufferedReader br = new BufferedReader(new InputStreamReader(is, enc))) {

      String line;
      String title = null;
      List<String> authors = new ArrayList<String>();
      int year = 0;
      String journal = null;
  
      // The structure of an entry in Google Scholar:
      // <div class='gs_ri'>"
      // <h3 class="gs_rt">
      // <a href="#"><b>Hygroscopic </b>properties of carbon and <b>diesel
      // </b>soot particles</a>
      // </h3>
      // <div class="gs_a">
      // E Weingartner, H Burtscher, U Baltensperger - Atmospheric Environment,
      // 1997 - Elsevier
      // </div>
      // </div>
  
      StringBuilder cookieSB = new StringBuilder();
      // Parse the response line by line.
      while ((line = br.readLine()) != null && !line.equals("0")) {
        String setCookieKey = "Set-Cookie:";
        int index = line.indexOf(setCookieKey);
        if (index > -1) {
          line = line.substring(setCookieKey.length()).trim();
          String[] cookieElements = line.split(";");
          cookieSB.append(cookieElements[0] + "; ");
        }
        
        // Find the title of an entry.
        int pos1 = line.indexOf(ENTRY_TITLE_START);
        pos1 = line.indexOf(">", pos1 + ENTRY_TITLE_START.length());
        int pos2 = line.indexOf("</a>", pos1);
        if (pos1 > -1 && pos2 > -1) {
          title = unescape(line.substring(pos1 + 1, pos2));
        }
  
        // Find the metadata section of an entry (containing the authors, year,
        // journal).
        pos1 = line.indexOf(ENTRY_METADATA_START);
        pos2 = line.indexOf("</div>", pos1 + ENTRY_METADATA_START.length());
        if (pos1 > -1 && pos2 > -1) {
          String metadata =
              line.substring(pos1 + ENTRY_METADATA_START.length(), pos2);
          String[] metadataElements = metadata.split(" - ");
          if (metadataElements.length > 0) {
            String[] authorsArray = metadataElements[0].split(",");
            for (String author : authorsArray) {
              author = unescape(author);
              if (!author.isEmpty()) {
                authors.add(unescape(author));
              }
            }
          }
  
          if (metadataElements.length > 1) {
            String[] journalElements = metadataElements[1].split(",");
            journal = unescape(metadataElements[1].split(",")[0]);
            if (journalElements.length > 1) {
              String yearStr = journalElements[journalElements.length - 1];
              year = Integer.parseInt(unescape(yearStr));
            }
          }
        }
  
        if (title != null) {
          DblpRecord record = new DblpRecord();
          record.setTitle(title);
          record.setAuthors(authors);
          record.setYear(year);
          record.setJournal(journal);
          list.add(record);
        }
  
        authors = new ArrayList<String>();
        title = null;
        year = 0;
        journal = null;
      }
      
      if (cookieSB.length() > 0) {
        cookie = cookieSB.toString();
      }
    }

    return list;
  }

  /**
   * Unescapes the given text, i.e. removes html entities and removes the
   * content in "<>".
   * 
   * @param text
   *          the text to process.
   * @return the unescaped text.
   */
  protected static String unescape(String text) {
    text = text.replaceAll("[<].+?[>]", "");
    text = text.replaceAll("[\\[].+?[\\]]", "");
    text = text.replaceAll("[&]\\S*[;]", "");
    text = StringEscapeUtils.unescapeHtml4(text);
    return text.trim();
  }

  /**
   * Extracts the content encoding from the content type.
   * 
   * @param contentType
   *          the content type.
   * @return the content encoding.
   */
  public static String extractContentEncoding(String contentType) {
    if (contentType != null) {
      int index = contentType.indexOf("charset");
      if (index > -1) {
        index = contentType.indexOf("=", index);
        int index2 = contentType.indexOf(";", index);
        String encoding = null;
        if (index2 > -1) {
          encoding = contentType.substring(index + 1, index2);
        } else {
          encoding = contentType.substring(index + 1);
        }
        return encoding.trim();
      }
    }
    return null;
  }
}
