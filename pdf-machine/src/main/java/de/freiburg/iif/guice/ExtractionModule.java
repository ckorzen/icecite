package de.freiburg.iif.guice;

import org.apache.commons.logging.Log;

import com.google.inject.AbstractModule;
import com.google.inject.Singleton;

import de.freiburg.iif.extraction.MetadataMatcher;
import de.freiburg.iif.extraction.metadata.DocumentMetadataMatcher2;
import de.freiburg.iif.extraction.metadataknowledge.InvertedIndexMetadataKnowledge;
import de.freiburg.iif.extraction.metadataknowledge.MetadataKnowledge;
import de.freiburg.iif.extraction.stripper.PdfBoxStripper;
import de.freiburg.iif.extraction.stripper.PdfStripper;

/**
 * The class GuiceServerModule.
 * 
 * @author Claudius Korzen
 */
public class ExtractionModule extends AbstractModule {

  @Override
  protected void configure() {	  
    bind(Log.class).toProvider(LogProvider.class).in(Singleton.class);
    bind(MetadataMatcher.class).to(DocumentMetadataMatcher2.class);
    bind(MetadataKnowledge.class).to(InvertedIndexMetadataKnowledge.class);
    bind(PdfStripper.class).to(PdfBoxStripper.class);
  }
}
