import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tong/providers/theme_provider.dart';
import 'package:tong/repository/auth_service.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:tong/screens/auth/login_screen.dart';
import 'package:tong/screens/main/budget/budget_screen.dart';
import 'package:tong/services/export_service.dart';
import 'package:tong/services/sync_service.dart';
import 'package:tong/utils/constants.dart';
import 'package:tong/utils/theme.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Logger _logger = Logger('ProfileScreen');
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ExportService _exportService = ExportService();
  final SyncService _syncService = SyncService();

  User? _user;
  Map<String, dynamic> _userStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser;
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      // Mock user stats - in real app, fetch from Firestore
      _userStats = {
        'totalExpenses': 15000.0,
        'totalDays': 45,
        'averageDaily': 333.33,
        'categoriesCount': 8,
        'joinDate': DateTime.now().subtract(const Duration(days: 45)),
      };
    } catch (e) {
      _logger.severe('Error loading user stats: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportData('csv');
            },
            child: const Text('CSV'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportData('json');
            },
            child: const Text('JSON'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String format) async {
    try {
      final startDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 30)));
      final endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (format == 'csv') {
        await _exportService.exportToCSV(startDate, endDate);
      } else {
        await _exportService.exportToJSON(startDate, endDate);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data exported successfully as $format')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: Constants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        Constants.tongDokanImage,
        width: 50,
        height: 50,
      ),
      children: [
        const Text(
          'টং is a simple and intuitive expense tracking app designed to help you manage your daily expenses efficiently.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n• Daily expense tracking\n• Category management\n• Analytics and insights\n• Budget tracking\n• Data export\n• Offline support with automatic sync',
        ),
      ],
    );
  }

  Future<void> _manualSync() async {
    try {
      await _syncService.syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data synchronized successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      _logger.info('Logging out...');
      await _authService.signOut();

      // Sign out from Google account
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      _logger.info('Logged out');

      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _showAboutDialog,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 24),
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildSettingsCard(themeProvider),
                  const SizedBox(height: 24),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _user?.photoURL ?? 'https://via.placeholder.com/150',
              ),
            ).animate().scale(duration: 600.ms),
            const SizedBox(height: 16),
            Text(
              _user?.displayName ?? 'No Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              _user?.email ?? 'No Email',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Member since ${DateFormat('MMM yyyy').format(_userStats['joinDate'] ?? DateTime.now())}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: 'Total Spent',
                    value:
                        '৳${_userStats['totalExpenses']?.toStringAsFixed(0) ?? '0'}',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    title: 'Days Tracked',
                    value: '${_userStats['totalDays'] ?? 0}',
                    icon: Icons.calendar_today,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: 'Daily Average',
                    value:
                        '৳${_userStats['averageDaily']?.toStringAsFixed(0) ?? '0'}',
                    icon: Icons.trending_up,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    title: 'Categories',
                    value: '${_userStats['categoriesCount'] ?? 0}',
                    icon: Icons.category,
                    color: AppTheme.infoColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsCard(ThemeProvider themeProvider) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Toggle dark/light theme',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
              ),
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.account_balance_wallet,
              title: 'Budget Tracker',
              subtitle: 'Set and monitor spending limits',
              onTap: () =>
                  Navigator.of(context).pushNamed(BudgetScreen.routeName),
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.download,
              title: 'Export Data',
              subtitle: 'Export your expense data',
              onTap: _showExportDialog,
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.sync,
              title: 'Sync Data',
              subtitle: 'Manually sync with cloud',
              onTap: _manualSync,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.3, end: 0);
  }
}
