import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tong/screens/auth/login_screen.dart';
import 'package:tong/screens/main/main_screen.dart';
import 'package:tong/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void checkUser() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      developer.log("User not logged in");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      });
    } else {
      developer.log("User logged in");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
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
      body: SizedBox(
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(Constants.tongDokanImage, width: 200),
              const SizedBox(height: 20),
              Text(
                Constants.appName,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
