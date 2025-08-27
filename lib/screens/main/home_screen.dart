import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tong/providers/theme_provider.dart';
import 'package:tong/repository/auth_service.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:tong/screens/main/category/list_category_screen.dart';
import 'package:tong/services/connectivity_service.dart';
import 'package:tong/utils/constants.dart';
import 'package:tong/utils/theme.dart';
import 'package:tong/widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Logger _logger = Logger('HomeScreen');

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;

  Map<String, dynamic> _todaysData = {};
  Map<String, dynamic> _categories = {};
  bool isLoading = true;
  bool isRefreshing = false;
  String error = '';
  double _totalAmount = 0.0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _initializeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await _checkUser();
      await _fetchCategories();
      await _fetchTodaysData();

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      _logger.severe('Initialization failed: $e');
      setState(() {
        isLoading = false;
        error = 'Error initializing data: $e';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
      error = '';
    });

    try {
      await _fetchCategories();
      await _fetchTodaysData();
    } catch (e) {
      setState(() {
        error = 'Error refreshing data: $e';
      });
    } finally {
      setState(() {
        isRefreshing = false;
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
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
    final connectivityService = Provider.of<ConnectivityService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.appName),
        actions: [
          // Theme toggle
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          // Sync status widget
          const SyncStatusWidget(),
          // Refresh
          IconButton(
            onPressed: isRefreshing ? null : _refreshData,
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          // Categories
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(CategoryListScreen.routeName);
            },
            icon: const Icon(Icons.list_alt_outlined),
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : error.isNotEmpty
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('MMMM d, yyyy').format(now);
    final String dayOfWeek = DateFormat('EEEE').format(now);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(formattedDate, dayOfWeek),
                const SizedBox(height: 24),
                _buildCategoriesSection(),
                const SizedBox(height: 24),
                _buildTotalSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String formattedDate, String dayOfWeek) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi ${_user?.displayName?.split(' ').first ?? 'User'}! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dayOfWeek, $formattedDate',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildCategoriesSection() {
    if (_categories.isEmpty) {
      return _buildEmptyCategoriesWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Expenses',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final categoryId = _categories.keys.elementAt(index);
            final categoryData = _categories[categoryId];
            final itemCount = _todaysData[categoryId] ?? 0;
            final categoryTitle = categoryData['title'];
            final categoryPrice = categoryData['price'];

            return _buildCategoryCard(
              categoryId,
              categoryTitle,
              categoryPrice,
              itemCount,
              index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyCategoriesWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add some categories to start tracking your expenses',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(CategoryListScreen.routeName);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Categories'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String categoryId,
    String categoryTitle,
    dynamic categoryPrice,
    int itemCount,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳${categoryPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCounterButton(
                    icon: Icons.remove,
                    onTap: () => _decrementItemCount(categoryId),
                    isEnabled: itemCount > 0,
                  ),
                  Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      itemCount.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildCounterButton(
                    icon: Icons.add,
                    onTap: () => _incrementItemCount(categoryId),
                    isEnabled: true,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '৳${(categoryPrice * itemCount).toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Today',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '৳${_totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
