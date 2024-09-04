import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tong/screens/auth/login_screen.dart';
import 'package:tong/screens/main/category/list_category_screen.dart';
import 'package:tong/screens/main/history/HistoryScreen.dart';
import 'package:tong/screens/main/user/profile_screen.dart';
import 'package:tong/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  final Map<int, String> _months = const {
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };

  final Map<String, dynamic> _todaysData = {};
  final Map<String, dynamic> _categories = {};

  bool isLoading = true;
  String error = '';

  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    super.dispose();
    _todaysData.clear();
    _categories.clear();
  }

  // refresh data
  Future<void> _refreshData() async {
    await _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkUser();
    await _fetchCategories();
    await _fetchTodaysData();
  }

  Future<void> _checkUser() async {
    _user = _auth.currentUser;

    if (_user == null) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      print("Fetching categories...");
      QuerySnapshot querySnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: _user!.uid)
          // sort by title
          // .orderBy('title')
          .get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        _categories[doc.id] = doc.data();
      }

      print("Categories fetched: ${_categories.length}");

      setState(() {
        _categories;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchTodaysData() async {
    if (_user == null) return;

    final String today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final DocumentReference userDoc = _firestore
        .collection('daily_data')
        .doc(_user!.uid)
        .collection('dates')
        .doc(today);

    try {
      print("Fetching today's data...");
      final DocumentSnapshot docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        print("Today's data already exists");

        setState(() {
          _todaysData.addAll(docSnapshot.data() as Map<String, dynamic>);
        });

        _updateTotalAmount();

        setState(() {
          isLoading = false;
          error = '';
        });
      } else {
        print("Today's data does not exist");

        await userDoc.set({
          '11': 11,
        });

        final newDocSnapshot = await userDoc.get();
        setState(() {
          _todaysData.addAll(newDocSnapshot.data() as Map<String, dynamic>);
          isLoading = false;
          error = '';
        });
      }
    } catch (e) {
      print('Error fetching today\'s data: $e');
      setState(() {
        isLoading = false;
        error = 'Error fetching today\'s data: $e';
      });
    }
  }

  void _updateTotalAmount() {
    double total = 0;

    print("Updating total amount...");
    print("Categories: ${_categories.length}");
    print("Todays data: ${_todaysData.length}");

    // Iterate through the _todaysData map to calculate the total amount
    _todaysData.forEach((categoryId, itemCount) {
      print("Category ID: $categoryId");
      print("Count: $itemCount");

      if (_categories.containsKey(categoryId.toString())) {
        print("Category ID found in _categories");
        // check type of price
        double price = 0.0;
        if (_categories[categoryId]['price'] is double) {
          print("Price is double");
          price = _categories[categoryId]['price'];
        } else if (_categories[categoryId]['price'] is int) {
          print("Price is int");
          price = _categories[categoryId]['price'] + 0.0;
        } else if (_categories[categoryId]['price'] is String) {
          print("Price is String");
          price = int.parse(_categories[categoryId]['price'].toString()) + 0.0;
        } else {
          print("Price is not int or String or double");
          print("Price: ${_categories[categoryId]['price']}");
          price = 0.0;
        }
        print("Price: $price");
        total += (price) * (itemCount as int);
      } else {
        print("Category ID not found in _categories");
      }
    });

    // Update the state with the new total amount
    setState(() {
      _totalAmount = total;
    });
  }

  void _incrementItemCount(String categoryId) {
    setState(() {
      if (_todaysData.containsKey(categoryId)) {
        _todaysData[categoryId] += 1;
      } else {
        _todaysData[categoryId] = 1;
      }
      _updateTotalAmount(); // Update the total amount if needed
    });

    // Update the count in Firestore
    _updateItemCountInFirestore(categoryId, _todaysData[categoryId]);
  }

  void _decrementItemCount(String categoryId) {
    setState(() {
      if (_todaysData.containsKey(categoryId) && _todaysData[categoryId] > 0) {
        _todaysData[categoryId] -= 1;
      }

      _updateTotalAmount(); // Update the total amount if needed
    });

    // Update the count in Firestore
    if (_todaysData.containsKey(categoryId) == false) {
      _updateItemCountInFirestore(categoryId, 0);
    } else {
      _updateItemCountInFirestore(categoryId, _todaysData[categoryId]);
    }
  }

  Future<void> _updateItemCountInFirestore(String categoryId, int count) async {
    final String today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final DocumentReference userDoc = _firestore
        .collection('daily_data')
        .doc(_user!.uid)
        .collection('dates')
        .doc(today);

    try {
      await userDoc.update({categoryId: count});
    } catch (e) {
      print('Error updating item count in Firestore: $e');
    }
  }

  void _handleLogout() {
    _auth.signOut();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    });
  }

  void _onMenuSelected(int item) {
    switch (item) {
      case 0:
        Navigator.of(context).pushNamed(CategoryListScreen.routeName);
        break;
      case 1:
        Navigator.of(context).pushNamed(ProfileScreen.routeName);
        break;
      case 2:
        Navigator.of(context).pushNamed(HistoryScreen.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate =
        '${_months[now.month]} ${now.day}, ${now.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.appName),
        actions: [
          IconButton(
            onPressed: () {
              _refreshData();
            },
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<int>(
            onSelected: (item) => _onMenuSelected(item),
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.list_alt_outlined, size: 20),
                    SizedBox(width: 5),
                    Text('Product'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 5),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 5),
                    Text('History'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hi ${_user!.displayName ?? 'User'}'),
                      const SizedBox(height: 5),
                      Text(
                        'Today is $formattedDate',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final categoryId = _categories.keys.elementAt(index);
                          // print("Category key: $categoryId");

                          final categoryData = _categories[categoryId];
                          // print("Category data: $categoryData");

                          final itemCount = _todaysData[categoryId] ?? 0;
                          // print("Item count: $itemCount");

                          final categoryTitle = categoryData['title'];
                          // print("Category title: $categoryTitle");

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text(
                                    categoryTitle ?? 'Unknown Category',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildIconWithCounter(
                                    icon: Icons.add,
                                    onTap: () {
                                      _incrementItemCount(categoryId);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    itemCount.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildIconWithCounter(
                                    icon: Icons.remove,
                                    onTap: () {
                                      _decrementItemCount(categoryId);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 70,
                        child: Text(
                          _totalAmount.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildIconWithCounter({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 0.5),
          borderRadius: const BorderRadius.all(Radius.elliptical(5, 5)),
        ),
        child: Icon(
          icon,
          size: 20,
        ),
      ),
    );
  }
}
