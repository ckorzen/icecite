package de.freiburg.iif.extraction.title;

import java.io.IOException;

import org.junit.Test;

/**
 * Test-class to test the methods of DocumentMetadataMatcher.
 * 
 * @author Claudius Korzen
 */
public class DocumentMetadataMatcherTest {
//  /** The injector **/
//  private static Injector inj = Guice.createInjector(new ExtractionModule());
//  /** The implementation of metadata extraction **/
//  private static MetadataMatcher mm = inj.getInstance(MetadataMatcher.class);
//  /** The metadata knowledge */
//  private final MetadataKnowledge mk = inj
//      .getInstance(MetadataKnowledge.class);

  /**
   * Test something
   * 
   * @throws Exception
   *           if something fails.
   */
  @Test
  public void test() throws Exception {
    // URL myURL = new
    // URL("http://scholar.google.de/scholar?hl=de&q=test&btnG=&lr=");
    // URLConnection urlConn = myURL.openConnection();
    // // urlConn.addRequestProperty("Accept",
    // "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
    // // urlConn.addRequestProperty("Accept-Encoding", "gzip,deflate,sdch");
    // // urlConn.addRequestProperty("Accept-Language",
    // "de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4");
    // // urlConn.addRequestProperty("Cache-Control", "max-age=0");
    // // urlConn.addRequestProperty("Connection", "keep-alive");
    // // urlConn.addRequestProperty("Host", "scholar.google.de");
    // // urlConn.addRequestProperty("Referer", "http://scholar.google.de/");
    // urlConn.addRequestProperty("User-Agent",
    // "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36");
    // // urlConn.addRequestProperty("X-Chrome-Variations",
    // "COW1yQEIiLbJAQictskBCKa2yQEIqLbJAQiptskBCLi2yQEIwbbJAQj9g8oBCJiEygEIqYXKAQjEhcoBCNGFygE=");
    //
    // urlConn.connect();
    //
    // BufferedReader br = new BufferedReader(new
    // InputStreamReader(urlConn.getInputStream()));
    //
    // String line;
    // while ((line = br.readLine()) != null) {
    // System.out.println(line);
    // }
    //
    // String headerName=null;
    // for (int i=0; (headerName = urlConn.getHeaderFieldKey(i))!=null; i++) {
    // System.out.println(headerName);
    // if (headerName.equals("Set-Cookie")) {
    // String cookie = urlConn.getHeaderField(i);
    // String[] cookieElements = cookie.split(";");
    // for (String element : cookieElements) {
    // System.out.println(element);
    // }
    // }
    // }
    //
    // // String USER_DIR = System.getProperty("user.dir");
    // // /** The base directory */
    // // String BASE_DIR =
    // // USER_DIR + "/src/test/resources/de/freiburg/iif/pdfextraction";
    // // /** The pdf directory */
    // // String PDF_DIR = BASE_DIR + "/pdfs/metadaten_testcases";
    // // File pdfDir = new File(PDF_DIR);
    // //
    // // File pdfFile = new File(PDF_DIR + File.separatorChar +
    // "1743-8977-5-4ASIA-Pakistan.pdf");
    // //// mm.match(pdfFile, false, false, 0);
    // //
    // // PDDocument doc = PDDocument.load(pdfFile);
    // // DocumentBuilderFactory f = DocumentBuilderFactory.newInstance();
    // // DocumentBuilder builder = f.newDocumentBuilder();
    // //
    // // String xml = "<metadata><title>MAN</title></metadata>";
    // //
    // // PDMetadata metadata1 = doc.getDocumentCatalog().getMetadata();
    // // if(metadata1 != null) {
    // // System.out.println(metadata1.getInputStreamAsString());
    // // }
    // //
    // // Document xmpDoc = builder.parse(new
    // ByteArrayInputStream(xml.getBytes()));
    // // PDMetadata metadata = new PDMetadata(doc);
    // // metadata.importXMPMetadata(new XMPMetadata(xmpDoc));
    // // PDDocumentCatalog cat = doc.getDocumentCatalog();
    // // cat.setMetadata(metadata);
    // // doc.save(pdfFile.getAbsolutePath());
    // //
    // //
    // //// for (File pdfFile : pdfDir.listFiles()) {
    // //// System.out.println(pdfFile);
    // //// mm.match(pdfFile);
    // //// }
    // //
    // //// PDFTextStripper stripper = new PDFTextStripper();
    // //// System.out.println(stripper.getText(PDDocument.load(pdfFile)));
    // //
    // //// List<HasMetadata> list = mk.query(MetadataKnowledgeQueryType.TITLE,
    // "hygroscopicity of diesel aerosols");
    // //// System.out.println(list.get(0));
  }

  @Test
  public void http() throws IOException {
//    org.apache.pdfbox.io.RandomAccess ra = new RandomAccessFile(file, mode);
//    GoogleScholarMetadataKnowledge g = new GoogleScholarMetadataKnowledge(null);
//    g.queryGoogleScholar(URLEncoder.encode("Maßnahmen zur Begrenzung der latenten Betriebsgefahr von großen Dieselmotoren (über 2, 25 MW) auf Schiffen ", "UTF-8"));
  }
}
