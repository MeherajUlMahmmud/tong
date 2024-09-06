import 'package:flutter/material.dart';
import 'package:tong/screens/auth/login_screen.dart';
import 'package:tong/screens/main/category/add_edit_category_screen.dart';
import 'package:tong/screens/main/category/list_category_screen.dart';
import 'package:tong/screens/main/history/HistoryScreen.dart';
import 'package:tong/screens/main/home_screen.dart';
import 'package:tong/screens/main/main_screen.dart';
import 'package:tong/screens/main/user/profile_screen.dart';
import 'package:tong/screens/utility/not_found_screen.dart';
import 'package:tong/screens/utility/splash_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case SplashScreen.routeName:
      return MaterialPageRoute(builder: (context) => const SplashScreen());
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    case MainScreen.routeName:
      return MaterialPageRoute(builder: (context) => const MainScreen());
    case HomeScreen.routeName:
      return MaterialPageRoute(builder: (context) => const HomeScreen());
    case HistoryScreen.routeName:
      return MaterialPageRoute(builder: (context) => const HistoryScreen());
    case ProfileScreen.routeName:
      return MaterialPageRoute(builder: (context) => const ProfileScreen());
    case CategoryListScreen.routeName:
      return MaterialPageRoute(
          builder: (context) => const CategoryListScreen());
    case AddEditCategoryScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const AddEditCategoryScreen(),
        settings: settings,
      );
    default:
      return MaterialPageRoute(builder: (context) => const NotFoundScreen());
  }
}
