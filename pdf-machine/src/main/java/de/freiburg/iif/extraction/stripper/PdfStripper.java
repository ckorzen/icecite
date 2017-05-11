package de.freiburg.iif.extraction.stripper;

import java.io.File;
import java.io.IOException;
import java.util.List;

import org.apache.pdfbox.pdmodel.PDDocument;

import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;

/**
 * The interface to the pdf extraction tool.
 * 
 * @author Claudius Korzen.
 * 
 */
public interface PdfStripper {
  /**
   * Extracts the textlines from the given pdf file.
   * 
   * @param file
   *          the pdf file to process.
   * @param startPage
   *          the start page for the extraction.
   * @param endPage
   *          the end page for the extraction.
   * @param splitLines
   *          flag to decide, if lines should be checked if they need to be
   *          splitted.
   * 
   * @return The list of lines in the given page-interval.
   * @throws IOException
   *           if the extraction fails.
   */
  // TODO: Use other type than "Region"?
  public List<Region> extractLines(File file, int startPage, int endPage,
    boolean splitLines) throws IOException;

  /**
   * Extracts the textlines from the given pdf file.
   * 
   * @param file
   *          the pdf file to process.
   * @param startPage
   *          the start page for the extraction.
   * @param endPage
   *          the end page for the extraction.
   * @param splitLines
   *          flag to decide, if lines should be checked if they need to be
   *          splitted.
   * @return The list of lines in the given page-interval.
   * @throws IOException
   *           if the extraction fails.
   */
  // TODO: Remove it.
  public List<Region> extractLines(PDDocument file, int startPage,
    int endPage, boolean splitLines) throws IOException;

  /**
   * Imports the given metadata as XMP into the given pdfFile.
   * 
   * @param file
   *          the file to import into.
   * @param record
   *          the metadata record to import.
   * @param outputDir
   *          the directory, where to save the file. If it is null, the file is
   *          saved at its origin location.
   * @throws Exception if importing the metadata fails. 
   */
  public void importMetadata(File file, HasMetadata record, String outputDir)
    throws Exception;
}
