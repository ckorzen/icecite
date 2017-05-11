import 'dart:io';
import 'package:path/path.dart';

const String DEPLOY_SOURCE = "build";
List<String> manifestFiles = [];

/// The main method.
void main(args) {  
  createManifestFile();
}

/// Creates the manifest file.
void createManifestFile() {
  Directory dir = new Directory(DEPLOY_SOURCE);
  if (!dir.existsSync()) return;
    
  List<FileSystemEntity> entities = dir.listSync(recursive:true);
  for (var entity in entities) {
    if (entity is File) {
      String path = entity.path.replaceFirst("$DEPLOY_SOURCE\\web\\", "");
      // Fetch all files from external-scripts
      if (path.startsWith("external-scripts")) {
        manifestFiles.add(path);
        continue;
      }
      
      // Fetch all js files in external-scripts.
      if (extension(path) == ".js") {
        manifestFiles.add(path);
        continue;
      }

      // Fetch all images
      if (path.startsWith("images")) {
        manifestFiles.add(path);
        continue;
      }
            
      // Fetch all css files.
      if (extension(path) == ".css") {
        manifestFiles.add(path);
        continue;
      }
    }
  }
    
  // Fixed files.
  manifestFiles.add("icecite.html");
  manifestFiles.add("icecite.html_bootstrap.dart");
    
  writeManifestFile(manifestFiles);
}

/// Writes the given filePaths to manifest file.
void writeManifestFile(List<String> filePaths) {
  StringBuffer sb = new StringBuffer();
  File file = new File("$DEPLOY_SOURCE\\web\\icecite.appcache");
  if (!file.existsSync()) file.createSync();
  
  // Write the header.
  sb.writeln("CACHE MANIFEST");
  sb.writeln("# ${new DateTime.now()}");
  sb.writeln();
  
  // Write the filepaths.
  sb.writeln("CACHE:");
  for (String path in filePaths) {
    sb.writeln(path);
  }
  sb.writeln();
  
  sb.writeln("NETWORK:");
  sb.writeln("*");
    
  file.writeAsStringSync(sb.toString());
}