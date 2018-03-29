part of pdf_resolver;

abstract class PdfResolverInterface {
  /**
   * Search for a pdf in web, related to given entry. The result contains the 
   * entry, the references and the pdf (as blob) in a map.
   */
  Future<Map> meta2Pdf(LibraryEntry entry);
  
  /**
   * Match the given entry against a digital library. The result contains the 
   * enriched entry and the references in a map.
   */
  Future<Map> pdf2Meta(LibraryEntry entry, Blob blob);
}