library logging_util;

import 'package:logging/logging.dart';

bool isEnabled = false;

/// Enables the logging.
void enable() {
  /// Setup Logging.
  Logger logger = new Logger('');
  logger.level = Level.SEVERE;
  logger.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time} (${rec.loggerName}): ${rec.message}');
  });  
  isEnabled = true;
}

/// Returns a logger for the given name.
Logger get(String name) {
  if (!isEnabled) enable();
  return new Logger(name);
}
