import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:tong/repository/auth_service.dart';
import 'package:tong/screens/main/main_screen.dart';
import 'package:tong/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Logger _logger = Logger('LoginScreen');

  final AuthService _authService = AuthService();

  bool isLoading = false;
  String error = '';

  Future<void> _googleSignIn() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    UserCredential? userCredential = await _authService.signInWithGoogle();

    if (userCredential != null) {
      _logger.info("User signed in: ${userCredential.user}");
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
    } else {
      _logger.severe("Failed to sign in");
      setState(() {
        isLoading = false;
        error = "Failed to sign in";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(Constants.tongDokanImage, width: 200),
              const SizedBox(height: 20),
              const Text(
                Constants.appName,
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _googleSignIn,
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage('assets/images/google.png'),
                              width: 35,
                            ),
                            Text('Sign In with Google'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
