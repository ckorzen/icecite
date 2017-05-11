package de.freiburg.iif.utils;

import static de.freiburg.iif.utils.Patterns.BIB_HEADER_PATTERN;

import java.util.regex.Matcher;

/**
 * The helper class Semantics, that provides methods to understand the semantics
 * of strings.
 * 
 * @author Claudius Korzen
 * 
 */
public class Semantics {

  /**
   * Checks, if the given text is a bibliography header.
   * 
   * @param text the text to analyze.
   * @return true, if the given text is a bibliography header. false otherwise.
   */
  public static final boolean isBibliographyHeader(String text) {
    if (text != null) {
      // Remove all whitespaces to detect bibliography headers like "RE F ER ENC ES"
      text = text.replaceAll("\\s", "");
      Matcher m = BIB_HEADER_PATTERN.matcher(text);
      return m.matches();
    }
    return false;
  }
}
