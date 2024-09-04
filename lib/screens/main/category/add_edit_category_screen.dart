import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditCategoryScreen extends StatefulWidget {
  static const routeName = '/add-edit-category';

  const AddEditCategoryScreen({super.key});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  String? categoryId;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract arguments passed to this screen
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args != null) {
      categoryId = args;
      // Fetch category details based on the categoryId
      _loadCategoryData(categoryId!);
    }
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _user = _auth.currentUser;
    });
  }

  Future<void> _loadCategoryData(categoryId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categorySnapshot =
          await _firestore.collection('categories').doc(categoryId).get();

      if (categorySnapshot.exists) {
        final data = categorySnapshot.data()!;
        _titleController.text = data['title'];
        _priceController.text = data['price'].toString();
      }
    } catch (e) {
      // Handle error (e.g., show a snackbar or dialog)
      print('Error loading category data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      if (categoryId != null) {
        // Edit existing category
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .update({
          'title': title,
          'price': price,
        });
      } else {
        // Add new category
        await FirebaseFirestore.instance.collection('categories').add({
          'title': title,
          'price': price,
          'userId': _user!.uid,
        });
      }

      Navigator.of(context).pop();
    } catch (e) {
      // Handle error (e.g., show a snackbar or dialog)
      print('Error saving category: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryId == null ? 'Add Product' : 'Update Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Product title',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: 'Product price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _saveCategory,
                          child: Text(categoryId == null
                              ? 'Add Product'
                              : 'Save Changes'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
