import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:tong/services/connectivity_service.dart';
import 'package:tong/services/local_database_service.dart';

class SyncService {
  final Logger _logger = Logger('SyncService');
  final FirestoreService _firestoreService = FirestoreService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final Connectivity _connectivity = Connectivity();

  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  void initialize() {
    _logger.info('Initializing SyncService');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          _logger.info('Internet connection restored, starting sync');
          _startPeriodicSync();
          _syncAllData();
        } else {
          _logger.info('Internet connection lost, stopping sync');
          _stopPeriodicSync();
        }
      },
    );

    // Start periodic sync if connected
    if (_connectivityService.isConnected) {
      _startPeriodicSync();
      _syncAllData();
    }
  }

  void _startPeriodicSync() {
    _stopPeriodicSync(); // Stop existing timer if any

    // Sync every 5 minutes when online
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_connectivityService.isConnected && !_isSyncing) {
        _syncAllData();
      }
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _syncAllData() async {
    if (_isSyncing) {
      _logger.info('Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;
    _logger.info('Starting data synchronization');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.warning('No user logged in, skipping sync');
        return;
      }

      // Sync categories first
      await _syncCategories(user.uid);

      // Sync daily data
      await _syncDailyData(user.uid);

      // Process sync queue
      await _processSyncQueue();

      _logger.info('Data synchronization completed successfully');
    } catch (e) {
      _logger.severe('Error during data synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCategories(String userId) async {
    try {
      _logger.info('Syncing categories');

      // Get local categories
      final localCategories = await LocalDatabaseService.getCategories(userId);

      // Get remote categories
      final remoteCategories = await _firestoreService.fetchCategories();

      // Merge and sync
      for (final localCategory in localCategories) {
        final categoryId = localCategory['id'];
        final remoteCategory = remoteCategories[categoryId];

        if (remoteCategory == null) {
          // Category exists locally but not remotely - add to sync queue
          await LocalDatabaseService.addToSyncQueue(
            'CREATE',
            'categories',
            localCategory,
          );
        } else {
          // Compare timestamps to determine which is newer
          final localUpdated = DateTime.parse(localCategory['updatedAt']);
          final remoteUpdated = DateTime.parse(remoteCategory['updatedAt']);

          if (localUpdated.isAfter(remoteUpdated)) {
            // Local is newer - update remote
            await LocalDatabaseService.addToSyncQueue(
              'UPDATE',
              'categories',
              localCategory,
            );
          } else if (remoteUpdated.isAfter(localUpdated)) {
            // Remote is newer - update local
            await LocalDatabaseService.updateCategory(remoteCategory);
          }
        }
      }

      // Add new remote categories to local
      for (final entry in remoteCategories.entries) {
        final categoryId = entry.key;
        final remoteCategory = entry.value;

        final localExists =
            localCategories.any((cat) => cat['id'] == categoryId);
        if (!localExists) {
          await LocalDatabaseService.insertCategory({
            'id': categoryId,
            ...remoteCategory,
          });
        }
      }
    } catch (e) {
      _logger.severe('Error syncing categories: $e');
    }
  }

  Future<void> _syncDailyData(String userId) async {
    try {
      _logger.info('Syncing daily data');

      // Get unsynced local data
      final unsyncedData = await LocalDatabaseService.getUnsyncedData();

      for (final data in unsyncedData) {
        try {
          // Sync to Firebase
          await _firestoreService.updateItemCount(
            data['categoryId'],
            data['count'],
          );

          // Mark as synced
          await LocalDatabaseService.markAsSynced(data['id']);

          _logger.info(
              'Synced daily data: ${data['date']} - ${data['categoryId']}');
        } catch (e) {
          _logger.warning('Failed to sync daily data: $e');
        }
      }
    } catch (e) {
      _logger.severe('Error syncing daily data: $e');
    }
  }

  Future<void> _processSyncQueue() async {
    try {
      _logger.info('Processing sync queue');

      final syncQueue = await LocalDatabaseService.getSyncQueue();

      for (final item in syncQueue) {
        try {
          final operation = item['operation'];
          final tableName = item['tableName'];
          final data = item['data'];

          switch (operation) {
            case 'CREATE':
              await _processCreateOperation(tableName, data);
              break;
            case 'UPDATE':
              await _processUpdateOperation(tableName, data);
              break;
            case 'DELETE':
              await _processDeleteOperation(tableName, data);
              break;
          }

          // Remove from sync queue after successful processing
          await LocalDatabaseService.removeFromSyncQueue(item['id']);

          _logger.info('Processed sync queue item: $operation $tableName');
        } catch (e) {
          _logger.warning('Failed to process sync queue item: $e');
        }
      }
    } catch (e) {
      _logger.severe('Error processing sync queue: $e');
    }
  }

  Future<void> _processCreateOperation(
      String tableName, Map<String, dynamic> data) async {
    switch (tableName) {
      case 'categories':
        await _firestoreService.addCategory(
          data['title'],
          data['price'],
          data['userId'],
        );
        break;
      case 'daily_data':
        await _firestoreService.updateItemCount(
          data['categoryId'],
          data['count'],
        );
        break;
    }
  }

  Future<void> _processUpdateOperation(
      String tableName, Map<String, dynamic> data) async {
    switch (tableName) {
      case 'categories':
        await _firestoreService.updateCategory(
          data['id'],
          data['title'],
          data['price'],
        );
        break;
      case 'daily_data':
        await _firestoreService.updateItemCount(
          data['categoryId'],
          data['count'],
        );
        break;
    }
  }

  Future<void> _processDeleteOperation(
      String tableName, Map<String, dynamic> data) async {
    switch (tableName) {
      case 'categories':
        await _firestoreService.deleteCategory(data['id']);
        break;
    }
  }

  // Public methods for manual sync
  Future<void> syncNow() async {
    _logger.info('Manual sync requested');
    await _syncAllData();
  }

  Future<void> syncCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _syncCategories(user.uid);
    }
  }

  Future<void> syncDailyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _syncDailyData(user.uid);
    }
  }

  // Check sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final unsyncedData = await LocalDatabaseService.getUnsyncedData();
      final syncQueue = await LocalDatabaseService.getSyncQueue();

      return {
        'isOnline': _connectivityService.isConnected,
        'isSyncing': _isSyncing,
        'unsyncedItems': unsyncedData.length,
        'queuedOperations': syncQueue.length,
        'lastSync': DateTime.now()
            .toIso8601String(), // In real app, store this in SharedPreferences
      };
    } catch (e) {
      _logger.severe('Error getting sync status: $e');
      return {
        'isOnline': false,
        'isSyncing': false,
        'unsyncedItems': 0,
        'queuedOperations': 0,
        'lastSync': null,
      };
    }
  }

  void dispose() {
    _stopPeriodicSync();
    _connectivitySubscription?.cancel();
    _logger.info('SyncService disposed');
  }
}
