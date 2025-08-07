import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await CategoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading categories: $e');
      }
    }
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          isEditing ? 'Edit Category' : 'Add Category',
          style: const TextStyle(color: Colors.white),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();

                // Check if name already exists
                final nameExists = await CategoryService.categoryNameExists(
                  name,
                  excludeId: category?.id,
                );

                if (nameExists) {
                  _showErrorSnackBar('Category name already exists');
                  return;
                }

                Navigator.pop(context);

                if (isEditing) {
                  final updatedCategory = category.copyWith(
                    name: name,
                    description: description,
                    updatedAt: DateTime.now(),
                  );
                  await _updateCategory(updatedCategory);
                } else {
                  final newCategory = Category(
                    id: '',
                    name: name,
                    description: description,
                    createdAt: DateTime.now(),
                  );
                  await _addCategory(newCategory);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(Category category) async {
    final success = await CategoryService.addCategory(category);
    if (success) {
      _showSuccessSnackBar('Category added successfully');
      _loadCategories();
    } else {
      _showErrorSnackBar('Failed to add category');
    }
  }

  Future<void> _updateCategory(Category category) async {
    final success = await CategoryService.updateCategory(category);
    if (success) {
      _showSuccessSnackBar('Category updated successfully');
      _loadCategories();
    } else {
      _showErrorSnackBar('Failed to update category');
    }
  }

  void _showDeleteConfirmationDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\nThis will deactivate the category but keep it in the database.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final success = await CategoryService.deleteCategory(category.id);
    if (success) {
      _showSuccessSnackBar('Category deleted successfully');
      _loadCategories();
    } else {
      _showErrorSnackBar('Failed to delete category');
    }
  }

  Future<void> _toggleCategoryStatus(Category category) async {
    final updatedCategory = category.copyWith(
      isActive: !category.isActive,
      updatedAt: DateTime.now(),
    );

    final success = await CategoryService.updateCategory(updatedCategory);
    if (success) {
      _showSuccessSnackBar(
        category.isActive ? 'Category deactivated' : 'Category activated',
      );
      _loadCategories();
    } else {
      _showErrorSnackBar('Failed to update category status');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.fixed,
        margin: EdgeInsets.zero,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        margin: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Category Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            )
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No categories found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first category',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: category.isActive
                              ? const Color(0xFFFFD700)
                              : Colors.grey,
                          child: Icon(
                            Icons.category,
                            color: category.isActive ? Colors.black : Colors.white,
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(
                            color: category.isActive ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              category.description,
                              style: TextStyle(
                                color: category.isActive ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: category.isActive
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    category.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: category.isActive ? Colors.green : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Created: ${category.createdAt.day}/${category.createdAt.month}/${category.createdAt.year}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF2A2A2A),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditCategoryDialog(category);
                                break;
                              case 'toggle':
                                _toggleCategoryStatus(category);
                                break;
                              case 'delete':
                                _showDeleteConfirmationDialog(category);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    category.isActive ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.isActive ? 'Deactivate' : 'Activate',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
