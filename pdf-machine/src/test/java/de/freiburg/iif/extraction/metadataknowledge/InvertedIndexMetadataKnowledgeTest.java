package de.freiburg.iif.extraction.metadataknowledge;

import java.io.IOException;

import junit.framework.Assert;

import org.junit.Test;

import de.freiburg.iif.extraction.metadataknowledge.InvertedIndexMetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQuery;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge.MetadataKnowledgeQueryType;

/**
 * Tests for the methods in InvertedIndexMetadataKnowledge.
 * 
 * @author Claudius Korzen
 * 
 */
public class InvertedIndexMetadataKnowledgeTest {

  /**
   * Test the method prepareIndexUrl()
   * 
   * @throws IOException
   *           if creating the url for querying the index fails.
   */
  @Test
  public void testPrepareIndexUrl() throws IOException {
    InvertedIndexMetadataKnowledge mk = new InvertedIndexMetadataKnowledge();
    Assert.assertEquals(null, mk.prepareIndexUrl(null));

    MetadataKnowledgeQuery query = new MetadataKnowledgeQuery();
    query.add(MetadataKnowledgeQueryType.AUTHORS, "Obama Merkel Putin");

    Assert.assertEquals(InvertedIndexMetadataKnowledge.host + ":"
        + InvertedIndexMetadataKnowledge.port + "/?a=Obama Merkel Putin",
        mk.prepareIndexUrl(query).toString());

    query.add(MetadataKnowledgeQueryType.TITLE, "Mission impossible");

    Assert.assertEquals(InvertedIndexMetadataKnowledge.host + ":"
        + InvertedIndexMetadataKnowledge.port
        + "/?t=Mission impossible&a=Obama Merkel Putin",
        mk.prepareIndexUrl(query).toString());
  }
}
