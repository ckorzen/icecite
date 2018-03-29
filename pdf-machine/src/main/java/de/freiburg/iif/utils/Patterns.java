package de.freiburg.iif.utils;

import java.util.regex.Pattern;

/**
 * The class Patterns, that holds all regular expressions for the application.
 * 
 * @author Claudius Korzen
 * 
 */
public final class Patterns {

  /**
   * Pattern for identifying reference anchors. Instead of "\d" (digit
   * character), "\w" (word character) is used to meet anchors like "[l]"
   * instead of "[1]" (resulting from extraction failures). The pattern will
   * find anchors like "[1]" and "1."
   */
  public static final Pattern REFERENCE_ANCHOR_PATTERN = Pattern
      .compile("(^\\[\\w{1,3}\\]|^1?\\d{1,2}\\.\\D)(.+)");

  /**
   * Pattern to identify lines, which ends with an characteristic string,
   * indicating that the following corresponds to the current line logically.
   * 
   * Consider ":", only if it follows after a non-digit.
   */
  public static final Pattern OPEN_LINE_END_PATTERN = Pattern
      .compile("(\\D:|\\W+and|\\W+an|\\W+of|\\W+In|"
          + "\\W+in|\\W+The|\\W+the|\\W+at|\\W+for|\\W+@|ated)\\s*$");

  /**
   * Pattern to identify lines, which start with an lowercased word.
   */
  public static final Pattern LOWERCASED_LINE_START_PATTERN = Pattern
      .compile("^[a-z\\s]{3,}");

  /**
   * Pattern to identify words that starts with an uppercased letter, followed
   * by at least one lowercased letter.
   */
  public static final Pattern UPPERCASED_WORD_PATTERN = 
    Pattern.compile("[A-Z]{1}\\p{Lower}{1,}[^A-Z]");

  /**
   * Pattern to find all words with length > 3 in a string.
   */
  public static final Pattern LONG_WORDS_PATTERN = Pattern
//      .compile("(^|\\s)[\\p{L}\\p{M}]{2,}");
    .compile("[A-Z]{0,1}[A-Za-z]{2,}");
  /**
   * Pattern to find the first punctuation mark or the first occurence of the
   * word "and" in a line. It must be preceded by at least 2 characters to
   * ignore abbreviations mark like "C.Korzen"
   */
  public static final Pattern FIRST_PUNCTUATION_MARK_PATTERN = Pattern
      .compile("(?<=\\S{2,})([\\.,;:“]| and)");

  /**
   * Pattern to detect the header of a bibliography.
   */
  public static final Pattern BIB_HEADER_PATTERN = Pattern.compile(
      "^\\(?[A-Za-z0-9]{0,3}(\\)|\\.)?\\s?("
          + "Reference|References|Bibliography)\\s?[:punct:]?\\s*$",
      Pattern.MULTILINE + Pattern.CASE_INSENSITIVE);
  
  /**
   * Pattern to detect the header of a bibliography.
   */
  public static final Pattern ABSTRACT_PATTERN = Pattern.compile(
      "^\\(?[A-Za-z0-9]{0,3}(\\)|\\.)?\\s?("
          + "Abstract|Kurzfassung)\\s?[:punct:]?\\s*",
      Pattern.MULTILINE + Pattern.CASE_INSENSITIVE);

  /**
   * Pattern to detect the first word in a line.
   */
  public static final Pattern FIRST_WORD_IN_LINE_PATTERN =
  // [Stra&F199] Strauss, W. & ==> "Strauss"
  // \\p{L}\\p{M} to detect diacritics.
      Pattern.compile("(^|\\s|\\.)([\\p{L}\\p{M}-]{2,}|\\d{4}\\D)");

  /**
   * Pattern to detect the year in a line. "-" must not be precede and must not
   * be follow.
   */
  public static final Pattern YEAR_PATTERN = Pattern
      .compile("(?<!-)(19|20)\\d{2}(?!-)");
  
  /**
   * Pattern to detect numbers in a line.
   */
  public static final Pattern NUMBERS_PATTERN = Pattern
      .compile("\\d{1,}");
  
  /**
   * Pattern to detect numbers in a line.
   */
  public static final Pattern LINE_STARTS_WITH_LOWERCASE_WORD_PATTERN = Pattern
      .compile("^([a-z]{3,})\\s");
}
