package de.freiburg.iif.extraction.stripper;

import java.io.File;
import java.io.IOException;
import java.util.Calendar;
import java.util.List;

import org.apache.jempbox.xmp.XMPMetadata;
import org.apache.jempbox.xmp.XMPSchemaDublinCore;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentCatalog;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.pdmodel.common.PDMetadata;

import de.freiburg.iif.model.HasMetadata;
import de.freiburg.iif.model.Region;

/**
 * The implementation of PdfExtraction using PdfBox.
 * 
 * @author Claudius Korzen
 */
public class PdfBoxStripper implements PdfStripper {

  @Override
  public List<Region> extractLines(File file, int startPage, int endPage,
    boolean splitLines) throws IOException {
//    File tmp = File.createTempFile("icecite-", "ra");
//    PDDocument doc = PDDocument.loadNonSeq(file, new RandomAccessFile(tmp, "rw"));
    PDDocument doc = PDDocument.load(file);
    
    try {
      // Check, if document is decrpyted.
      if (doc.isEncrypted()) {
        try {
          doc.decrypt("");
          doc.setAllSecurityToBeRemoved(true);
        } catch (Exception e) {
          throw new IOException("The document is encrypted, and can't be decrypted.", e);
        }
      }
          
      PdfBoxTextLineStripper stripper = new PdfBoxTextLineStripper(doc);
  
      // Don't abort on parsing errors.
      stripper.setForceParsing(true);
      // Extract only the textlines of first page.
      stripper.setStartPage(startPage);
      stripper.setEndPage(endPage);
      stripper.setSplitLine(splitLines);
  
      List<Region> lines = stripper.getLines();
      return lines;
    } finally {
      doc.close();
    }
  }

  @Override
  // TODO: Remove it.
    public
    List<Region> extractLines(PDDocument doc, int startPage, int endPage,
      boolean splitLines) throws IOException {
    PdfBoxTextLineStripper stripper = new PdfBoxTextLineStripper(doc);

    // Don't abort on parsing errors.
    stripper.setForceParsing(true);
    // Extract only the textlines of first page.
    stripper.setStartPage(startPage);
    stripper.setEndPage(endPage);
    stripper.setSplitLine(splitLines);

    List<Region> lines = stripper.getLines();        
    doc.close();

    return lines;
  }

  @Override
  public void importMetadata(File file, HasMetadata record, String outputDir)
    throws Exception {
    if (file != null && record != null) {
      PDDocument pdDoc = PDDocument.load(file);
      try {
        PDDocumentCatalog pdCat = pdDoc.getDocumentCatalog();
        PDDocumentInformation info = pdDoc.getDocumentInformation();
        
        Calendar cal = null;
        if (record.getYear() > 1) {
          cal = Calendar.getInstance();
          cal.clear();
          cal.set(Calendar.YEAR, record.getYear());
        }
        
        if (info != null) {
          info.setTitle(record.getTitle() != null ? record.getTitle() : "");
          if (cal != null) { info.setCreationDate(cal); }
          info.setCreator("icecite - www.icecite.com");
          info.setSubject(record.getAbstract() != null ? record.getAbstract() : "");
          if (record.getAuthors() != null && !record.getAuthors().isEmpty()) {
  //          System.out.println("Author: " + record.getAuthors());
  //          info.setAuthor(record.getAuthors().toString());
          } else {
            info.setAuthor("");
          }
        }
              
        // PDMetadata pdMetadata = pdCat.getMetadata();
        // if (pdMetadata != null) {
        XMPMetadata xmp = new XMPMetadata();
        // Use the widespread schema of Dublin Core.
        XMPSchemaDublinCore dcSchema = xmp.addDublinCoreSchema();
        
        dcSchema.setTitle(record.getTitle());
        if (record.getAuthors() != null && !record.getAuthors().isEmpty()) {
          for (String author : record.getAuthors()) {
  //          System.out.println("Creator: " + author);
            dcSchema.addCreator(author);
          }
        } else {
          // Add an empty creator, to delete possible existing authors.
          dcSchema.addCreator("");
        }
        dcSchema.setSource(record.getJournal());
        dcSchema.setDescription(record.getAbstract());
              
        // Set the date (i.e. only the year).
          
        if (cal != null) { dcSchema.addDate(cal); }
        
        PDMetadata metadataStream = new PDMetadata(pdDoc);
        metadataStream.importXMPMetadata(xmp);
        pdCat.setMetadata(metadataStream);
        if (outputDir != null) {
          // There is a output dir given. Store it there.
          pdDoc.save(outputDir + File.separatorChar + file.getName());
        } else {
          // Save the pdf file at its origin location.
          pdDoc.save(file.getAbsolutePath());
        }
      } finally {
        pdDoc.close();
      }
    }
  }
}
