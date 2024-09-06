import 'package:flutter/material.dart';
import 'package:tong/screens/main/history/HistoryScreen.dart';
import 'package:tong/screens/main/home_screen.dart';
import 'package:tong/screens/main/user/profile_screen.dart';
import 'package:tong/utils/constants.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = '/main';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index of the selected tab.

  // List of screens to navigate between.
  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: NavigationLabels.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: NavigationLabels.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: NavigationLabels.profile,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index; // Update the selected index.
          });
        },
      ),
    );
  }
}
