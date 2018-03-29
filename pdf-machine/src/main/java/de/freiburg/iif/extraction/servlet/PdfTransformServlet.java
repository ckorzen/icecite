package de.freiburg.iif.extraction.servlet;

import java.io.IOException;
import java.io.InputStream;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.codec.binary.Base64InputStream;
import org.apache.commons.io.IOUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.log4j.MDC;

import de.freiburg.iif.model.DblpRecord;

/**
 * Servlet, that handles transformation requests.
 * 
 * @author Claudius Korzen
 *
 */
public class PdfTransformServlet extends HttpServlet {  
  /** The serial version id */
  private static final long serialVersionUID = 1L;
  /** The log4j-logger */
  protected Log LOG = LogFactory.getLog(PdfTransformServlet.class);
  
  @Override
  public void doPost(HttpServletRequest request, HttpServletResponse response)
      throws IOException {    
    // Prepare the response.
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    response.setHeader("Access-Control-Max-Age", "1000");  
    response.setHeader("Access-Control-Allow-Headers", "*");
    response.setContentType("application/json;charset=UTF-8");
    response.setCharacterEncoding("UTF-8");

    // Handle the request.
    handleRequest(request, response);    
  }
  
  /**
   * Handles the request.
   * 
   * @param req the request to handle.
   * @param res the response to prepare.
   * @throws IOException if handling the request fails.
   */
  private void handleRequest(HttpServletRequest req, HttpServletResponse res) 
      throws IOException {
    if (req != null) {
      MDC.put("user-agent", req.getHeader("User-Agent"));
      MDC.put("ip-address", req.getRemoteAddr());
      
      switch (req.getPathInfo()) {
        case("/pdf2Meta"):
        case("/pdf2Meta/"):
          handlePdf2Meta(req, res);
          break;
        case("/meta2Pdf"):
        case("/meta2Pdf/"):
          handleMeta2Pdf(req, res);
          break;
        default:
          break;
      }
    }
  }
  
  /**
   * Handles a "pdf2Meta"-request.
   * 
   * @param req the request to handle.
   * @param res the response to prepare.
   * @throws IOException if handling the request fails.
   */
  private void handlePdf2Meta(HttpServletRequest req, HttpServletResponse res) 
      throws IOException {    
    Pdf2MetadataTransformer transformer = new Pdf2MetadataTransformer();
    
    LOG.info("pdf2meta");
    
    InputStream is = new Base64InputStream(req.getInputStream());
    transformer.transform(is);
    is.close();
        
    res.setContentType("application/json");
    res.getWriter().write(transformer.toJson());
  }
      
  /**
   * Handles a "meta2Pdf"-request.
   * 
   * @param req the request to handle.
   * @param res the response to prepare.
   * @throws IOException if handling the request fails.
   */
  private void handleMeta2Pdf(HttpServletRequest req, HttpServletResponse res) 
      throws IOException {
    Metadata2PdfTransformer transformer = new Metadata2PdfTransformer();

    LOG.info("meta2Pdf");
    
    req.getRemoteAddr();
    InputStream is = req.getInputStream();
    
    if (is != null) {
      transformer.transform(new DblpRecord(is));
      is.close();
    
      res.setContentType("text/plain");
      res.getWriter().write(transformer.toJson());
    }
  }
    
  public static void main(String[] args) throws IOException {
//    Pdf2MetadataTransformer transformer = new Pdf2MetadataTransformer();
//      
//    InputStream is = new FileInputStream(new File("/home/korzen/Downloads/broccoli.pdf"));
//    transformer.transform(is);
//    is.close();
//          
//    System.out.println(transformer.toJson());
        
    Metadata2PdfTransformer transformer = new Metadata2PdfTransformer();
    
    DblpRecord record = new DblpRecord();
    record.setEe("ftp://ftp.math.tu-berlin.de/pub/Preprints/combi/Report-042-2004.pdf");
    
    transformer.transform(record);
          
    System.out.println(transformer.toJson());
  }
}
