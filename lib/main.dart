import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tong/screens/auth/login_screen.dart';
import 'package:tong/screens/main/category/add_edit_category_screen.dart';
import 'package:tong/screens/main/category/list_category_screen.dart';
import 'package:tong/screens/main/history/HistoryScreen.dart';
import 'package:tong/screens/main/home_screen.dart';
import 'package:tong/screens/main/user/profile_screen.dart';
import 'package:tong/screens/utility/splash_screen.dart';
import 'package:tong/utils/constants.dart';
import 'package:tong/utils/logger.dart';
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
        fontFamily: 'Alkatra',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        LoginScreen.routeName: (ctx) => const LoginScreen(),
        HomeScreen.routeName: (ctx) => const HomeScreen(),
        CategoryListScreen.routeName: (ctx) => const CategoryListScreen(),
        AddEditCategoryScreen.routeName: (ctx) => const AddEditCategoryScreen(),
        HistoryScreen.routeName: (ctx) => const HistoryScreen(),
        ProfileScreen.routeName: (ctx) => const ProfileScreen(),
      },
    );
  }
}
