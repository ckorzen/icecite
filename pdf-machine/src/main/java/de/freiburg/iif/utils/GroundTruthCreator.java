package de.freiburg.iif.utils;
//package de.freiburg.iif.pdfextraction;
//
//import java.io.BufferedReader;
//import java.io.BufferedWriter;
//import java.io.File;
//import java.io.FileInputStream;
//import java.io.FileWriter;
//import java.io.IOException;
//import java.io.InputStreamReader;
//import java.io.Reader;
//import java.io.Writer;
//import java.util.List;
//
//import de.freiburg.iif.pdfextraction.base.model.HasMetadata;
//import de.freiburg.iif.pdfextraction.references.ReferencesMetadataMatcher;
//
//public class GroundTruthCreator {
//
//  /** The user directory */
//  protected static final String USER_DIR = System.getProperty("user.dir");
//  /** The base directory */
//  protected static final String BASE_DIR = USER_DIR
//      + "/src/test/resources/de/freiburg/iif/pdfextraction";
//  /** The pdf directory */
//  protected static final String PDF_DIR = BASE_DIR + "/pdfs";
//  /** The file extension of groundtruth files */
//  protected static final String FILEEXT_GROUNDTRUTH = ".qrels";
//  /** The file extension of groundtruth for failures */
//  protected static final String FILEEXT_GROUNDTRUTH_FAILS = ".fails.qrels";
//
//  // Read from the groundtruth file.
//  protected static String path = BASE_DIR + File.separatorChar
//      + "references.medline" + FILEEXT_GROUNDTRUTH;
//
//  public static void main(String[] args) throws IOException {
//    File file = new File(path);
//    Reader reader = new InputStreamReader(new FileInputStream(file), "UTF-8");
//    BufferedReader buf = new BufferedReader(reader);
//
//    // Write all failures on evaluation in an extra file.
//    String newFilepath = path + ".new2";
//    File newFile = new File(newFilepath);
//    Writer writer = new FileWriter(newFile);
//    BufferedWriter bw = new BufferedWriter(writer);
//    
//    ReferencesMetadataMatcher matcher = new ReferencesMetadataMatcher();
//
//    String line = null;
//    int i = 0;
//    // Process groundtruth file line by line.
//    while ((line = buf.readLine()) != null) {
//      if (!line.startsWith("\t")) {
//        String[] split = line.split("\t");
//                
//        if (split.length > 0) {
//          String pdfFilename = split[0];
//          File pdfFile = new File(PDF_DIR + File.separatorChar + pdfFilename);
//          
//          System.out.println(i + " Write "+ pdfFilename);
//          bw.write(pdfFilename);
//          bw.newLine();
//          
//          try {
//            List<HasMetadata> records = matcher.match(pdfFile);
//            if (records != null) {
//              for (int j = 0; j < records.size(); j++) {
//                HasMetadata record = records.get(j);
//                if (record != null) {
//                  if (record.getKey() != null) {
//                    bw.write("\t" + record.getRaw() + "\t" + record.getKey());
//                  } else {
//                    bw.write("\t" + record.getRaw() + "\t" + "NO_MATCH");
//                  }
//                  bw.newLine();
//                }
//              }
//            }
//          } catch (Exception e) {
//            e.printStackTrace();
//          }
//        }
//        i++;
//      }
////      else {
////        String[] split = line.split("\t");
////        if (split.length > 1) {
////          String reference = split[1];
////
////          if (reference != null && !reference.isEmpty()) {
////            System.out.print(" " + i + " Matching "+ reference+"...");
////            HasMetadata record = matcher.matchReference(reference);
////           
////            if (record != null && record.getKey() != null) {
////              System.out.println(record.getKey());
////              bw.write("\t" + reference + "\t" + record.getKey());
////              bw.newLine();
////            } else {
////              System.out.println("NO_MATCH");
////              bw.write("\t" + reference + "\t" + "NO_MATCH");
////              bw.newLine();
////            }
////          }
////        }
////      }
//    }
//    
//    bw.flush();
//    bw.close();
//    buf.close();
//  }
//}
