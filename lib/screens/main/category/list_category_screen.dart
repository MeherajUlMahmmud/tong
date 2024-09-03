import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tong/screens/main/category/add_edit_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  static const routeName = '/category';

  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, dynamic> _categories = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AddEditCategoryScreen.routeName);
        },
        child: const Icon(Icons.add),
      ),
      body: _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCategories,
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final categoryId = _categories.keys.elementAt(index);

                  final categoryData = _categories[categoryId];

                  final categoryTitle = categoryData['title'];
                  final categoryPrice = categoryData['price'];

                  return ListTile(
                    title: Text(categoryTitle),
                    subtitle: Text('Price: \$$categoryPrice'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                    ),
                    onTap: () {
                      // Handle tap on category item
                      Navigator.of(context).pushNamed(
                        AddEditCategoryScreen.routeName,
                        arguments: categoryId,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
