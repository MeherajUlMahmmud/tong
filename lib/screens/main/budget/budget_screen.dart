import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tong/providers/theme_provider.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:tong/utils/theme.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  static const routeName = '/budget';

  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic> _categories = {};
  Map<String, double> _budgets = {};
  Map<String, double> _spent = {};
  bool isLoading = true;
  String selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _fetchCategories();
      await _fetchBudgets();
      await _fetchSpentAmounts();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    _categories = await _firestoreService.fetchCategories();
  }

  Future<void> _fetchBudgets() async {
    // Mock data - in real app, fetch from Firestore
    _budgets = {
      'food': 3000.0,
      'transport': 1500.0,
      'shopping': 2000.0,
      'entertainment': 1000.0,
      'bills': 1200.0,
    };
  }

  Future<void> _fetchSpentAmounts() async {
    // Mock data - in real app, calculate from actual spending
    _spent = {
      'food': 2500.0,
      'transport': 1200.0,
      'shopping': 1800.0,
      'entertainment': 800.0,
      'bills': 900.0,
    };
  }

  void _showBudgetDialog(String categoryId, String categoryName) {
    final currentBudget = _budgets[categoryId] ?? 0.0;
    final controller = TextEditingController(text: currentBudget.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for $categoryName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                prefixText: '৳',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newBudget = double.tryParse(controller.text) ?? 0.0;
              setState(() {
                _budgets[categoryId] = newBudget;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Tracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
              });
              _loadData();
            },
            itemBuilder: (context) =>
                ['This Week', 'This Month', 'This Year'].map((period) {
              return PopupMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildBudgetList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalBudget =
        _budgets.values.fold<double>(0, (sum, budget) => sum + budget);
    final totalSpent =
        _spent.values.fold<double>(0, (sum, spent) => sum + spent);
    final remaining = totalBudget - totalSpent;
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Total Budget',
                    value: '৳${totalBudget.toStringAsFixed(0)}',
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Total Spent',
                    value: '৳${totalSpent.toStringAsFixed(0)}',
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Remaining',
                    value: '৳${remaining.toStringAsFixed(0)}',
                    color: remaining >= 0
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Used',
                    value: '${percentage.toStringAsFixed(1)}%',
                    color: percentage > 80
                        ? AppTheme.warningColor
                        : AppTheme.infoColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (percentage / 100).toDouble(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 80 ? AppTheme.warningColor : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildBudgetList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Budgets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._categories.entries.map((entry) {
          final categoryId = entry.key;
          final categoryData = entry.value;
          final categoryName = categoryData['title'];
          final budget = _budgets[categoryId] ?? 0.0;
          final spent = _spent[categoryId] ?? 0.0;
          final remaining = budget - spent;
          final percentage = budget > 0 ? (spent / budget) * 100 : 0;

          return _buildBudgetCard(
            categoryId: categoryId,
            categoryName: categoryName,
            budget: budget,
            spent: spent,
            remaining: remaining,
            percentage: percentage,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBudgetCard({
    required String categoryId,
    required String categoryName,
    required double budget,
    required double spent,
    required double remaining,
    required double percentage,
  }) {
    final isOverBudget = remaining < 0;
    final isNearLimit = percentage > 80;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBudgetDialog(categoryId, categoryName),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBudgetItem(
                      title: 'Budget',
                      value: '৳${budget.toStringAsFixed(0)}',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBudgetItem(
                      title: 'Spent',
                      value: '৳${spent.toStringAsFixed(0)}',
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBudgetItem(
                      title: 'Remaining',
                      value: '৳${remaining.toStringAsFixed(0)}',
                      color: isOverBudget
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (percentage / 100).toDouble(),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget
                            ? AppTheme.errorColor
                            : isNearLimit
                                ? AppTheme.warningColor
                                : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isOverBudget
                              ? AppTheme.errorColor
                              : isNearLimit
                                  ? AppTheme.warningColor
                                  : AppTheme.primaryColor,
                        ),
                  ),
                ],
              ),
              if (isOverBudget) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Over budget by ৳${(-remaining).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else if (isNearLimit) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Near budget limit',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (100 * _categories.keys.toList().indexOf(categoryId)).ms)
        .slideX(begin: 0.3, end: 0);
  }

  Widget _buildBudgetItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
