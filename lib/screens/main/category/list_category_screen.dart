import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:tong/screens/main/category/add_edit_category_screen.dart';
import 'package:tong/utils/constants.dart';

class CategoryListScreen extends StatefulWidget {
  static const routeName = '/category';

  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final Logger _logger = Logger('CategoryListScreen');

  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic> _categories = {};
  final Map<String, bool> _expandedCategories = {}; // Track expanded state

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _logger.info('Fetching categories...');

      _categories = await _firestoreService.fetchCategories();
      setState(() {});

      _logger.info('Categories fetched: ${_categories.length}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      await _firestoreService.deleteCategory(categoryId);
      _loadCategories(); // Refresh categories after deletion
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ScreenTitles.categoryList),
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
              onRefresh: _loadCategories,
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final categoryId = _categories.keys.elementAt(index);
                  final categoryData = _categories[categoryId];
                  final categoryTitle = categoryData['title'];
                  final categoryPrice = categoryData['price'];

                  // Check if this category is expanded
                  bool isExpanded = _expandedCategories[categoryId] ?? false;

                  return Column(
                    children: [
                      ListTile(
                        title: Text(categoryTitle),
                        subtitle: Text('৳ $categoryPrice'),
                        trailing: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                        onTap: () {
                          setState(() {
                            _expandedCategories[categoryId] = !isExpanded;
                          });
                        },
                      ),
                      if (isExpanded) // Show buttons if expanded
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    AddEditCategoryScreen.routeName,
                                    arguments: categoryId,
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Update'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  final confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Category'),
                                      content: const Text(
                                          'Are you sure you want to delete this Category?'),
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
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
