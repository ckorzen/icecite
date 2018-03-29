import 'dart:io';
import 'package:intl/intl.dart';
import 'package:args/args.dart';
import 'build-manifest.dart' as manifestBuilder;
import 'package:path/path.dart';

const String DEPLOY_SOURCE = "build";
//const String DEPLOY_TARGET_PROD = "/home/korzen/icecite/web/icecite";
const String DEPLOY_TARGET_PROD = "I:/";
//const String DEPLOY_TARGET_DEV = "/home/korzen/icecite/web/icecite";
const String DEPLOY_TARGET_DEV = "J:/";

//const String PUB_CMD = "/home/korzen/bin/dart-sdk/bin/pub";
const String PUB_CMD = "C:\\Users\\korzen\\Downloads\\eclipse\\eclipse\\dart-sdk\\bin\\pub";

ArgResults settings;
bool executeClear;
bool executeDeploy;
bool executeBuild;

/// The main method.
void main(args) {
  _parseArguments(args);
  
  executeClear = !settings['build'] && !settings['deploy']; 
  executeDeploy = !settings['build'] && !settings['clear']; 
  executeBuild = !settings['deploy'] && !settings['clear']; 
  
  String source = DEPLOY_SOURCE;
  String target;
  if (settings['mode'] == 'dev') {
    target = new Uri.file(DEPLOY_TARGET_DEV).toFilePath(); 
  } else {
    target = new Uri.file(DEPLOY_TARGET_PROD).toFilePath();
  }
  
  println("Build icecite. Mode: ${settings['mode']}. Clear: $executeClear. " 
          "Build: $executeBuild. Deploy: $executeDeploy.");
  build(source, target);
  println("Finished.");
}

/// Builds icecite.
void build(String source, String target) {
  if (executeClear) {
    println("Clear $target...");
    _clearTarget(target);
  }
  if (executeBuild) {
    println("Pub build...");
    _build();
    manifestBuilder.createManifestFile();
  }
  if (executeDeploy) {
    println("Deploy $source to $target...");
    _deploy(source, target);
    _writeCreationDateFile(join(target, "build", "web"));
  }
}

// _____________________________________________________________________________

/// Runs pub build.
_build({sync: true}) {
  return _execute(PUB_CMD, ["build", "--mode=${settings['mode']}"], sync: sync);
}

/// Clears the deploy target.
void _clearTarget(target) {
  Directory dir = new Directory(target);
  List<FileSystemEntity> entities = dir.listSync(recursive: false);
  for (FileSystemEntity entity in entities) {
    if (entity.existsSync()) entity.deleteSync(recursive: true);
  }
}

/// Runs pub build.
void _deploy(String source, String target, {sync: true}) {
  _copyFolderSync(source, target);
}

// _____________________________________________________________________________

/// Parses the command line arguments.
void _parseArguments([List<String> args]) {
  var parser = new ArgParser()
   ..addOption('mode', abbr: 'm', help: "'dev' or 'prod'", defaultsTo: 'prod')
   ..addFlag('clear', help: 'Only clear the deploy target.')
   ..addFlag('deploy', negatable: false, help: 'Only deploy.')
   ..addFlag('build', negatable: false, help: 'Only build.')
   ..addFlag('help', negatable: false, help: 'Displays this help and exit.');
  
  void showUsage() {
    print('Usage: dart build-icecite.dart [options]');
    print('\nThese are valid options expected by build.dart:');
    print(parser.getUsage());
  }
  
  try {
    settings = parser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    showUsage();
    exit(1);
  }
    
  if (settings['help']) {
    print('A build script that deploys icecite to server.');
    showUsage();
    exit(0);
  }
}

/// Executes the given command with given arguments.
_execute(String cmd, List args, {bool runInShell: true, bool sync: false}) {
  if (sync) return Process.runSync(cmd, args, runInShell: runInShell);
  else return Process.run(cmd, args, runInShell: runInShell);
}
 
/// Performs a synchronous folder copy.
void _copyFolderSync(String path1, String path2) {      
  Directory dir1 = new Directory(path1);
  if (!dir1.existsSync()) {
    throw new Exception(
        'Source directory "${dir1.path}" does not exist, nothing to copy'
    );
  }
    
  // Check, if we need to create the target directory.
  if (!path2.endsWith(path1)) {
    path2 = join(path2, basename(path1));
  }
    
  // Create directory if it doesn't exist.
  Directory dir2 = new Directory(path2);
  if (!dir2.existsSync()) dir2.createSync(recursive: true);
   
  dir1.listSync().forEach((FileSystemEntity element) {
    String newPath = join(dir2.path, basename(element.path));
                
    if (element is File) {
      element.copy(newPath);
    } else if (element is Directory) {
      _copyFolderSync(element.path, newPath);
    } else {
      throw new Exception('File is neither File nor Directory. WTF?');
    }
  }); 
}

void _writeCreationDateFile(String target) {
  File creationDateFile = new File(join(target, "creation"));
  if (!creationDateFile.existsSync()) creationDateFile.createSync();
  
  var date = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  creationDateFile.writeAsString(formatter.format(date));
}

print(String s) => stdout.write(s);
println(String s) => stdout.writeln(s);