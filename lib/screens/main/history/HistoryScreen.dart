import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:tong/utils/constants.dart';
import 'package:tong/utils/utils.dart';

class HistoryScreen extends StatefulWidget {
  static const routeName = '/history';

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Logger _logger = Logger('HistoryScreen');

  final FirestoreService _firestoreService = FirestoreService();

  List<String> _dates = [];
  String? _selectedYearMonth; // Selected year and month for filtering
  // Default to current year
  String _selectedYear = DateTime.now().year.toString();
  // Default to current month
  String _selectedMonth = Helper.formatMonth(DateTime.now().month);
  Map<String, dynamic> _categories = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();

    _selectedYearMonth = Helper.formatYearMonth(DateTime.now());
    _initializeData();
  }

  /// Initialize data by fetching the current user, categories, and dates
  Future<void> _initializeData() async {
    try {
      await _fetchCategories();
      await _fetchDates();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.info('Error initializing data: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error initializing data: $e';
      });
    }
  }

  /// Filter dates based on the selected year and month
  void _filterByMonth(String year, String month) async {
    _selectedYearMonth = '$year-$month'; // Format year and month
    setState(() {}); // Trigger UI update

    await _fetchDates();
  }

  /// Fetch categories for the current user from Firestore
  Future<void> _fetchCategories() async {
    try {
      _logger.info("Fetching categories...");

      _categories = await _firestoreService.fetchCategories();
      setState(() {});

      _logger.info("Categories fetched: ${_categories.length}");
    } catch (e) {
      _logger.severe('Error fetching categories: $e');
      setState(() {
        _error = 'Error fetching categories: $e';
      });
    }
  }

  /// Fetch all available dates for the current user from Firestore
  Future<void> _fetchDates() async {
    try {
      _logger.info("Fetching dates...");

      _dates = await _firestoreService.fetchDates(_selectedYearMonth!);
      setState(() {});

      _logger.info("Dates fetched: ${_dates.length}");
    } catch (e) {
      _logger.severe('Error fetching dates: $e');
      setState(() {
        _error = 'Error fetching dates: $e';
      });
    }
  }

  Future<void> _showItemsBottomSheet(String date) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<DocumentSnapshot>(
          future: _firestoreService.fetchDailyDataDocument(date),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Error: ${snapshot.error}')),
                ),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox(
                height: 200,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No data for this date.')),
                ),
              );
            }

            Map<String, dynamic> dateData =
                snapshot.data!.data() as Map<String, dynamic>;

            // Remove 'initialized' or other non-category fields if present
            Map<String, dynamic> itemsData = Map.from(dateData);
            itemsData.remove('initialized');

            // Convert to a list of items with category titles and counts
            List<Map<String, dynamic>> itemsList = [];
            double totalSpent = 0.0; // Move this inside the builder

            itemsData.forEach((categoryId, itemCount) {
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
                if (itemCount is int) {
                  countInt = itemCount;
                } else if (itemCount is double) {
                  countInt = itemCount.toInt();
                } else {
                  // Handle other possible types or set to 0
                  countInt = 0;
                }

                double total = price * countInt;
                itemsList.add({
                  'title': title,
                  'price': price,
                  'count': countInt,
                  'total': total,
                });
              }
            });

            // Calculate total spent after processing all items
            totalSpent =
                itemsList.fold(0.0, (sum, item) => sum + item['total']);

            if (itemsList.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No items for this date.')),
                ),
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
                    '${Helper.formatDateString(date)}  -  ৳${totalSpent.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
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
                          '৳${item['price'].toStringAsFixed(2)}, Count: ${item['count']}',
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ScreenTitles.history),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Year Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Year',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _selectedYear,
                                hint: const Text("Select Year"),
                                onChanged: (String? newYear) {
                                  if (newYear != null) {
                                    _selectedYear = newYear;
                                    _filterByMonth(
                                        _selectedYear, _selectedMonth);
                                  }
                                },
                                items: List.generate(
                                  5,
                                  (index) {
                                    final year = (DateTime.now().year - index)
                                        .toString();
                                    return DropdownMenuItem<String>(
                                      value: year,
                                      child: Text(year),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Month Dropdown
                          Column(
                            children: [
                              const Text(
                                'Month',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _selectedMonth,
                                hint: const Text("Select Month"),
                                onChanged: (String? newMonth) {
                                  if (newMonth != null) {
                                    _selectedMonth = newMonth;
                                    _filterByMonth(
                                        _selectedYear, _selectedMonth);
                                  }
                                },
                                // items: List.generate(12, (index) {
                                //   final month =
                                //       (index + 1).toString().padLeft(2, '0');
                                //   return DropdownMenuItem<String>(
                                //     value: month,
                                //     child: Text(Helper.formatMonth(index + 1)),
                                //   );
                                // }),
                                items: Constants.monthToNumber.keys.map((key) {
                                  return DropdownMenuItem<String>(
                                    value: Constants.monthToNumber[key]!,
                                    child: Text(key),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // List of dates
                      Expanded(
                        child: _dates.isEmpty
                            ? const Center(
                                child: Text(
                                  'No history available for selected month.',
                                ),
                              )
                            : ListView.builder(
                                itemCount: _dates.length,
                                itemBuilder: (context, index) {
                                  final date = _dates[index];
                                  return ListTile(
                                    title: Text(Helper.formatDateString(date)),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      _showItemsBottomSheet(date);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
