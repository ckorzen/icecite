package de.freiburg.iif.extraction.performance;


/**
 * Main class to execute performance tests.
 * 
 * @author Claudius Korzen
 */
public class PerformanceTestMain {
  
  /** 
   * The main method 
   * 
   * @param args the arguments. 
   */
  public static void main(String[] args) {    
    if (args.length == 0) {
      System.err.println("Please type in a basename!");
      System.exit(1);
    }
//    String basename = args[0];
//        
//    // Evaluate the title extraction.
//    BasePerformanceTest test;
    
    // TODO: Prepare it with Guice.
//    if (basename.startsWith("titles")) {
//      test = new DocumentMetadataPerformanceTest();
//    } else {
//      test = new ReferencesMetadataPerformanceTest();
//    }
       
//    try {
//      test.evaluate(basename);
//    } catch (Exception e) {
//      e.printStackTrace();
//    }
  }
}
