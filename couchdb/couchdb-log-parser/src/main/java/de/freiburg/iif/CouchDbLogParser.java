package de.freiburg.iif;

import java.io.File;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

public class CouchDbLogParser extends LogParser {

  long outputFileLastModifiedTime = 0;
  
  @Override
  protected boolean takeFile(File file) {
    if (file.lastModified() <= outputFileLastModifiedTime) return false;
    return !(file.getName().endsWith(".dump"));    
  }

  @Override
  protected boolean takeLine(String line) {
    // Extract the date in the first [...]
    int index1 = line.indexOf("[");
    int index2 = line.indexOf("]", index1);
    
    if (index1 == 0 && index2 > index1) {
      String lineDateStr = line.substring(index1 + 1, index2);
      DateFormat df = new SimpleDateFormat("EEE, dd MMM yyyy kk:mm:ss z");
      long lineTime = 0;
      
      try {
        lineTime = df.parse(lineDateStr).getTime(); 
      } catch (Exception e) {
        e.printStackTrace();
      }
      
      boolean isTimeRelevant = lineTime > outputFileLastModifiedTime;
      boolean isContentRelevant = line.indexOf("Log ::" ) > 0;
          
      return isTimeRelevant && isContentRelevant;
    }
    return false;
  }

  @Override
  protected void onNoNeedToCreateOutputFile(File outputFile) {
    outputFileLastModifiedTime = outputFile.lastModified();
  }
}
