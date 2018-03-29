package de.freiburg.iif;

import java.io.File;

public class LogParserMain {

  public static void main(String[] args) {
    if (args.length < 2) {
      System.err.println("Usage: java -jar LogParserMain.jar <input> <output-file>");
    }
    
    LogParser parser = new CouchDbLogParser();
            
    try {
      parser.setInput(new File(args[0]));
      parser.setOutputFile(new File(args[1]));
      
      parser.parse();
    } catch (Exception e) {
      System.err.println("Error on parsing log: " + e.getMessage());
    }
  }
}
