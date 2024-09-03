import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tong/screens/main/home_screen.dart';
import 'package:tong/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  String error = '';

  Future<void> _googleSignIn() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        print("User signed in: ${userCredential.user}");

        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else {
        setState(() {
          isLoading = false;
          error = "Failed to sign in";
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        error = "Wrong credentials";
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
