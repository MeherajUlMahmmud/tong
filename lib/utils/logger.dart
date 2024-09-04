import 'package:logging/logging.dart';

void setupLogger() {
  // Configure the logger
  Logger.root.level = Level.ALL; // Log everything (you can change the level)
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}
