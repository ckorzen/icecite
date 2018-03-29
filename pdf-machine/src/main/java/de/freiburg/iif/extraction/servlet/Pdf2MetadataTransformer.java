package de.freiburg.iif.extraction.servlet;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;
import java.util.regex.Pattern;

import org.apache.commons.codec.binary.Base64OutputStream;
import org.apache.commons.io.output.ByteArrayOutputStream;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import de.freiburg.iif.enrichment.CitationsDetector.Citation;
import de.freiburg.iif.extraction.PaperMatcher;
import de.freiburg.iif.model.HasMetadata;

/**
 * Is used in PdfTransformServlet to transform pdf to metadata.
 * 
 * @author Claudius Korzen.
 *
 */
public class Pdf2MetadataTransformer {
  /** The extractor */
  private PaperMatcher matcher;
//  /** The extractor */
//  private PdfEnricher enricher;
  /** The extracted metadata */
  private HasMetadata metadata;
  /** The extracted references */
  private List<HasMetadata> references;
  /** The extracted citations */
  private List<Citation> citations;
  /** The log4j-logger */
  protected Log LOG = LogFactory.getLog(PdfTransformServlet.class);
  /** The Pattern to find a OpenAction entry. */
  protected Pattern openActionPattern = Pattern.compile("/OpenAction << ");
  /** The base64 string */
  protected String base64;
  
  /**
   * The constructor.
   */
  public Pdf2MetadataTransformer() {
    this.matcher = new PaperMatcher();
//    this.enricher = new PdfEnricher();
  }
  
  /**
   * Extracts the metadata and references from pdf.
   * 
   * @param stream the inputstream of pdf.
   * @throws IOException if extracting the metadata/references fails.
   */
  public void transform(InputStream stream) throws IOException {    
    // Extract the metadata and references.
    if (stream != null) {
      byte[] byteArray = toByteArray(stream);
      try {
        InputStream is1 = new ByteArrayInputStream(byteArray); 
        matcher.match(is1, true, true, true);
        is1.close();
        this.metadata = matcher.getMetadata();
        this.references = matcher.getReferences(); 
        this.citations = matcher.getCitations();
        
        // TODO
        InputStream is2 = new ByteArrayInputStream(byteArray);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        OutputStream os = new Base64OutputStream(baos, true, 0, null);
        byte[] buffer = new byte[1024]; // Adjust if you want
        int bytesRead;
        while ((bytesRead = is2.read(buffer)) != -1) {
            os.write(buffer, 0, bytesRead);
        }
        this.base64 = new String(baos.toByteArray());
        is2.close();
        os.flush();
        os.close();
      } catch (IOException e) {
        throw (e);
      }
    }
  }
  
  /**
   * Outputs the extraction results as json.
   * 
   * @return the extraction results as json.
   */
  public String toJson() {
    StringBuilder sb = new StringBuilder();
    sb.append("{");
    String metadataJson = toJson(metadata);
    sb.append(metadataJson);
    if (references != null) {
      if (metadataJson != null && metadataJson.length() > 0) sb.append(",");
      sb.append("\"references\": ["); 
      for (int i = 0; i < references.size(); i++) {
        HasMetadata reference = references.get(i);
        sb.append("{");
        sb.append(toJson(reference));
        sb.append((i < references.size() - 1) ? "}," : "}");
      }
      sb.append("]");
    }
//    if (base64 != null) {
//      if (sb.length() > 5) sb.append(",");
//      sb.append("\"pdf\": \"" + base64 + "\"");
//    }
    sb.append("}");
    return sb.toString();
  }
  
  /**
   * Outputs the given entry in a json representation.
   * 
   * @param entry the entry to output.
   * @return the json representation of the entry.
   */
  protected static String toJson(HasMetadata entry) {
    StringBuilder sb = new StringBuilder();
    if (entry != null) {      
      if (entry.getKey() != null) {
        sb.append("\"externalKey\": \""+entry.getKey()+"\","); 
      }
      if (entry.getTitle() != null) {
        sb.append("\"title\": \""+ toJsonUtf8String(entry.getTitle()) +"\","); 
      }
      if (entry.getAuthors() != null) {
        sb.append("\"authors\": ["); 
        for (int i = 0; i < entry.getAuthors().size(); i++) {  
          sb.append("\"" + entry.getAuthors().get(i) + "\"");
          if (i < entry.getAuthors().size() - 1) sb.append(", "); 
        }
        sb.append(" ],"); 
      }
      if (entry.getJournal() != null) {
        sb.append("\"journal\": \""+entry.getJournal()+"\",");
      }
      if (entry.getEe() != null) {
        sb.append("\"ee\": \""+entry.getEe()+"\",");
      }
      if (entry.getUrl() != null) {
        sb.append("\"url\": \""+entry.getUrl()+"\",");
      }
      if (entry.getRaw() != null) {
        sb.append("\"raw\": \"" + toJsonUtf8String(entry.getRaw())+"\",");
      }
      if (entry.getLineCoordinates() != null) {
        StringBuilder coordsSb = new StringBuilder();
        coordsSb.append("[");
        for (int i = 0; i < entry.getLineCoordinates().size(); i++) {
          Object[] coords = entry.getLineCoordinates().get(i);
          coordsSb.append("[");
          coordsSb.append(coords[0] + ", ");
          coordsSb.append(coords[1] + ", ");
          coordsSb.append(coords[2] + ", ");
          coordsSb.append(coords[3] + ", ");
          coordsSb.append(coords[4]);
          coordsSb.append("]");
          if (i < entry.getLineCoordinates().size() - 1) {
            coordsSb.append(", ");
          }
        }
        coordsSb.append("]");
        sb.append("\"lineCoordinates\": " + coordsSb.toString() + ",");
      }
      sb.append("\"year\": \""+entry.getYear()+"\"");
    }
    return sb.toString(); 
  }
  
//  /**
//   * Stores the given InputStream to file.
//   * 
//   * @param stream the stream to store.
//   * @return the file.
//   * @throws IOException if storing the stream fails.
//   */
//  private File store(InputStream stream) throws IOException {
//    if (stream != null) {
//      // TODO: Adjust the parent dir.
//      File parent = new File("/home/korzen/Downloads/");
//      // TODO: Adjust the filename.
//      File file = File.createTempFile("icecite-", ".pdf", parent);
//      
//      System.out.println(stream.hashCode());
//      
//      FileOutputStream fos = new FileOutputStream(file, false);
//      BufferedOutputStream bos = new BufferedOutputStream(fos);
//  
//      int bytesRead;
//      while ((bytesRead = stream.read()) != -1) {
//        bos.write(bytesRead);
//      }
//      stream.close();
//      bos.flush();
//      bos.close();
//      return file;
//    }
//    return null;
//  }
//  
//  protected InputStream cleanup(InputStream stream) throws IOException {
//    if (stream != null) {
//      String string = new String(IOUtils.toByteArray(stream));
//      Matcher m = openActionPattern.matcher(string);
//      
//      if (m.find()) { // Deletes only the first OpenAction entry.
//        String firstPart = string.substring(0, m.start());
//        String secondPart = string.substring(m.start() + 1);
//        string = firstPart + secondPart.substring(secondPart.indexOf(">>") + 2);
//      } 
////      return string;
//      return new ByteArrayInputStream(string.getBytes());
//    }
//    return null;
//  }
  
  /**
   * Returns the extracted metadata.
   * 
   * @return the extracted metadata.
   */
  public HasMetadata getMetadata() {
    return metadata;
  }
  
  /**
   * Returns the extracted references.
   * 
   * @return the extracted references.
   */
  public List<HasMetadata> getReferences() {
    return references;
  }
  
  /**
   * Returns the extracted citations.
   * 
   * @return the extracted citations.
   */
  public List<Citation> getCitations() {
    return citations;
  }
  
  /**
   * Write out special characters "\b, \f, \t, \n, \r", as such, backslash as \\
   * quote as \" and values less than an ASCII space (20hex) as "\\u00xx" format,
   * characters in the range of ASCII space to a '~' as ASCII, and anything higher in UTF-8.
   *
   * @param s String to be written in utf8 format on the output stream.
   * @return the string as json.
   */
  public static String toJsonUtf8String(String s) {
    StringBuffer sb = new StringBuffer();   
//    sb.append('\"');
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      // Anything less than ASCII space, write either in \\u00xx form,
      // or the special \t, \n, etc. form
      if (c < ' ') { 
        if (c == '\b') {
          sb.append("\\b");
        } else if (c == '\t') {
          sb.append("\\t");
        } else if (c == '\n') {
          sb.append("\\n");
        } else if (c == '\f') {
          sb.append("\\f");
        } else if (c == '\r') {
          sb.append("\\r");
        } else {
          String hex = Integer.toHexString(c);
          sb.append("\\u");
          int pad = 4 - hex.length();
          for (int k = 0; k < pad; k++) {
            sb.append('0');
          }
          sb.append(hex);
        }
      } else if (c == '\\' || c == '"') {
        sb.append('\\');
        sb.append(c);
      } else {   // Anything else - write in UTF-8 form (multi-byte encoded) (OutputStreamWriter is UTF-8)
        sb.append(c);
      }
    }
//    sb.append('\"');
    return sb.toString();
  }
  
  /**
   * Converts the given InputStream into byte array.
   */
  public byte[] toByteArray(InputStream stream) throws IOException {
    ByteArrayOutputStream b = new ByteArrayOutputStream();

    byte[] buffer = new byte[1024];
    int len;
    while ((len = stream.read(buffer)) > -1 ) {
        b.write(buffer, 0, len);
    }
    b.flush();

    byte[] byteArray = b.toByteArray();
    b.close();
    return byteArray;
  }
}
