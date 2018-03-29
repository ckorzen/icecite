package de.freiburg.iif.extraction;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import org.apache.pdfbox.pdmodel.PDDocument;

import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;

/**
 * The interface MetadataMatcher that defines a scheme for classes to match pdf
 * files to its referred record in a metadata knowledge.
 * 
 * @author Claudius Korzen
 * 
 */
public interface MetadataMatcher {
  /**
   * Matches the research paper given by the path to pdf file to the referred
   * record in the metadata knowledge base.
   * 
   * @param pdfFilePath
   *          the path of PDF file to process.
   * @param strict
   *          flag to specify the behavir, if metadata knowledge isn't
   *          available.
   * @param disableMK
   *          flag to switch on/off the metadata knowledge base.
   * @param minWaitInterval
   *          the minimal time interval to wait between two requests to the
   *          metdata knowledge.
   * @return the referred record of the metadata knowledge base.
   * @throws IOException
   *           if the matching fails.
   */
  public List<HasMetadata> match(String pdfFilePath, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException;

  /**
   * Matches the given pdf file to the referred record in the metadata knowledge
   * base.
   * 
   * @param file
   *          the PDF file to process.
   * @param strict
   *          flag to specify the behavior, if metadata knowledge isn't
   *          available.
   * @param disableMK
   *          flag to switch on/off the metadata knowledge base.
   * @param minWaitInterval
   *          the minimal time interval to wait between two requests to the
   *          metadata knowledge.
   * @return the referred record of the metadata knowledge base.
   * @throws IOException
   *           if the matching fails.
   */
  public List<HasMetadata> match(File file, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException;
  
  public List<HasMetadata> match(InputStream is, boolean strict,
      boolean disableMK, int minWaitInterval) throws IOException;
  
  /**
   * Matches the given pdf file to the referred record in the metadata knowledge
   * base.
   * 
   * @param doc
   *          the PDF file to process.
   * @param strict
   *          flag to specify the behavior, if metadata knowledge isn't
   *          available.
   * @param disableMK
   *          flag to switch on/off the metadata knowledge base.
   * @param minWaitInterval
   *          the minimal time interval to wait between two requests to the
   *          metadata knowledge.
   * @return the referred record of the metadata knowledge base.
   * @throws IOException
   *           if the matching fails.
   */
  public List<HasMetadata> match(PDDocument doc, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException;

  /**
   * Matches the given lines to the referred records in the metadata knowledge
   * base.
   * 
   * @param lines
   *          the lines to process.
   * @param strict
   *          flag to specify the behavir, if metadata knowledge isn't
   *          available.
   * @param disableMK
   *          flag to switch on/off the metadata knowledge base.
   * @param minWaitInterval
   *          the minimal time interval to wait between two requests to the
   *          metadata knowledge.
   * @return the referred record of the metadata knowledge base.
   * @throws IOException
   *           if the matching fails.
   */
  public List<HasMetadata> match(List<Region> lines, boolean strict,
    boolean disableMK, int minWaitInterval) throws IOException;

  /**
   * Returns an array of runtimes
   * 
   * @return the array of runtimes.
   */
  public long[] getRuntimes();

  /**
   * Returns the extracted fulltext.
   * 
   * @return the extracted fulltext.
   */
  public String getFulltext();
  
  /**
   * Returns the extracted fulltext.
   * 
   * @return the extracted fulltext.
   */
  public List<Region> getLines();
}
