import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:tong/repository/auth_service.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:tong/screens/main/category/list_category_screen.dart';
import 'package:tong/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = Logger('HomeScreen');

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;

  Map<String, dynamic> _todaysData = {};
  Map<String, dynamic> _categories = {};
  bool isLoading = true;
  String error = '';
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

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

  final String today =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

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
    try {
      await _checkUser();
      await _fetchCategories();
      await _fetchTodaysData();
    } catch (e) {
      _logger.severe('Initialization failed: $e');
      setState(() {
        isLoading = false;
        error = 'Error initializing data: $e';
      });
    }
  }

  Future<void> _checkUser() async {
    _user = _authService.currentUser;
    if (_user == null) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      _logger.info('Fetching categories...');
      _categories = await _firestoreService.fetchCategories();
      setState(() {});
      _logger.info('Categories fetched: ${_categories.length}');
    } catch (e) {
      _logger.severe('Error fetching categories: $e');
      setState(() {
        isLoading = false;
        error = 'Error fetching categories: $e';
      });
    }
  }

  Future<void> _fetchTodaysData() async {
    try {
      _logger.info('Fetching today\'s data...');
      final data = await _firestoreService.fetchDailyData(today);
      if (data != null) {
        _todaysData = data;
        _updateTotalAmount();
        setState(() {
          isLoading = false;
          error = '';
        });
      } else {
        await _firestoreService.initializeTodaysData();
        final newData = await _firestoreService.fetchDailyData(today);
        setState(() {
          _todaysData = newData ?? {};
          isLoading = false;
          error = '';
        });
      }
    } catch (e) {
      _logger.severe('Error fetching today\'s data: $e');
      setState(() {
        isLoading = false;
        error = 'Error fetching today\'s data: $e';
      });
    }
  }

  void _updateTotalAmount() {
    double total = 0.0;
    _logger.info('Updating total amount...');
    _todaysData.forEach((categoryId, itemCount) {
      if (_categories.containsKey(categoryId)) {
        final price =
            _firestoreService.getCategoryPrice(_categories, categoryId);
        total += price * (itemCount as int);
      }
    });
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
      _updateTotalAmount();
    });
    _firestoreService.updateItemCount(categoryId, _todaysData[categoryId]);
  }

  void _decrementItemCount(String categoryId) {
    setState(() {
      if (_todaysData.containsKey(categoryId) && _todaysData[categoryId] > 0) {
        _todaysData[categoryId] -= 1;
      }
      _updateTotalAmount();
    });
    _firestoreService.updateItemCount(categoryId, _todaysData[categoryId] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(CategoryListScreen.routeName);
            },
            icon: const Icon(Icons.list_alt_outlined),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final DateTime now = DateTime.now();
    final String formattedDate =
        '${_months[now.month]} ${now.day}, ${now.year}';

    if (error.isNotEmpty) {
      return Center(
        child: Text(
          error,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text('Hi ${_user!.displayName ?? 'User'}'),
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
              // developer.log("Category key: $categoryId");

              final categoryData = _categories[categoryId];
              // developer.log("Category data: $categoryData");

              final itemCount = _todaysData[categoryId] ?? 0;
              // developer.log("Item count: $itemCount");

              final categoryTitle = categoryData['title'];
              // developer.log("Category title: $categoryTitle");

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
