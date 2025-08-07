import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/storage_test_service.dart';
import '../services/category_service.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit;
  
  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _specsController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedCategory = '';
  List<Category> _categories = [];
  File? _selectedImage;
  bool _isLoading = false;
  bool _loadingCategories = true;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });

    try {
      final categories = await CategoryService.getActiveCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          
          // After categories are loaded, populate fields for editing
          if (widget.productToEdit != null) {
            _populateFieldsForEditing();
          } else if (_categories.isNotEmpty && _selectedCategory.isEmpty) {
            _selectedCategory = _categories.first.name;
          }
          
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
        _showErrorSnackBar('Error loading categories: $e');
      }
    }
  }

  void _populateFieldsForEditing() {
    final product = widget.productToEdit!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _specsController.text = product.specifications.join('\n');
    _tagsController.text = product.tags.join(', ');
    
    // Only set category if it exists in the loaded categories
    if (_categories.any((cat) => cat.name == product.category)) {
      _selectedCategory = product.category;
    } else if (_categories.isNotEmpty) {
      // If the product's category doesn't exist, default to first available category
      _selectedCategory = _categories.first.name;
      // Show a warning to the user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar('Original category "${product.category}" not found. Please select a new category.');
      });
    }
    // Note: Image loading from URL would require additional implementation
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _specsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Select Image Source', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFFD700)),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFFD700)),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate category selection
    if (_selectedCategory.isEmpty) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    // For editing, image is optional if product already has one
    if (_selectedImage == null && widget.productToEdit == null) {
      _showErrorSnackBar('Please select an image for the product');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      // Parse specifications
      final specs = _specsController.text
          .split('\n')
          .where((spec) => spec.trim().isNotEmpty)
          .toList();

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      bool success;
      if (widget.productToEdit != null) {
        // Editing existing product
        final updatedProduct = Product(
          id: widget.productToEdit!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text.trim()),
          imageUrl: widget.productToEdit!.imageUrl, // Keep existing image URL
          rating: widget.productToEdit!.rating,
          isAvailable: widget.productToEdit!.isAvailable,
          specifications: specs,
          tags: tags,
          ownerId: widget.productToEdit!.ownerId,
          createdAt: widget.productToEdit!.createdAt,
          updatedAt: DateTime.now(),
        );

        success = await ProductService.updateProduct(updatedProduct);
        
        if (success && mounted) {
          print('AddProductScreen: Product updated successfully, returning true');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          print('AddProductScreen: Failed to update product, success: $success');
          _showErrorSnackBar('Failed to update product. Please try again.');
        }
      } else {
        // Creating new product
        final productId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final product = Product(
          id: productId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text.trim()),
          imageUrl: '', // Will be set after upload
          rating: 0.0,
          isAvailable: true,
          specifications: specs,
          tags: tags,
          ownerId: currentUser.id,
          createdAt: DateTime.now(),
        );

        success = await ProductService.addProduct(product, _selectedImage!);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to add product. Please try again.');
        }
      }
    } catch (e) {
      print('Exception in _submitProduct: $e');
      _showErrorSnackBar('Error ${widget.productToEdit != null ? 'updating' : 'adding'} product: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testStorageConnection() async {
    try {
      final isConnected = await StorageTestService.testStorageConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected 
                  ? 'Storage connection: OK' 
                  : 'Storage connection: FAILED'
            ),
            backgroundColor: isConnected ? Colors.green : Colors.red,
          ),
        );
      }
      
      if (isConnected && _selectedImage != null) {
        final testResult = await StorageTestService.testImageUpload(_selectedImage!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                testResult != null 
                    ? 'Test upload: SUCCESS' 
                    : 'Test upload: FAILED'
              ),
              backgroundColor: testResult != null ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.productToEdit != null ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_selectedImage != null)
            IconButton(
              onPressed: _testStorageConnection,
              icon: const Icon(Icons.bug_report),
              tooltip: 'Test Storage',
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              const Text(
                'Product Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: Color(0xFFFFD700),
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add image',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Product Name
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'Enter product name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              const Text(
                'Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _loadingCategories || _selectedCategory.isEmpty || !_categories.any((cat) => cat.name == _selectedCategory) 
                    ? null 
                    : _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
                items: _loadingCategories
                    ? []
                    : _categories.map((category) {
                        return DropdownMenuItem(
                          value: category.name,
                          child: Text(category.name),
                        );
                      }).toList(),
                onChanged: _loadingCategories
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                hint: _loadingCategories
                    ? const Text(
                        'Loading categories...',
                        style: TextStyle(color: Colors.grey),
                      )
                    : const Text(
                        'Select Category',
                        style: TextStyle(color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 16),

              // Price
              _buildTextField(
                controller: _priceController,
                label: 'Price per Day (\$)',
                hint: 'Enter daily rental price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter product description',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Specifications
              _buildTextField(
                controller: _specsController,
                label: 'Specifications',
                hint: 'Enter specifications (one per line)\ne.g.:\n24.2MP Full Frame\nISO 100-51200\n4K Video Recording',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter specifications';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tags
              _buildTextField(
                controller: _tagsController,
                label: 'Tags',
                hint: 'Enter tags separated by commas\ne.g.: professional, full-frame, video',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter tags';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        )
                      : Text(
                          widget.productToEdit != null ? 'Update Product' : 'Add Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
