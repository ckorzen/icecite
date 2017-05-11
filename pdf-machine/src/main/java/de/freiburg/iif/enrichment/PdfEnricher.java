package de.freiburg.iif.enrichment;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

import org.apache.commons.codec.binary.Base64OutputStream;
import org.apache.pdfbox.exceptions.COSVisitorException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentCatalog;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;

import de.freiburg.iif.enrichment.CitationsDetector.Citation;
import de.freiburg.iif.extraction.MetadataMatcher;
import de.freiburg.iif.extraction.references.ReferencesMetadataMatcher;
import de.freiburg.iif.model.PDPopup;

/**
 * Enriches the pdf with popups for each citation. The popups are shown 
 * on clicking a citation in free text. The popup contains the metadata of the 
 * clicked citation.
 * 
 * @author Claudius Korzen
 *
 */
public class PdfEnricher {  
  /** The MetadataMatcher to extract the references */
  protected MetadataMatcher matcher;
  /** The CitationsDetector */
  protected CitationsDetector citationsDetector;
  
  /** The constructor. */
  public PdfEnricher() {
    this.matcher = new ReferencesMetadataMatcher();
    this.citationsDetector = new CitationsDetector();
  }
     
  /**
   * Enriches the given pdf file.
   * 
   * @param doc the pdf file to enrich.
   * @throws Exception if something goes wrong on enriching.
   */
  public String enrich(InputStream stream, List<Citation> citations) throws IOException {
    try (ByteArrayOutputStream baos = new ByteArrayOutputStream(); 
        OutputStream os = new Base64OutputStream(baos, true, 0, null)) {
              
      // 1st inputstream.
      PDDocument doc = PDDocument.load(stream);
      try {
        PDDocumentCatalog catalog = doc.getDocumentCatalog(); 
        PDAcroForm form = catalog.getAcroForm();
        if (form == null) form = new PDAcroForm(doc);
        
        for (Citation citation : citations) {
          // Create a popup for each citation.
          PDPopup.create(doc, form, citation);
        }
      
        // Write back the acroForm.
        catalog.setAcroForm(form);
        // Save the document.
        doc.save(os);
      } catch (COSVisitorException e) {
        throw new IOException(e);
      } finally {
        doc.close();
      }
      return new String(baos.toByteArray());
    }
  }
}
