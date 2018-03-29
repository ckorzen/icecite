package de.freiburg.iif;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.security.InvalidParameterException;
import java.util.Date;
import java.util.zip.GZIPInputStream;

/**
 * A program for parsing the logs.
 * 
 * @author Claudius Korzen
 */
public abstract class LogParser {
  /** The input. Can be a directory or a single log file. */
  protected File input;
  /** The output file to write to. */ 
  protected File outputFile;
  /** The putput writer. */
  protected BufferedWriter outputWriter;
  
  // ___________________________________________________________________________
  // Parser methods.
  
  /**
   * Parses the given input and writes it to given output.
   */
  public void parse() throws IOException {
    this.outputWriter = new BufferedWriter(new FileWriter(outputFile, true));
    
    System.out.println("Parsing input " + input.getAbsolutePath());
    System.out.println("Writing output to " + outputFile.getAbsolutePath());
    System.out.println("******************");
    
    // Check, if the input is a file or a directory.
    if (input.isFile()) {
      parseFile(input);
    } else if (input.isDirectory()) {
      for (int i = 0; i < input.listFiles().length; i++) {
        parseFile(input.listFiles()[i]);
      }  
    }
        
    // Touch the output file to mark the current timestamp.
    outputFile.setLastModified(new Date().getTime());
    
    this.outputWriter.flush();
    this.outputWriter.close();
  }
  
  /**
   * Parses the given single log file.
   */
  protected void parseFile(File file) throws IOException {    
    if (file == null) return;
    if (!file.exists()) return;
    if (!file.isFile()) return;
    if (!file.canRead()) return;
    
    System.out.println("Visiting file " + file.getAbsolutePath());
    
    if (!takeFile(file)) {
      System.out.println("  Don't take the file.");
      return;
    }
    
    InputStream is = new FileInputStream(file);
      
    // Check, if the given file is zipped.
    if (file.getName().endsWith(".gz")) {;
      is = new GZIPInputStream(is);
    }
    
    // Parse the stream and count the number of parsed lines.
    int numParsedLines = parseInputStream(is);
      
    System.out.println("  Num of parsed lines: " + numParsedLines);
    
    // Close the input stream.
    is.close();
  }
  
  /**
   * Parses the given input stream.
   */
  protected int parseInputStream(InputStream stream) throws IOException {
    BufferedReader br = new BufferedReader(new InputStreamReader(stream));
        
    int numOfParsedLines = 0;
    
    String line = null;
    while ((line = br.readLine()) != null) {
      boolean parsed = parseLine(line);
      if (parsed) numOfParsedLines++;
    }
    
    br.close();
    return numOfParsedLines;
  }
  
  /**
   * Parses the given line of a log file.
   */
  protected boolean parseLine(String line) throws IOException {
    if (line == null) return false;
    if (!takeLine(line)) return false;
    
    writeLine(line);
    return true;
  }
    
  /**
   * Writes the given line to output file.
   */
  protected void writeLine(String line) throws IOException {
    outputWriter.write(line);
    outputWriter.newLine();
  }
  
  // ___________________________________________________________________________
  // Setter methods.
    
  /**
   * Sets the input for this parser and validates it. 
   */
  public void setInput(File input) throws IOException {
    if (input == null) {
      throw new InvalidParameterException("No input is given");
    }
    if (!input.exists()) {
      throw new InvalidParameterException("Input doesn't exist.");
    }
    if (!input.canRead()) {
      throw new IOException("Can't read input.");
    }
    
    this.input = input;
  }
  
  /**
   * Sets the output file and validates it. If the file doesn't exist, this 
   * method will try to create it. 
   */
  public void setOutputFile(File output) throws IOException {
    if (output == null) {
      throw new InvalidParameterException("No output file is given");
    }
    if (output.isDirectory()) {
      throw new InvalidParameterException("Output must be a file.");
    }
     
    if (output.exists()) {
      onNoNeedToCreateOutputFile(output);
    } else {
      boolean created = false;
      try {
        created = output.createNewFile();  
      } catch (Exception e) {
        throw new IOException("Couldn't create the output file.");
      }
      
      if (!created) throw new IOException("Couldn't create the output file.");
      
      onNeedToCreateOutputFile(output);
    }
    
    if (!output.canWrite()) {
      throw new IOException("Couldn't write to output file.");
    }
        
    this.outputFile = output;
  }
  
  // ___________________________________________________________________________
  // Abstract methods.
  
  /**
   * Returns true, if the given file should be considered for parsing. It is 
   * guaranteed, that file != null.
   */
  protected abstract boolean takeFile(File file);
  
  /**
   * Returns true, if the given line should be considered for parsing.
   */
  protected abstract boolean takeLine(String line);
  
  /**
   * This method is called, whenever there is a need to create the output file.
   */
  protected void onNeedToCreateOutputFile(File outputFile) { };
  
  /**
   * This method is called, whenever there isn't a need to create the output 
   * file.
   */
  protected void onNoNeedToCreateOutputFile(File outputFile) { };
}
