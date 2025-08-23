import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import '../models/buy_product.dart';
import '../models/category.dart';
import '../services/buy_product_service.dart';
import '../services/google_auth_service.dart';
import '../services/storage_test_service.dart';
import '../services/category_service.dart';

class AddBuyProductScreen extends StatefulWidget {
  final BuyProduct? productToEdit;
  
  const AddBuyProductScreen({super.key, this.productToEdit});

  @override
  State<AddBuyProductScreen> createState() => _AddBuyProductScreenState();
}

class _AddBuyProductScreenState extends State<AddBuyProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _featuresController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _warrantyController = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedCondition = 'new';
  List<Category> _categories = [];
  File? _selectedImage;
  bool _isLoading = false;
  bool _loadingCategories = true;
  
  final ImagePicker _picker = ImagePicker();
  final List<String> _conditionOptions = ['new', 'used', 'refurbished'];

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
    _brandController.text = product.brand;
    _featuresController.text = product.features.join('\n');
    _specificationsController.text = _formatSpecifications(product.specifications);
    _stockQuantityController.text = product.stockQuantity.toString();
    _warrantyController.text = product.warranty;
    _selectedCondition = product.condition;
    
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
  }

  String _formatSpecifications(Map<String, dynamic> specs) {
    return specs.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }

  Map<String, dynamic> _parseSpecifications(String text) {
    final Map<String, dynamic> specs = {};
    final lines = text.split('\n');
    
    for (String line in lines) {
      if (line.trim().isNotEmpty && line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          specs[key] = value;
        }
      }
    }
    
    return specs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _featuresController.dispose();
    _specificationsController.dispose();
    _stockQuantityController.dispose();
    _warrantyController.dispose();
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
      final currentUser = GoogleAuthService.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      // Parse features
      final features = _featuresController.text
          .split('\n')
          .where((feature) => feature.trim().isNotEmpty)
          .toList();

      // Parse specifications
      final specifications = _parseSpecifications(_specificationsController.text);

      bool success;
      if (widget.productToEdit != null) {
        // Editing existing product
        final updatedProduct = BuyProduct(
          id: widget.productToEdit!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          imageUrl: widget.productToEdit!.imageUrl, // Keep existing image URL
          category: _selectedCategory,
          brand: _brandController.text.trim(),
          rating: widget.productToEdit!.rating,
          reviewCount: widget.productToEdit!.reviewCount,
          features: features,
          specifications: specifications,
          ownerId: widget.productToEdit!.ownerId,
          ownerName: widget.productToEdit!.ownerName,
          createdAt: widget.productToEdit!.createdAt,
          updatedAt: DateTime.now(),
          isAvailable: widget.productToEdit!.isAvailable,
          stockQuantity: int.parse(_stockQuantityController.text.trim()),
          condition: _selectedCondition,
          warranty: _warrantyController.text.trim(),
          additionalImages: widget.productToEdit!.additionalImages,
        );

        success = await BuyProductService.updateProduct(updatedProduct.id, updatedProduct);
        
        if (success && mounted) {
          print('AddBuyProductScreen: Product updated successfully, returning true');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          print('AddBuyProductScreen: Failed to update product, success: $success');
          _showErrorSnackBar('Failed to update product. Please try again.');
        }
      } else {
        // Creating new product
        final productId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Generate random rating between 4.0 and 5.0
        final random = Random();
        final randomRating = 4.0 + random.nextDouble(); // 4.0 to 5.0
        final randomReviewCount = 5 + random.nextInt(46); // 5 to 50 reviews
        
        final product = BuyProduct(
          id: productId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          imageUrl: '', // Will be set after upload
          category: _selectedCategory,
          brand: _brandController.text.trim(),
          rating: double.parse(randomRating.toStringAsFixed(1)), // Round to 1 decimal place
          reviewCount: randomReviewCount,
          features: features,
          specifications: specifications,
          ownerId: currentUser.id,
          ownerName: currentUser.name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isAvailable: true,
          stockQuantity: int.parse(_stockQuantityController.text.trim()),
          condition: _selectedCondition,
          warranty: _warrantyController.text.trim(),
          additionalImages: [],
        );

        final addedId = await BuyProductService.addProductWithImage(product, _selectedImage);
        success = addedId != null;
        
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
          widget.productToEdit != null ? 'Edit Buy Product' : 'Add New Buy Product',
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

              // Brand
              _buildTextField(
                controller: _brandController,
                label: 'Brand',
                hint: 'Enter brand name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter brand name';
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

              // Condition Dropdown
              const Text(
                'Condition',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
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
                items: _conditionOptions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Price
              _buildTextField(
                controller: _priceController,
                label: 'Price (\$)',
                hint: 'Enter product price',
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

              // Stock Quantity
              _buildTextField(
                controller: _stockQuantityController,
                label: 'Stock Quantity',
                hint: 'Enter available quantity',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) < 0) {
                    return 'Stock quantity cannot be negative';
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

              // Features
              _buildTextField(
                controller: _featuresController,
                label: 'Features',
                hint: 'Enter features (one per line)\ne.g.:\nWireless connectivity\nHigh resolution display\nLong battery life',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter features';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Specifications
              _buildTextField(
                controller: _specificationsController,
                label: 'Specifications',
                hint: 'Enter specifications (key: value format)\ne.g.:\nDisplay: 6.1 inch OLED\nStorage: 128GB\nRAM: 8GB',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter specifications';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Warranty
              _buildTextField(
                controller: _warrantyController,
                label: 'Warranty',
                hint: 'Enter warranty information\ne.g.: 2 years manufacturer warranty',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter warranty information';
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
