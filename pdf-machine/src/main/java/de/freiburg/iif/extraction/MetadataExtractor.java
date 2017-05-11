package de.freiburg.iif.extraction;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.List;
import java.util.zip.DataFormatException;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.pdfbox.pdmodel.PDDocument;

import com.google.inject.Guice;
import com.google.inject.Injector;

import de.freiburg.iif.extraction.stripper.PdfStripper;
import de.freiburg.iif.guice.ExtractionModule;
import de.freiburg.iif.model.HasMetadata;

/**
 * Class MetadataExtractor providing an interface to start the metadata
 * extraction from pdf files via the command line.
 * 
 * @author Claudius Korzen
 * 
 */
public class MetadataExtractor {
  /** The injector **/
  private static Injector inj = Guice.createInjector(new ExtractionModule());
  /** The implementation of metadata extraction **/
  private static MetadataMatcher mm = inj.getInstance(MetadataMatcher.class);
  /** The implementation of pdf extraction **/
  private static PdfStripper ex = inj.getInstance(PdfStripper.class);

  /** Option to define a directory (containing several pdf files) to process */
  private static final String OPTION_DISABLE_MK = "mk";
  /** Decription of option to define a directory */
  private static final String OPTION_DISABLE_MK_DESC =
      "disable the metadata knowledge.";

  /** Option to force the metadata extraction. */
  private static final String OPTION_STRICT = "s";
  /** Description of option to force the metadata extraction. */
  private static final String OPTION_STRICT_DESC =
      "Strict mode. Don't provide "
          + "extracted data, if the server of metadata knowledge isn't available "
          + "or if the metadata knowledge doesn't contains a related record.";

  /** Option to define an output directory. */
  private static final String OPTION_OUTPUT_DIR = "o";
  /** Description of option to define an output directory. */
  private static final String OPTION_OUTPUT_DIR_DESC = "The output directory.";

  /**
   * Option to extract the name of a conference from directory names (as claimed
   * by MAN)
   */
  private static final String OPTION_EXTRACT_CONF_DIR = "c";
  /** Decription of option to extract the name of a conference from directories */
  private static final String OPTION_EXTRACT_CONF_DIR_DESC =
      "extract conference names from directory names";

  /**
   * Option to extract the name of a conference from directory names (as claimed
   * by MAN)
   */
  private static final String OPTION_RECURSIVE = "r";
  /** Decription of option to extract the name of a conference from directories */
  private static final String OPTION_RECURSIVE_DESC = "recursive mode";

  /**
   * Option to define a minimal time interval to wait between two requests to
   * the metadata knowledge..
   */
  private static final String OPTION_MIN_WAIT_INTERVAL = "t";
  /** Decription of option to extract the name of a conference from directories */
  private static final String OPTION_MIN_WAIT_INTERVAL_DESC =
      "the minimal time interval to wait before sending a request to Google Scholar (in ms)";

  /**
   * Main executable method to extract metadata from pdf files.
   * 
   * @param args
   *          the command line arguments.
   */
  public static void main(String[] args) {
    Options options = new Options();
    options.addOption(OPTION_STRICT, false, OPTION_STRICT_DESC);
    options.addOption(OPTION_DISABLE_MK, false, OPTION_DISABLE_MK_DESC);
    options.addOption(OPTION_OUTPUT_DIR, true, OPTION_OUTPUT_DIR_DESC);
    // Define the following option explicitly to allow an optional arg.
    Option option =
        new Option(OPTION_EXTRACT_CONF_DIR, true, OPTION_EXTRACT_CONF_DIR_DESC);
    option.setOptionalArg(true);
    options.addOption(option);
    options.addOption(OPTION_RECURSIVE, false, OPTION_RECURSIVE_DESC);
    options.addOption(OPTION_MIN_WAIT_INTERVAL, true,
        OPTION_MIN_WAIT_INTERVAL_DESC);

    // Parse the command line arguments.
    CommandLine cmd = parseArguments(args, options);
    if (cmd == null || cmd.getArgs().length < 1) {
      // printUsage(applicationName, options, System.out);
      printHelp(options, 80, "Help", "End of Help", 5, 3, true, System.out);
      System.exit(1);
    }

    try {
      processPath(cmd.getArgs()[0], cmd);
    } catch (IOException io) {
      Throwable cause = io.getCause();
      if (cause instanceof DataFormatException) {
        System.out.println("An error occurred: corrupt stream detected");
      }
    } catch (Exception e) {
      System.err.println(cmd.getArgs()[0] + ": an error occurred: "
          + e.getMessage());
      e.printStackTrace();
    }
  }

  /**
   * Parses the command line arguments.
   * 
   * @param args
   *          the command line arguments.
   * @param options
   *          the command-line options.
   * @return the parsed command line arguments.
   */
  private static CommandLine parseArguments(String[] args, Options options) {
    CommandLine cmd = null;
    if (args != null && args.length > 0) {
      CommandLineParser parser = new GnuParser();
      try {
        cmd = parser.parse(options, args);
      } catch (ParseException e) {
        System.err.println("An error occurred: " + e.getMessage());
        return null;
      }
    }
    return cmd;
  }

  /**
   * Print usage information to provided OutputStream.
   * 
   * @param applicationName
   *          Name of application to list in usage.
   * @param options
   *          Command-line options to be part of usage.
   * @param out
   *          OutputStream to which to write the usage information.
   */
  @SuppressWarnings("unused")
  private static void printUsage(final String applicationName,
    final Options options, final OutputStream out) {

    try (PrintWriter writer = new PrintWriter(out)) {
      final HelpFormatter usageFormatter = new HelpFormatter();
      usageFormatter.printUsage(writer, 80, applicationName, options);
      writer.flush();
    }
  }

  /**
   * Write "help" to the provided OutputStream.
   * 
   * @param options
   *          command-line options to be part of usage.
   * @param rowWidth
   *          the number of characters to be displayed on each line
   * @param header
   *          the banner to display at the beginning of the help
   * @param footer
   *          the banner to display at the end of the help
   * @param spacesBeforeOption
   *          the number of characters of padding to be prefixed to each line
   * @param spacesBeforeOptionDescription
   *          the number of characters of padding to be prefixed to each
   *          description line
   * @param displayUsage
   *          whether to print an automatically generated usage statement
   * @param out
   *          outputStream to which to write the usage information.
   */
  private static void printHelp(final Options options, final int rowWidth,
    final String header, final String footer, final int spacesBeforeOption,
    final int spacesBeforeOptionDescription, final boolean displayUsage,
    final OutputStream out) {

    final String cmdLineSyntax = "java -jar <jarfile-name>.jar <dir|file>";
    try (PrintWriter writer = new PrintWriter(out)) {
      final HelpFormatter helpFormatter = new HelpFormatter();
      helpFormatter.printHelp(writer, rowWidth, cmdLineSyntax, header, options,
          spacesBeforeOption, spacesBeforeOptionDescription, footer,
          displayUsage);
      writer.flush();
    }
  }

  /**
   * Processes the given path.
   * 
   * @param path
   *          the path to process.
   * @param cmd
   *          the parsed arguments of the command line.
   * @throws Exception
   *           if something went wrong.
   */
  private static void processPath(String path, CommandLine cmd)
    throws Exception {
    if (path == null || path.isEmpty()) { throw new IOException(
        "Path must be non-empty"); }

    File file = new File(path);
    if (!file.exists()) { throw new IOException("Path doesn't exist"); }

    if (file.isFile()) {
      if (!file.getName().toLowerCase().trim().endsWith(".pdf")) { throw new IOException(
          "Path doesn't point to a pdf file"); }
      processFile(file, cmd, null);
    } else if (file.isDirectory()) {
      processDirectory(file, file, cmd);
    }
  }

  /**
   * Processes the directory, given by filePath.
   * 
   * @param dir
   *          the directory.
   * @param baseDir
   *          the parent directory defined by the user.
   * @param cmd
   *          the parsed command line.
   */
  private static void
    processDirectory(File dir, File baseDir, CommandLine cmd) {
    boolean recursive = cmd.hasOption(OPTION_RECURSIVE);
    boolean extractConfFromDirName = cmd.hasOption(OPTION_EXTRACT_CONF_DIR);
    String defaultConf = cmd.getOptionValue(OPTION_EXTRACT_CONF_DIR);
    if (extractConfFromDirName && defaultConf == null) {
      defaultConf = extractConferenceName(dir, baseDir);
    }

    for (File file : dir.listFiles()) {      
      if (recursive && file.isDirectory()) {
        processDirectory(file, baseDir, cmd);
      } else if (file.isFile()) {
        boolean isPdf = file.getName().toLowerCase().endsWith("pdf");
        if (isPdf) {
          try {
            processFile(file, cmd, defaultConf);
          } catch (IOException io) {
            Throwable cause = io.getCause();
            if (cause instanceof DataFormatException) {
              System.out.println("An error occurred: corrupt stream detected");
            }
          } catch (Exception e) {
            System.err.println(cmd.getArgs()[0] + ": an error occurred: "
                + e.getMessage());
            e.printStackTrace();
          }
        }
      }
    }
  }

  /**
   * Processes the given file.
   * 
   * @param file
   *          the file to process.
   * @param cmd
   *          the parsed arguments of command line.
   * @param defaultConf
   *          the default conference name, if any.
   * @throws Exception
   *           if matching fails.
   */
  private static void processFile(File file, CommandLine cmd,
    String defaultConf) throws Exception {
    String outputDir = cmd.getOptionValue(OPTION_OUTPUT_DIR);
    boolean strict = cmd.hasOption(OPTION_STRICT);
    boolean disableMK = cmd.hasOption(OPTION_DISABLE_MK);
    String minWaitIntervalStr = cmd.getOptionValue(OPTION_MIN_WAIT_INTERVAL);
    int minWaitInterval = 10000;

    if (minWaitIntervalStr != null) {
      minWaitInterval = Integer.parseInt(minWaitIntervalStr);
    }

    System.out.print(file.getAbsolutePath() + "...");
    List<HasMetadata> matches =
        mm.match(PDDocument.load(file), strict, disableMK, minWaitInterval);
    HasMetadata match =
        (matches != null && !matches.isEmpty()) ? matches.get(0) : null;

    // Set the default conference if any.
    if (match != null && defaultConf != null) {
      match.setJournal(defaultConf);
    }

    output(file, match, outputDir);
    System.out.println("Done!");
  }

  /**
   * Outputs the given text in the given OutputStream.
   * 
   * @param origin
   *          the processed file.
   * @param match
   *          he computed match.
   * @param outputDir
   *          the output directory.
   * @throws Exception
   *           if outputting the result fails.
   */
  private static void output(File origin, HasMetadata match, String outputDir)
    throws Exception {
    // outputXmlFile(origin, match, outputDir);
    ex.importMetadata(origin, match, outputDir);
  }

  /**
   * Extracts the conference name
   * 
   * @param dir
   *          the name of directory to extract from.
   * @param baseDir
   *          the dir defined by the user.
   * @return the extracted conf name.
   */
  private static String extractConferenceName(File dir, File baseDir) {
    if (dir != null && baseDir != null) {
      String dirPath = dir.getAbsolutePath();
      String baseDirPath = baseDir.getAbsolutePath();

      int index = dirPath.indexOf(baseDirPath);
      if (index == 0) {
        // extract the subpath, beginning at the basepath.
        String subPath = dirPath.substring(baseDirPath.length());
        // Replace all "/", "\" and "_" by whitespaces.
        // TODO: Are there any more separator-chars to consider?
        return subPath.replaceAll("[\\\\/\\_]", " ").trim();
      }
    }
    return null;
  }

  // /**
  // * Returns a xml representation of a metadata record.
  // *
  // * @param match the record to process.
  // * @return the xml representaion of the metadata record.
  // */
  // private static String toValidXmp(HasMetadata match) {
  // String newLine = System.getProperty("line.separator");
  // StringBuilder sb = new StringBuilder();
  //
  // sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
  // sb.append(newLine);
  // sb.append("<x:xmpmeta xmlns:x=\"adobe:ns:meta/\">");
  // sb.append(newLine);
  // //
  // sb.append("  <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">");
  // sb.append("  <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:pdf='http://ns.adobe.com/pdf/1.3/'>");
  // sb.append(newLine);
  // sb.append("    <rdf:Description rdf:about=\"\" xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\">");
  // sb.append(newLine);
  // sb.append("      <xmp:CreatorTool>Icecite - http://www.icecite.com</xmp:CreatorTool>");
  // sb.append(newLine);
  // sb.append("      <xmp:ModifyDate>2013-06-12T00:17:13+02:00</xmp:ModifyDate>");
  // sb.append(newLine);
  // sb.append("      <pdf:Title>Some fancy title</pdf:Title>");
  // sb.append(newLine);
  // // sb.append("      <dc:creator>First author</dc:creator>");
  // // sb.append(newLine);
  // sb.append("    </rdf:Description>");
  // sb.append(newLine);
  // // sb.append("    <metadata>");
  // // sb.append(newLine);
  // // if (match != null) {
  // // sb.append("      <title>"
  // // + (match.getTitle() != null ? match.getTitle() : "") + "</title>");
  // // sb.append(newLine);
  // // sb.append("      <authors>");
  // // sb.append(newLine);
  // // if (match.getAuthors() != null) {
  // // for (String author : match.getAuthors()) {
  // // if (author != null) {
  // // sb.append("        <author>" + author + "</author>");
  // // sb.append(newLine);
  // // }
  // // }
  // // }
  // // sb.append("      </authors>");
  // // sb.append(newLine);
  // // sb.append("      <year>" + match.getYear() + "</year>");
  // // sb.append(newLine);
  // // sb.append("      <journal>"
  // // + (match.getJournal() != null ? match.getJournal() : "")
  // // + "</journal>");
  // // sb.append(newLine);
  // // sb.append("      <abstract>"
  // // + (match.getAbstract() != null ? match.getAbstract() : "")
  // // + "</abstract>");
  // // sb.append(newLine);
  // // }
  // // sb.append("    </metadata>");
  // // sb.append(newLine);
  // sb.append("  </rdf:RDF>");
  // sb.append(newLine);
  // sb.append("</x:xmpmeta>");
  // sb.append(newLine);
  // return sb.toString();
  // }

  // /**
  // * Outputs the given match into a xml file.
  // *
  // * @param origin
  // * the processed file
  // * @param match
  // * the matched metadata record.
  // * @param outputDir
  // * the output directory.
  // * @throws IOException
  // * if writing to file fails.
  // */
  // private static void outputXmlFile(File origin, HasMetadata match,
  // String outputDir) throws IOException {
  // if (origin != null) {
  // File outputFile;
  // if (outputDir != null) {
  // outputFile =
  // new File(outputDir + File.separatorChar
  // + getBaseName(origin.getName()) + ".xml");
  // } else {
  // outputFile = new File(getBaseName(origin.getAbsolutePath()) + ".xml");
  // }
  //
  // FileWriter fw = new FileWriter(outputFile);
  // BufferedWriter bw = new BufferedWriter(fw);
  // bw.write("<metadata pdf=\"" + origin.getAbsolutePath() + "\">");
  // bw.newLine();
  // if (match != null) {
  // bw.write("  <title>"
  // + (match.getTitle() != null ? match.getTitle() : "") + "</title>");
  // bw.newLine();
  // bw.write("  <authors>");
  // bw.newLine();
  // if (match.getAuthors() != null) {
  // for (String author : match.getAuthors()) {
  // if (author != null) {
  // bw.write("    <author>" + author + "</author>");
  // bw.newLine();
  // }
  // }
  // }
  // bw.write("  </authors>");
  // bw.newLine();
  // bw.write("  <year>" + match.getYear() + "</year>");
  // bw.newLine();
  // bw.write("  <journal>"
  // + (match.getJournal() != null ? match.getJournal() : "")
  // + "</journal>");
  // bw.newLine();
  // bw.write("  <abstract>"
  // + (match.getAbstract() != null ? match.getAbstract() : "")
  // + "</abstract>");
  // bw.newLine();
  // bw.write("</metadata>");
  // bw.newLine();
  // }
  //
  // bw.flush();
  // bw.close();
  // }
  // }

  /**
   * Computes the basename for the given path (the path without the filetype
   * extension.
   * 
   * @param path
   *          the path to process.
   * @return the basename of the path.
   */
  protected static String getBaseName(String path) {
    if (path != null) {
      int index = path.lastIndexOf(".");
      if (index > -1) { return path.substring(0, index); }
    }
    return path;
  }
}
