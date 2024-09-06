import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:tong/repository/auth_service.dart';
import 'package:tong/screens/auth/login_screen.dart';
import 'package:tong/utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Logger _logger = Logger('ProfileScreen');

  final AuthService _authService = AuthService();

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser;
  }

  void _logout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm the logout
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      _logger.info('Logging out...');
      await _authService.signOut();

      // Sign out from Google account (clears account session)
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      _logger.info('Logged out');

      if (!context.mounted) return;

      // Clear the stack and navigate to the login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName, // Assuming LoginScreen is the route for login
        (route) => false, // This clears all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ScreenTitles.profile),
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // show user's profile picture
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        _user!.photoURL ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _user!.displayName ?? 'No Name',
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _user!.email ?? 'No Email',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _logout,
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
