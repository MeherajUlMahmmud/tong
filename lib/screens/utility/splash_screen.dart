import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tong/screens/auth/login_screen.dart';
import 'package:tong/screens/main/home_screen.dart';
import 'package:tong/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void checkUser() async {
    final User? _user = _auth.currentUser;

    if (_user == null) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      });
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          Constants.appName,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
