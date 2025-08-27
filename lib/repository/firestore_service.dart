import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:tong/services/connectivity_service.dart';
import 'package:tong/services/local_database_service.dart';
import 'package:tong/services/sync_service.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();
  final Logger _logger = Logger('FirestoreService');

  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  Future<Map<String, dynamic>> fetchCategories() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firebase when online
        _logger.info('Fetching categories from Firebase');
        QuerySnapshot querySnapshot = await _firestore
            .collection('categories')
            .where('userId', isEqualTo: user.uid)
            .get();

        final Map<String, dynamic> categories = {};
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          categories[doc.id] = doc.data();
        }

        // Store in local database for offline access
        for (final entry in categories.entries) {
          await LocalDatabaseService.insertCategory({
            'id': entry.key,
            ...entry.value,
          });
        }

        return categories;
      } else {
        // Fetch from local database when offline
        _logger.info('Fetching categories from local database');
        final localCategories =
            await LocalDatabaseService.getCategories(user.uid);

        final Map<String, dynamic> categories = {};
        for (final category in localCategories) {
          categories[category['id']] = {
            'title': category['title'],
            'price': category['price'],
            'userId': category['userId'],
          };
        }

        return categories;
      }
    } catch (e) {
      _logger.severe('Error fetching categories: $e');

      // Fallback to local database
      try {
        final localCategories =
            await LocalDatabaseService.getCategories(user.uid);
        final Map<String, dynamic> categories = {};
        for (final category in localCategories) {
          categories[category['id']] = {
            'title': category['title'],
            'price': category['price'],
            'userId': category['userId'],
          };
        }
        return categories;
      } catch (localError) {
        throw Exception('Error fetching categories: $e');
      }
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      if (_connectivityService.isConnected) {
        // Delete from Firebase when online
        await _firestore.collection('categories').doc(categoryId).delete();
      }

      // Always delete from local database
      await LocalDatabaseService.deleteCategory(categoryId);

      // Add to sync queue for offline scenarios
      if (!_connectivityService.isConnected) {
        await LocalDatabaseService.addToSyncQueue(
          'DELETE',
          'categories',
          {'id': categoryId},
        );
      }
    } catch (e) {
      _logger.severe('Error deleting category: $e');
      throw Exception('Error deleting category: $e');
    }
  }

  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      if (_connectivityService.isConnected) {
        DocumentSnapshot doc =
            await _firestore.collection('categories').doc(categoryId).get();
        return doc.exists ? doc.data() as Map<String, dynamic>? : null;
      } else {
        // Get from local database when offline
        final localCategories = await LocalDatabaseService.getCategories(
            _auth.currentUser?.uid ?? '');
        final category = localCategories.firstWhere(
          (cat) => cat['id'] == categoryId,
          orElse: () => {},
        );
        return category.isNotEmpty ? category : null;
      }
    } catch (e) {
      _logger.severe('Error fetching category: $e');
      throw Exception('Error fetching category: $e');
    }
  }

  double getCategoryPrice(Map<String, dynamic> categories, String categoryId) {
    dynamic priceData = categories[categoryId]['price'];
    if (priceData is double) {
      return priceData;
    } else if (priceData is int) {
      return priceData.toDouble();
    } else if (priceData is String) {
      return double.tryParse(priceData) ?? 0.0;
    } else {
      throw Exception('Invalid price type for category $categoryId');
    }
  }

  Future<void> updateCategory(
      String categoryId, String title, double price) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (_connectivityService.isConnected) {
        // Update Firebase when online
        await _firestore.collection('categories').doc(categoryId).update({
          'title': title,
          'price': price,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      // Always update local database
      await LocalDatabaseService.updateCategory({
        'id': categoryId,
        'title': title,
        'price': price,
        'userId': user.uid,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Add to sync queue for offline scenarios
      if (!_connectivityService.isConnected) {
        await LocalDatabaseService.addToSyncQueue(
          'UPDATE',
          'categories',
          {
            'id': categoryId,
            'title': title,
            'price': price,
            'userId': user.uid,
          },
        );
      }
    } catch (e) {
      _logger.severe('Error updating category: $e');
      throw Exception('Error updating category: $e');
    }
  }

  Future<void> addCategory(String title, double price, String userId) async {
    try {
      if (_connectivityService.isConnected) {
        // Add to Firebase when online
        final docRef = await _firestore.collection('categories').add({
          'title': title,
          'price': price,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Store in local database with the generated ID
        await LocalDatabaseService.insertCategory({
          'id': docRef.id,
          'title': title,
          'price': price,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Generate a temporary ID for offline use
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        // Store in local database
        await LocalDatabaseService.insertCategory({
          'id': tempId,
          'title': title,
          'price': price,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Add to sync queue
        await LocalDatabaseService.addToSyncQueue(
          'CREATE',
          'categories',
          {
            'id': tempId,
            'title': title,
            'price': price,
            'userId': userId,
          },
        );
      }
    } catch (e) {
      _logger.severe('Error adding category: $e');
      throw Exception('Error adding category: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchDailyData(String date) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firebase when online
        final DocumentReference userDoc = _firestore
            .collection('daily_data')
            .doc(user.uid)
            .collection('dates')
            .doc(date);

        DocumentSnapshot docSnapshot = await userDoc.get();
        final data = docSnapshot.exists
            ? docSnapshot.data() as Map<String, dynamic>?
            : null;

        // Store in local database
        if (data != null) {
          for (final entry in data.entries) {
            if (entry.key != 'initialized') {
              await LocalDatabaseService.insertDailyData({
                'userId': user.uid,
                'date': date,
                'categoryId': entry.key,
                'count': entry.value,
                'synced': 1,
              });
            }
          }
        }

        return data;
      } else {
        // Fetch from local database when offline
        final localData =
            await LocalDatabaseService.getDailyData(user.uid, date);

        final Map<String, dynamic> data = {};
        for (final item in localData) {
          data[item['categoryId']] = item['count'];
        }

        return data.isNotEmpty ? data : null;
      }
    } catch (e) {
      _logger.severe('Error fetching daily data: $e');

      // Fallback to local database
      try {
        final localData =
            await LocalDatabaseService.getDailyData(user.uid, date);
        final Map<String, dynamic> data = {};
        for (final item in localData) {
          data[item['categoryId']] = item['count'];
        }
        return data.isNotEmpty ? data : null;
      } catch (localError) {
        throw Exception('Error fetching daily data: $e');
      }
    }
  }

  Future<DocumentSnapshot> fetchDailyDataDocument(String date) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final DocumentReference userDoc = _firestore
        .collection('daily_data')
        .doc(user.uid)
        .collection('dates')
        .doc(date);

    try {
      DocumentSnapshot docSnapshot = await userDoc.get();
      return docSnapshot;
    } catch (e) {
      _logger.severe('Error fetching daily data document: $e');
      throw Exception('Error fetching daily data document: $e');
    }
  }

  Future<void> initializeTodaysData() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final String today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    try {
      if (_connectivityService.isConnected) {
        // Initialize in Firebase when online
        final DocumentReference userDoc = _firestore
            .collection('daily_data')
            .doc(user.uid)
            .collection('dates')
            .doc(today);

        await userDoc.set({'initialized': true});
      }

      // Always initialize in local database
      await LocalDatabaseService.insertDailyData({
        'userId': user.uid,
        'date': today,
        'categoryId': 'initialized',
        'count': 1,
        'synced': _connectivityService.isConnected ? 1 : 0,
      });
    } catch (e) {
      _logger.severe('Error initializing today\'s data: $e');
      throw Exception('Error initializing today\'s data: $e');
    }
  }

  Future<void> updateItemCount(String categoryId, int count) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final String today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    try {
      // Always update local database first
      await LocalDatabaseService.insertDailyData({
        'userId': user.uid,
        'date': today,
        'categoryId': categoryId,
        'count': count,
        'synced': _connectivityService.isConnected ? 1 : 0,
      });

      if (_connectivityService.isConnected) {
        // Update Firebase when online
        final DocumentReference userDoc = _firestore
            .collection('daily_data')
            .doc(user.uid)
            .collection('dates')
            .doc(today);

        await userDoc.update({categoryId: count});
      }
      // If offline, the data will be synced when connection is restored
    } catch (e) {
      _logger.severe('Error updating item count: $e');
      throw Exception('Error updating item count: $e');
    }
  }

  Future<List<String>> fetchDates(String yearMonth) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      if (_connectivityService.isConnected) {
        // Fetch from Firebase when online
        final QuerySnapshot querySnapshot = await _firestore
            .collection('daily_data')
            .doc(user.uid)
            .collection('dates')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: yearMonth)
            .where(FieldPath.documentId, isLessThan: '${yearMonth}z')
            .orderBy(FieldPath.documentId, descending: true)
            .get();

        List<String> fetchedDates = [];
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          fetchedDates.add(doc.id);
        }
        return fetchedDates;
      } else {
        // Fetch from local database when offline
        final localData = await LocalDatabaseService.getDailyData(user.uid, '');
        final Set<String> dates = {};

        for (final item in localData) {
          final date = item['date'] as String;
          if (date.startsWith(yearMonth)) {
            dates.add(date);
          }
        }

        return dates.toList()..sort((a, b) => b.compareTo(a));
      }
    } catch (e) {
      _logger.severe('Error fetching dates: $e');
      throw Exception('Error fetching dates: $e');
    }
  }

  // Manual sync methods
  Future<void> syncData() async {
    await _syncService.syncNow();
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }
}
