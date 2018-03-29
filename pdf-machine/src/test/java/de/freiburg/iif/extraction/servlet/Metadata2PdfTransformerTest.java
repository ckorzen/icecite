package de.freiburg.iif.extraction.servlet;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import junit.framework.Assert;

import org.junit.Before;
import org.junit.Test;

import de.freiburg.iif.extraction.servlet.Metadata2PdfTransformer;
import de.freiburg.iif.extraction.servlet.Metadata2PdfTransformer.Publisher;
import de.freiburg.iif.model.DblpRecord;

/**
 * Test class for Metadata2PdfTransformerTest.
 * 
 * @author Claudius Korzen
 */
public class Metadata2PdfTransformerTest {
  /** The transformer to test */
  private Metadata2PdfTransformer transformer;
  /** The first record to test */
  private DblpRecord record1;
  /** The second record to test */
  private DblpRecord record2;
  /** The third record to test */
  private DblpRecord record3;
  /** The fourth record to test */
  private DblpRecord record4;
  /** The fifth record to test */
  private DblpRecord emptyRecord;
  
  /** Prepares the testing enviroment */
  @Before
  public void prepare() {
    transformer = new Metadata2PdfTransformer();
    
    record1 = new DblpRecord();
    record1.setTitle("Broccoli: Semantic Full-Text Search at your Fingertips");
    record1.setJournal("CoRR");
    record1.setYear(2012);
    record1.setEe("http://arxiv.org/abs/1207.2615");
    List<String> authors1 = new ArrayList<>();
    authors1.add("Hannah Bast");
    authors1.add("Florian Bäurle");
    authors1.add("Björn Buchhold");
    authors1.add("Elmar Haussmann");
    record1.setAuthors(authors1);
    
    record2 = new DblpRecord();
    record2.setTitle("Accurate Information Extraction from Research Papers using Conditional Random Fields");
    record2.setJournal("HLT-NAACL");
    record2.setYear(2004);
    record2.setEe("http://acl.ldc.upenn.edu/hlt-naacl2004/main/pdf/176_Paper.pdf");
    List<String> authors2 = new ArrayList<>();
    authors2.add("Fuchun Peng");
    authors2.add("Andrew McCallum");
    record2.setAuthors(authors2);
    
    record3 = new DblpRecord();
    record3.setTitle("Analytic displacement mapping using hardware tessellation");
    record3.setJournal("ACM Trans. Graph.");
    record3.setYear(2013);
    record3.setEe("http://doi.acm.org/10.1145/2487228.2487234");
    List<String> authors3 = new ArrayList<>();
    authors3.add("Matthias Niessner");
    authors3.add("Charles T. Loop");
    record3.setAuthors(authors3);
    
    record4 = new DblpRecord();
    record4.setTitle("Academic users' interactions with ScienceDirect in search tasks: Affective and cognitive behaviors");
    record4.setJournal("Inf. Process. Manage.");
    record4.setYear(2008);
    record4.setEe("http://dx.doi.org/10.1016/j.ipm.2006.10.007");
    List<String> authors4 = new ArrayList<>();
    authors4.add("Carol Tenopir");
    authors4.add("Peiling Wang");
    record4.setAuthors(authors4);
    
    emptyRecord = new DblpRecord();
  }
  
  /** Test transform() */
  @Test
  public void testTransform() {
    transformer.transform(record1);
    Assert.assertTrue(transformer.base64Data.startsWith("JVBERi0xLjUK"));
    transformer.transform(record2);
    Assert.assertTrue(transformer.base64Data.startsWith("JVBERi0xLjMK"));
    transformer.transform(record3);
    Assert.assertTrue(transformer.base64Data.startsWith("JVBERi0xLjMN"));
    transformer.transform(record4);
    Assert.assertTrue(transformer.base64Data.startsWith("JVBERi0xLjUN"));
    transformer.transform(emptyRecord);
    Assert.assertEquals(null, transformer.base64Data);
    transformer.transform(null);
    Assert.assertEquals(null, transformer.base64Data);
  }
  
  /** Test resolveUrl */
  @Test
  public void testResolveUrl() {
    Assert.assertEquals("http://arxiv.org/abs/1207.2615", transformer.resolveUrl(record1));
    Assert.assertEquals("http://acl.ldc.upenn.edu/hlt-naacl2004/main/pdf/176_Paper.pdf", transformer.resolveUrl(record2));
    Assert.assertEquals("http://dl.acm.org/citation.cfm?doid=2487228.2487234", transformer.resolveUrl(record3));
    Assert.assertEquals("http://linkinghub.elsevier.com/retrieve/pii/S0306457306001658", transformer.resolveUrl(record4));
    Assert.assertEquals(null, transformer.resolveUrl(emptyRecord));
    Assert.assertEquals(null, null);
  }
  
  /** Test guessPublisher */
  @Test
  public void testGuessPublisher() {
    Assert.assertEquals(Publisher.ARXIV, transformer.guessPublisher("http://arxiv.org/abs/1207.2615"));
    Assert.assertEquals(Publisher.DIRECT_LINKED, transformer.guessPublisher("http://acl.ldc.upenn.edu/hlt-naacl2004/main/pdf/176_Paper.pdf"));
    Assert.assertEquals(Publisher.ACM, transformer.guessPublisher("http://dl.acm.org/citation.cfm?doid=2487228.2487234"));
    Assert.assertEquals(Publisher.NONE, transformer.guessPublisher("http://linkinghub.elsevier.com/retrieve/pii/S0306457306001658"));
    Assert.assertEquals(Publisher.NONE, transformer.guessPublisher(null));
    Assert.assertEquals(null, null);
  }
  
  /** Test guessDownloadUrl() */
  @Test
  public void testGuessDownloadUrl() {
    Assert.assertEquals("http://arxiv.org/pdf/1207.2615", transformer.guessDownloadUrl("http://arxiv.org/abs/1207.2615"));
    Assert.assertEquals(record2.getEe(), transformer.guessDownloadUrl(record2.getEe()));
    Assert.assertEquals("http://portal.acm.org/ft_gateway.cfm?id=2487234&type=pdf", transformer.guessDownloadUrl("http://dl.acm.org/citation.cfm?doid=2487228.2487234"));
    Assert.assertEquals("http://link.springer.com/chapter/10.1007/978-3-642-03456-5_24/fulltext.pdf", transformer.guessDownloadUrl("http://link.springer.com/chapter/10.1007/978-3-642-03456-5_24"));
  }
  
  /** Test guessAcmDownloadUrl() */
  @Test
  public void testGuessACMDownloadUrl() {
    Assert.assertEquals("http://portal.acm.org/ft_gateway.cfm?id=2487234&type=pdf", transformer.guessACMDownloadUrl("http://dl.acm.org/citation.cfm?doid=2487228.2487234"));
  }
  
  /** Test guessArxivDownloadUrl() */
  @Test
  public void testGuessArxivDownloadUrl() {
    Assert.assertEquals("http://arxiv.org/pdf/1207.2615", transformer.guessArxivDownloadUrl("http://arxiv.org/abs/1207.2615"));
  }
  
  /** Test guessSpringerDownloadUrl() */
  @Test
  public void testGuessSpringerDownloadUrl() {
    Assert.assertEquals("http://link.springer.com/chapter/10.1007/978-3-642-03456-5_24/fulltext.pdf", transformer.guessSpringerDownloadUrl("http://link.springer.com/chapter/10.1007/978-3-642-03456-5_24"));
  }
  
  /** Test guessDirectDownloadUrl() */
  @Test
  public void testGuessDirectDownloadUrl() {
    // download url should be equal to ee.
    Assert.assertEquals(
        transformer.guessDirectDownloadUrl(record2.getEe()), record2.getEe());
  }
  
  /** Test guessDownloadUrlViaGoogle() */
  @Test
  public void testGuessDownloadUrlViaGoogle() {
    Assert.assertEquals("http://ad-publications.informatik.uni-freiburg.de/JIWES_semanticsearch_BBBH_2013.pdf", transformer.guessDownloadUrlViaGoogle(record1));
    Assert.assertEquals("http://www.cs.umass.edu/~mccallum/papers/hlt2004.pdf", transformer.guessDownloadUrlViaGoogle(record2));
    Assert.assertEquals("http://research.microsoft.com/en-us/um/people/cloop/TOG2013.pdf",  transformer.guessDownloadUrlViaGoogle(record3));
    Assert.assertEquals("http://web.utk.edu/~peilingw/vita.pdf",  transformer.guessDownloadUrlViaGoogle(record4));
    Assert.assertEquals(null, transformer.guessDownloadUrlViaGoogle(emptyRecord));
    Assert.assertEquals(null, transformer.guessDownloadUrlViaGoogle(null));
  }
  
  /** Test dcreateGoogleQueryUrl() */
  @Test
  public void testCreateGoogleQueryUrl() {
    Assert.assertEquals("http://www.google.com/search?q=Broccoli%3A+Semantic+Full-Text+Search+at+your+Fingertips%2C+%5BHannah+Bast%2C+Florian+B%C3%A4urle%2C+Bj%C3%B6rn+Buchhold%2C+Elmar+Haussmann%5D+filetype%3Apdf", transformer.createGoogleQueryUrl(record1));
    Assert.assertEquals("http://www.google.com/search?q=Accurate+Information+Extraction+from+Research+Papers+using+Conditional+Random+Fields%2C+%5BFuchun+Peng%2C+Andrew+McCallum%5D+filetype%3Apdf", transformer.createGoogleQueryUrl(record2));
    Assert.assertEquals("http://www.google.com/search?q=Analytic+displacement+mapping+using+hardware+tessellation%2C+%5BMatthias+Niessner%2C+Charles+T.+Loop%5D+filetype%3Apdf", transformer.createGoogleQueryUrl(record3));
    Assert.assertEquals("http://www.google.com/search?q=Academic+users%27+interactions+with+ScienceDirect+in+searchtasks%3A+Affective+and+cognitive+behaviors%2C+%5BCarol+Tenopir%2C+Peiling+Wang%5D+filetype%3Apdf", transformer.createGoogleQueryUrl(record4));
    Assert.assertEquals(null, transformer.createGoogleQueryUrl(emptyRecord));
  }
  
  /** 
   * Test parseGoogleResult() 
   * 
   * @throws IOException if parsing fails.
   * */
  @Test
  public void testParseGoogleResult() throws IOException {
    Assert.assertEquals("http://ad-publications.informatik.uni-freiburg.de/JIWES_semanticsearch_BBBH_2013.pdf", transformer.parseGoogleResult("http://www.google.com/search?q=Broccoli%3A+Semantic+Full-Text+Search+at+your+Fingertips%2C+%5BHannah+Bast%2C+Florian+B%C3%A4urle%2C+Bj%C3%B6rn+Buchhold%2C+Elmar+Haussmann%5D+filetype%3Apdf"));
    Assert.assertEquals("http://www.cs.umass.edu/~mccallum/papers/hlt2004.pdf", transformer.parseGoogleResult("http://www.google.com/search?q=Accurate+Information+Extraction+from+Research+Papers+using+Conditional+Random+Fields%2C+%5BFuchun+Peng%2C+Andrew+McCallum%5D+filetype%3Apdf"));
    Assert.assertEquals("http://research.microsoft.com/en-us/um/people/cloop/TOG2013.pdf", transformer.parseGoogleResult("http://www.google.com/search?q=Analytic+displacement+mapping+using+hardware+tessellation%2C+%5BMatthias+Niessner%2C+Charles+T.+Loop%5D+filetype%3Apdf"));
    Assert.assertEquals("http://web.utk.edu/~peilingw/vita.pdf", transformer.parseGoogleResult("http://www.google.com/search?q=Academic+users%27+interactions+with+ScienceDirect+in+searchtasks%3A+Affective+and+cognitive+behaviors%2C+%5BCarol+Tenopir%2C+Peiling+Wang%5D+filetype%3Apdf"));
    Assert.assertEquals(null, transformer.parseGoogleResult(null));
  }
  
  /** Test download() */
  @Test
  public void testDownload() {
//    Assert.assertTrue(transformer.download("http://ad-publications.informatik.uni-freiburg.de/JIWES_semanticsearch_BBBH_2013.pdf").startsWith("JVBERi0xLjUK"));
//    Assert.assertTrue(transformer.download("http://www.cs.umass.edu/~mccallum/papers/hlt2004.pdf").startsWith("JVBERi0xLjMK"));
//    Assert.assertTrue(transformer.download("http://research.microsoft.com/en-us/um/people/cloop/TOG2013.pdf").startsWith("JVBERi0xLjUK"));
//    Assert.assertTrue(transformer.download("http://web.utk.edu/~peilingw/vita.pdf").startsWith("JVBERi0xLjUNJeL"));
//    Assert.assertEquals(null, transformer.download(null));
  }
}
