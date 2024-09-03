import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  void _logout() async {
    await _auth.signOut();

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
                      style: const TextStyle(fontSize: 20),
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
