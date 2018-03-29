package de.freiburg.iif.extraction;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import org.apache.pdfbox.pdmodel.PDDocument;

import de.freiburg.iif.enrichment.CitationsDetector;
import de.freiburg.iif.enrichment.CitationsDetector.Citation;
import de.freiburg.iif.extraction.metadata.DocumentMetadataMatcher2;
import de.freiburg.iif.extraction.references.ReferencesMetadataMatcher;
import de.freiburg.iif.extraction.stripper.PdfBoxStripper;
import de.freiburg.iif.extraction.stripper.PdfStripper;
import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;

/**
 * Class to extract the metadata and the references from scientific research
 * papers.
 * 
 * @author Claudius Korzen
 * 
 */
public class PaperMatcher {
  /** The pdf extraction */
  protected PdfStripper pdfExtraction;
  /** The matcher for the metadata */
  protected MetadataMatcher metadataMatcher;
  /** The matcher for the references */
  protected MetadataMatcher referencesMatcher;
  /** The citations detector */
  protected CitationsDetector citationsDetector;
  /** The matched metadata */
  protected HasMetadata metadata;
  /** The matched reference */
  protected List<HasMetadata> references;
  /** The fulltext */
  protected String fulltext;
  /** The extracted lines */
  protected List<Region> lines;
  /** The extracted citations */
  protected List<Citation> citations;

  /**
   * The constructor.
   */
  public PaperMatcher() {
    this.pdfExtraction = new PdfBoxStripper();
    this.metadataMatcher = new DocumentMetadataMatcher2();
    this.referencesMatcher = new ReferencesMetadataMatcher();
    this.citationsDetector = new CitationsDetector();
  }

  public void match(InputStream is, boolean matchMetadata,
    boolean matchReferences, boolean extractCitations) throws IOException {
    match(PDDocument.load(is), matchMetadata, matchReferences, extractCitations);
  }
  /**
   * Matches the given pdfFile.
   * 
   * @param pdfFile
   *          the file to match.
   * @param matchMetadata
   *          true, if the metadata should be matched.
   * @param matchReferences
   *          true, if the references should be matched.
   * @throws IOException
   *           if the matching process fails.
   */
  public void match(PDDocument doc, boolean matchMetadata,
    boolean matchReferences, boolean extractCitations) throws IOException {
    if (matchMetadata || matchReferences) {
      if (doc != null) {
        // If references shouldn't be matched, extract only the first page.
        int endPage = matchReferences ? Integer.MAX_VALUE : 1;
        setLines(pdfExtraction.extractLines(doc, 1, endPage, true));

        if (matchMetadata) {
          List<HasMetadata> records = metadataMatcher.match(getLines(), false, false, 0);
          if (records != null && records.size() > 0) {
            setMetadata(records.get(0));
          }
        }
        if (matchReferences) { 
          setReferences(referencesMatcher.match(getLines(), false, false, 0));
          setFulltext(referencesMatcher.getFulltext());
        }
        if (extractCitations) {
          setCitations(citationsDetector.detect(getReferences(), getLines()));
        }
      }
    }
  }

  /**
   * Returns the metadata.
   * 
   * @return the metadata.
   */
  public HasMetadata getMetadata() {
    return metadata;
  }

  /**
   * Sets the metadata.
   * 
   * @param metadata
   *          the metadata to set.
   */
  protected void setMetadata(HasMetadata metadata) {
    this.metadata = metadata;
  }

  /**
   * Returns the references.
   * 
   * @return the references.
   */
  public List<HasMetadata> getReferences() {
    return references;
  }

  /**
   * Sets the references.
   * 
   * @param references
   *          the references to set.
   */
  protected void setReferences(List<HasMetadata> references) {
    this.references = references;
  }

  /**
   * Returns the fulltext.
   * 
   * @return the fulltext.
   */
  public String getFulltext() {
    return fulltext;
  }

  /**
   * Sets the fulltext.
   * 
   * @param fulltext
   *          the fulltext to set.
   */
  protected void setFulltext(String fulltext) {
    this.fulltext = fulltext;
  }
  
  /**
   * Sets the extracted lines.
   * 
   * @param lines the extracted lines.
   */
  protected void setLines(List<Region> lines) {
    this.lines = lines;
  }
  
  /**
   * Returns the extracted lines.
   * 
   * @return the extracted lines.
   */
  public List<Region> getLines() {
    return lines;
  }
  
  /**
   * Sets the extracted citations.
   * 
   * @param citations the extracted citations.
   */
  protected void setCitations(List<Citation> citations) {
    this.citations = citations;
  }
  
  /**
   * Returns the extracted citations.
   * 
   * @return the extracted citations.
   */
  public List<Citation> getCitations() {
    return citations;
  }
}
