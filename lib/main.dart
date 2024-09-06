import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tong/utils/constants.dart';
import 'package:tong/utils/logger.dart';
import 'package:tong/utils/routes_handler.dart';
import 'firebase_options.dart';

void main() async {
  setupLogger();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Constants.appName,
      theme: ThemeData(
        fontFamily: Constants.fontFamily,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: generateRoute,
    );
  }
}
