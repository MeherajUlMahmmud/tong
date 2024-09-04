import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tong/utils/utils.dart';

class HistoryScreen extends StatefulWidget {
  static const routeName = '/history';

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  List<String> _dates = [];
  Map<String, dynamic> _categories = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize data by fetching the current user, categories, and dates
  Future<void> _initializeData() async {
    try {
      _user = _auth.currentUser;

      if (_user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });

        // Clear the stack and navigate to the login screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      await _fetchCategories();
      await _fetchDates();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error initializing data: $e';
      });
    }
  }

  /// Fetch categories for the current user from Firestore
  Future<void> _fetchCategories() async {
    try {
      print("Fetching categories...");
      QuerySnapshot querySnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: _user!.uid)
          .orderBy('title')
          .get();

      Map<String, dynamic> fetchedCategories = {};

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        fetchedCategories[doc.id] = doc.data();
      }

      setState(() {
        _categories = fetchedCategories;
      });

      print("Categories fetched: ${_categories.length}");
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _error = 'Error fetching categories: $e';
      });
    }
  }

  /// Fetch all available dates for the current user from Firestore
  Future<void> _fetchDates() async {
    try {
      print("Fetching dates...");
      QuerySnapshot querySnapshot = await _firestore
          .collection('daily_data')
          .doc(_user!.uid)
          .collection('dates')
          // .orderBy(FieldPath.documentId, descending: true) // Latest dates first
          .get();

      List<String> fetchedDates = [];

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        fetchedDates.add(doc.id); // Assuming doc.id is the date string
      }

      setState(() {
        _dates = fetchedDates;
      });

      print("Dates fetched: ${_dates.length}");
    } catch (e) {
      print('Error fetching dates: $e');
      setState(() {
        _error = 'Error fetching dates: $e';
      });
    }
  }

  /// Show a bottom sheet with item details for a selected date
  Future<void> _showItemsBottomSheet(String date) async {
    showModalBottomSheet(
      context: context,
      // isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore
              .collection('daily_data')
              .doc(_user!.uid)
              .collection('dates')
              .doc(date)
              .get(),
          builder: (context, snapshot) {
            // if (snapshot.connectionState == ConnectionState.waiting) {
            //   return const Padding(
            //     padding: EdgeInsets.all(16.0),
            //     child: Center(child: CircularProgressIndicator()),
            //   );
            // }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No data for this date.')),
              );
            }

            Map<String, dynamic> dateData =
                snapshot.data!.data() as Map<String, dynamic>;

            // Remove 'initialized' or other non-category fields if present
            Map<String, dynamic> itemsData = Map.from(dateData);
            itemsData.remove('initialized');

            // Convert to a list of items with category titles and counts
            List<Map<String, dynamic>> itemsList = [];

            itemsData.forEach((categoryId, count) {
              if (_categories.containsKey(categoryId)) {
                String title = _categories[categoryId]['title'] ?? 'No Title';
                dynamic priceDynamic = _categories[categoryId]['price'];
                double price;
                if (priceDynamic is int) {
                  price = priceDynamic.toDouble();
                } else if (priceDynamic is double) {
                  price = priceDynamic;
                } else {
                  price = 0.0;
                }
                int countInt = 0;
                if (count is int) {
                  countInt = count;
                } else if (count is double) {
                  countInt = count.toInt();
                } else {
                  // Handle other possible types or set to 0
                  countInt = 0;
                }

                itemsList.add({
                  'title': title,
                  'price': price,
                  'count': countInt,
                  'total': price * countInt,
                });
              }
            });

            if (itemsList.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No items for this date.')),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 16.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items for ${_formatDateString(date)}',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itemsList.length,
                    itemBuilder: (ctx, index) {
                      final item = itemsList[index];
                      if (item['count'] == 0) return const SizedBox();
                      return ListTile(
                        title: Text(item['title']),
                        subtitle: Text(
                            'Price: \$${item['price'].toStringAsFixed(2)}, Count: ${item['count']}'),
                        trailing: Text('\$${item['total'].toStringAsFixed(2)}'),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Format date string from 'yyyy-MM-dd' to 'Month dd, yyyy'
  String _formatDateString(String dateString) {
    // Assuming dateString is in 'yyyy-MM-dd' format
    try {
      DateTime date = DateTime.parse(dateString);
      return "${Helper().getMonthName(date.month)} ${date.day}, ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _dates.isEmpty
                  ? const Center(child: Text('No history available.'))
                  : ListView.builder(
                      itemCount: _dates.length,
                      itemBuilder: (context, index) {
                        final date = _dates[index];
                        return ListTile(
                          title: Text(_formatDateString(date)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showItemsBottomSheet(date);
                          },
                        );
                      },
                    ),
    );
  }
}
