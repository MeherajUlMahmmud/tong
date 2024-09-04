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
          .orderBy('title')
          .get();

      setState(() {
        _categories.clear();
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          _categories[doc.id] = doc.data();
        }
      });

      print("Products fetched: ${_categories.length}");
    } catch (e) {
      print('Error fetching Product: $e');
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();

      setState(() {
        _categories.remove(categoryId);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      print('Error deleting category: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete Product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AddEditCategoryScreen.routeName,
                              arguments: categoryId,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Product'),
                                content: const Text(
                                    'Are you sure you want to delete this Product?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete == true) {
                              _deleteCategory(categoryId);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
