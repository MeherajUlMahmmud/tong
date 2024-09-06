import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  Future<Map<String, dynamic>> fetchCategories() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
          .get();

      final Map<String, dynamic> categories = {};
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        categories[doc.id] = doc.data();
      }
      return categories;
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }

  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('categories').doc(categoryId).get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
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
      await _firestore.collection('categories').doc(categoryId).update({
        'title': title,
        'price': price,
      });
    } catch (e) {
      throw Exception('Error updating category: $e');
    }
  }

  Future<void> addCategory(String title, double price, String userId) async {
    try {
      await _firestore.collection('categories').add({
        'title': title,
        'price': price,
        'userId': userId,
      });
    } catch (e) {
      throw Exception('Error adding category: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchDailyData(String date) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final DocumentReference userDoc = _firestore
        .collection('daily_data')
        .doc(user.uid)
        .collection('dates')
        .doc(date);

    try {
      DocumentSnapshot docSnapshot = await userDoc.get();
      return docSnapshot.exists
          ? docSnapshot.data() as Map<String, dynamic>?
          : null;
    } catch (e) {
      throw Exception('Error fetching today\'s data: $e');
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
      throw Exception('Error fetching today\'s data: $e');
    }
  }

  Future<void> initializeTodaysData() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final String today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final DocumentReference userDoc = _firestore
        .collection('daily_data')
        .doc(user.uid)
        .collection('dates')
        .doc(today);

    try {
      await userDoc.set({'11': 11});
    } catch (e) {
      throw Exception('Error initializing today\'s data: $e');
    }
  }

  Future<void> updateItemCount(String categoryId, int count) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final String today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final DocumentReference userDoc = _firestore
        .collection('daily_data')
        .doc(user.uid)
        .collection('dates')
        .doc(today);

    try {
      await userDoc.update({categoryId: count});
    } catch (e) {
      throw Exception('Error updating item count in Firestore: $e');
    }
  }

  Future<List<String>> fetchDates(String yearMonth) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('daily_data')
          .doc(user.uid)
          .collection('dates')
          // Match month
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: yearMonth)
          // To ensure it stays within the selected month
          .where(FieldPath.documentId, isLessThan: '${yearMonth}z')
          // Latest dates first
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      List<String> fetchedDates = [];

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        fetchedDates.add(doc.id); // Assuming doc.id is the date string
      }
      return fetchedDates;
    } catch (e) {
      throw Exception('Error fetching dates from Firestore: $e');
    }
  }
}
