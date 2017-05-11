package de.freiburg.iif.extraction.servlet;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.util.List;

import org.apache.commons.codec.binary.Base64InputStream;
import org.apache.commons.codec.binary.Base64OutputStream;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import de.freiburg.iif.enrichment.CitationsDetector.Citation;
import de.freiburg.iif.model.HasMetadata;

/**
 * Is used in PdfTransformServlet to transform metadata to pdf.
 * 
 * @author Claudius Korzen.
 *
 */
public class Metadata2PdfTransformer {  
  /** The downloaded pdf as base64 string */
  protected String base64Data;
  /** The transformer that transform the pdf to metadata and references */
  protected Pdf2MetadataTransformer p2mTransformer;
  /** The transformer will also extract metadata from pdf */
  protected HasMetadata metadata;
  /** The transformer will also extract references from pdf */
  protected List<HasMetadata> references;
  /** The transformer will also extract citations from pdf */
  protected List<Citation> citations;
  /** The pdf enricher */
  // protected PdfEnricher enricher;
  /** The log4j-logger */
  protected Log LOG = LogFactory.getLog(Metadata2PdfTransformer.class);
  
  /** The constructor */
  public Metadata2PdfTransformer() {
    p2mTransformer = new Pdf2MetadataTransformer();
    //enricher = new PdfEnricher();
  }
  
  /** Enumeration of Publishers */
  enum Publisher {
    /** Publisher ACM */
    ACM("http://portal.acm.org/", "http://dl.acm.org/"),
    /** Publisher Springer */
    SPRINGER("http://springerlink.com/", "http://www.springerlink.com/", 
        "www.springerlink.com/", "http://link.springer.com/"),
    /** Publisher Arxiv */
    ARXIV("http://arxiv.org/"),
    /** Direct linked pdfs */
    DIRECT_LINKED,
    /** Defualt publisher */
    NONE;
    
    /** The related urls of publishers */
    String[] urls;
    
    /** 
     * The constructor 
     * 
     * @param urls the array of urls. 
     */
    Publisher(String... urls) {
      this.urls = urls;
    }
  }
  
  /**
   * Tries to find a related pdf to given entry.
   * 
   * @param entry the entry to process.
   */
  public void transform(HasMetadata entry) {
    LOG.info("XXX");
    InputStream is = download(guessDownloadUrl(resolveUrl(entry)));
    if (is == null) is = download(guessDownloadUrlViaGoogle(entry));
    if (is != null) {
      try {
        byte[] byteArray = toByteArray(is, true);  
        is.close();
        if (byteArray != null) {
          InputStream is1 = new Base64InputStream(new ByteArrayInputStream(byteArray));
          p2mTransformer.transform(is1);
          is1.close();
          this.metadata = p2mTransformer.getMetadata();
          this.references = p2mTransformer.getReferences();
          this.citations = p2mTransformer.getCitations();
          
          // TODO!
          InputStream is2 = new Base64InputStream(new ByteArrayInputStream(byteArray));
          ByteArrayOutputStream baos = new ByteArrayOutputStream();
          OutputStream os = new Base64OutputStream(baos, true, 0, null);
          
          byte[] buffer = new byte[1024]; // Adjust if you want
          int bytesRead;
          while ((bytesRead = is2.read(buffer)) != -1) {
              os.write(buffer, 0, bytesRead);
          }
          this.base64Data = new String(baos.toByteArray());
          is2.close();
          os.flush();
          os.close();
        }
      } catch (Exception e) {
        // TODO: Error handling.
        e.printStackTrace();
      }
    }
  }

  /**
   * Resolves the url for the given entry (i.e. follows all redirects)
   * 
   * @param entry the entry to process.
   * @return the resolved url.
   */
  protected String resolveUrl(HasMetadata entry) {
    if (entry != null) {
      String ee = entry.getEe();
      if (ee != null) {
        try {
          URL url = new URL(ee);
          URLConnection con = url.openConnection(); 
          String hop = null;
          while ((hop = con.getHeaderField("Location")) != null) {
            try {
              url = new URL(hop);
            } catch (Exception e) {
              break;
            }
            con = url.openConnection();
          }
          return url.toString();
        } catch (IOException e) {
          return null;
        }
      }
    }
    return null;
  }
  
  /**
   * Tries to guess the publisher of given entry.
   * 
   * @param ee the url to electronic edition.
   * @return the publisher.
   */
  protected Publisher guessPublisher(String ee) {
    if (ee != null) {
      if (ee.endsWith(".pdf")) return Publisher.DIRECT_LINKED;

      // Check, if the publisher is ACM.
      for (String url : Publisher.ACM.urls) {
        if (ee.startsWith(url)) return Publisher.ACM;
      }
      // Check, if the publisher is Springer.
      for (String url : Publisher.SPRINGER.urls) {
        if (ee.startsWith(url)) return Publisher.SPRINGER;
      }
      // Check, if the publisher is ARXIV.
      for (String url : Publisher.ARXIV.urls) {
        if (ee.startsWith(url)) return Publisher.ARXIV;
      }
    }
    return Publisher.NONE;
  }
  
  /**
   * Tries to guess the url for given ee.
   * 
   * @param ee the url by publisher.
   * @return the direct link to the pdf.
   */
  protected String guessDownloadUrl(String ee) {
    Publisher p = guessPublisher(ee);
    switch(p) {
      case ACM:
        return guessACMDownloadUrl(ee);
      case ARXIV:
        return guessArxivDownloadUrl(ee);
      case SPRINGER:
        return guessSpringerDownloadUrl(ee);
      case DIRECT_LINKED:
        return guessDirectDownloadUrl(ee);
      case NONE:
      default:
        return null;
    }
  }
  
  /**
   * Guesses the download url, given that ACM is the publisher.
   * 
   * @param ee the ee to process.
   * @return the direct link to the pdf.
   */
  protected String guessACMDownloadUrl(String ee) {
    // http://portal.acm.org/citation.cfm?doid=301136.301191 -> 
    // http://portal.acm.org/ft_gateway.cfm?id=301191&type=pdf
    int indexOfLastPoint = ee.lastIndexOf('.');
    String id = ee.substring(indexOfLastPoint + 1);
    return "http://portal.acm.org/ft_gateway.cfm?id="+id+"&type=pdf";
  }
  
  /**
   * Guesses the download url, given that Arxiv is the publisher.
   * 
   * @param ee the ee to process.
   * @return the direct link to the pdf.
   */
  protected String guessArxivDownloadUrl(String ee) {
    StringBuffer sb = new StringBuffer(ee);
    int index = sb.indexOf("abs");
    sb.replace(index, index + 3, "pdf");
    return sb.toString();
  }
  
  /**
   * Guesses the download url, given that Springer is the publisher.
   * 
   * @param ee the ee to process.
   * @return the direct link to the pdf.
   */
  protected String guessSpringerDownloadUrl(String ee) {
    return ee + "/fulltext.pdf";
  }
  
  /**
   * Guesses the download url, given that ee points directly to the pdf.
   * 
   * @param ee the ee to process.
   * @return the direct link to the pdf.
   */
  protected String guessDirectDownloadUrl(String ee) {
    return ee;
  }
  
  /**
   * Guesses the download url for given entry via querying google.
   * 
   * @param entry the entry to process.
   * @return the direct link to pdf.
   */
  protected String guessDownloadUrlViaGoogle(HasMetadata entry) {
    String url = createGoogleQueryUrl(entry);
     
    try {
      return parseGoogleResult(url);
    } catch (IOException e) {
      return null;
    }
  }
  
  /**
   * Encodes a string of arguments as a URL for a Google search query.
   * 
   * @param entry the entry to process.
   * 
   * @return An url for a Google search query based on the arguments.
   */
  protected String createGoogleQueryUrl(HasMetadata entry) {
    if (entry != null) {
      final StringBuilder sb = new StringBuilder("/search?q=");
      if (entry.getTitle() != null && entry.getAuthors() != null) {
        String query = entry.getTitle() + " filetype:pdf";
        try {
          query = URLEncoder.encode(query, "UTF-8");
        } catch (IOException e) {
          // Nothing to do.
        }
        sb.append(query);
        return "http://www.google.com" + sb.toString();
      }
    }
    return null;
  }
  
  /**
   * Parses the Google response for links to pdfs.
   * 
   * @param urlStr the url of google query.
   * @return the first link of the first hit of google query.
   * @throws IOException if parsing the google response fails.
   */
  protected String parseGoogleResult(String urlStr) throws IOException {    
    if (urlStr != null) {
      // These tokens are adequate for parsing the HTML from Google. First,
      // find a heading-3 element with an "r" class. Then find the next anchor
      // with the desired link. The last token indicates the end of the URL
      // for the link.
      final String googleEntryHeaderStartToken = "<h3 class=\"r\">";
      final String googleEntryUrlStartToken = "/url?q=";
      final String googleEntryUrlEndToken = "&";
      
      try {
        URL url = new URL(urlStr);
        URLConnection conn = url.openConnection();
        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.17) Gecko/20110422 Ubuntu/9.10 (karmic) Firefox/3.6.17"); // TODO: Parameterize
        InputStream is = conn.getInputStream();
        String toParse = new String(toByteArray(is, false));
        is.close();
                        
        // Loop until all links are found and parsed. Find each link by
        // finding the beginning and ending index of the tokens defined
        // above.
        int index = 0;
        if (-1 != (index = toParse.indexOf(googleEntryHeaderStartToken, index))) {
          final int result = toParse.indexOf(googleEntryUrlStartToken, index);
          
          // parse url to pdf
          final int urlStart = result + googleEntryUrlStartToken.length();
          final int urlEnd = toParse.indexOf(googleEntryUrlEndToken, urlStart);
          final String urlText = toParse.substring(urlStart, urlEnd);
          
  //        // parse description of pdf
  //        final int descriptionStart = toParse.indexOf(googleEntryDescriptionStartToken, urlEnd) + googleEntryDescriptionStartToken.length();
  //        final int descriptionEnd = toParse.indexOf(googleEntryDescriptionEndToken, descriptionStart);
  //        String description = toParse.substring(descriptionStart, descriptionEnd);
  //        description = description.replaceAll("<b>|</b>", "");
          
          return urlText;
        }
      } catch (final IndexOutOfBoundsException e) {
        throw new IOException("Failed to parse Google links.");
      }
    }
    return null;
  }
  
  /**
   * Downloads the pdf for given url.
   * 
   * @param downloadUrl the url to process.
   * @return the content of downloaded pdf.
   */
  protected InputStream download(String downloadUrl) {
    if (downloadUrl != null) {
      try {
        URL url = new URL(downloadUrl);
        URLConnection conn = url.openConnection();
        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.17) Gecko/20110422 Ubuntu/9.10 (karmic) Firefox/3.6.17"); // TODO: Parameterize        
        String contentType = conn.getContentType();
        if (contentType != null && contentType.contains("pdf")) {
          if (conn.getContentLength() > 0) {
            return conn.getInputStream();
          }
        }
      } catch (IOException e) {
        return null;
      }
    }
    return null;
  }
  
  /**
   * Transform a given InputStream to String.
   * 
   * @param is the InputStream-object to transform.
   * @param base64Encoded true, if result should be base64 encoded.
   * @return the InputStream-object ads string.
   * @throws IOException if transforming the InputStream-object fails.
   */
  private static byte[] toByteArray(InputStream is, boolean base64Encoded)
      throws IOException {
    final ByteArrayOutputStream baos = new ByteArrayOutputStream();
    OutputStream os = baos;
    if (base64Encoded) os = new Base64OutputStream(baos, true, 0, null);
    int ch;
    while (-1 != (ch = is.read())) os.write(ch);
    os.flush();
    os.close();
    return baos.toByteArray();
  }
  
  /**
   * Returns the result as Json.
   * 
   * @return the result as Json.
   */
  public String toJson() {
    StringBuilder sb = new StringBuilder();
    sb.append("{");
    // Append the pdf.
    sb.append(Pdf2MetadataTransformer.toJson(metadata));
    if (references != null) {
      if (sb.length() > 5) sb.append(","); // 5 is arbitrarily chosen (>1), to 
      // check, if there is some preceding stuff.
      sb.append("\"references\": ["); 
      for (int i = 0; i < references.size(); i++) {
        HasMetadata reference = references.get(i);
        sb.append("{");
        sb.append(Pdf2MetadataTransformer.toJson(reference));
        sb.append((i < references.size() - 1) ? "}," : "}");
      }
      sb.append("]");
    }
    if (base64Data != null) {
      if (sb.length() > 5) sb.append(",");
      sb.append("\"pdf\": \"" + base64Data + "\"");
    }
    sb.append("}");
    return sb.toString();
  }
}