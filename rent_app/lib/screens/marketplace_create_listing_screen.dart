import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/location_dropdown.dart';

class MarketplaceCreateListingScreen extends StatefulWidget {
  final MarketplaceListing? editListing;

  const MarketplaceCreateListingScreen({
    super.key,
    this.editListing,
  });

  @override
  State<MarketplaceCreateListingScreen> createState() => _MarketplaceCreateListingScreenState();
}

class _MarketplaceCreateListingScreenState extends State<MarketplaceCreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _tagsController = TextEditingController();

  MarketplaceCondition _condition = MarketplaceCondition.good;
  String _selectedCategory = 'Cameras';
  String _selectedLocation = '';
  bool _isNegotiable = false;
  bool _isLoading = false;

  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];

  final List<String> _categories = [
    'Cameras',
    'Lenses',
    'Drones',
    'Lighting',
    'Audio',
    'Accessories',
    'Tripods',
    'Filters',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editListing != null) {
      _populateForm();
    } else {
      // Set default user info
      _emailController.text = GoogleAuthService.currentUser?.email ?? '';
      _phoneController.text = GoogleAuthService.currentUser?.phone ?? '';
    }
  }

  void _populateForm() {
    final listing = widget.editListing!;
    _titleController.text = listing.title;
    _descriptionController.text = listing.description;
    _brandController.text = listing.brand;
    _priceController.text = listing.price.toString();
    _locationController.text = listing.location;
    _selectedLocation = listing.location;
    _phoneController.text = listing.contactPhone;
    _emailController.text = listing.contactEmail;
    _tagsController.text = listing.tags.join(', ');
    
    _condition = listing.condition;
    _selectedCategory = listing.category;
    _isNegotiable = listing.isNegotiable;
    _existingImageUrls = List.from(listing.imageUrls);
  }

  Future<void> _pickImages() async {
    _showImageSourceDialog();
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', Colors.red);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', Colors.red);
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
                _pickImagesFromGallery();
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

  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if location is selected
    if (_selectedLocation.isEmpty) {
      _showSnackBar('Please select a location', Colors.orange);
      return;
    }

    // Check if at least one image is provided (either new or existing)
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      _showSnackBar('Please add at least one image', Colors.orange);
      return;
    }

    if (GoogleAuthService.currentUser == null) {
      _showSnackBar('Please sign in to create a listing', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update user phone number if it's different from the current one
      final enteredPhone = _phoneController.text.trim();
      final currentPhone = GoogleAuthService.currentUser?.phone ?? '';
      
      if (enteredPhone.isNotEmpty && enteredPhone != currentPhone) {
        print('Updating user phone number from "$currentPhone" to "$enteredPhone"');
        await GoogleAuthService.updateUserProfile(phone: enteredPhone);
      }

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final listing = MarketplaceListing(
        id: widget.editListing?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim(),
        price: double.parse(_priceController.text),
        imageUrls: _existingImageUrls, // Start with existing URLs
        category: _selectedCategory,
        tags: tags,
        condition: _condition,
        location: _selectedLocation,
        contactPhone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim(),
        isNegotiable: _isNegotiable,
        sellerId: GoogleAuthService.currentUser!.id,
        sellerName: GoogleAuthService.currentUser!.name,
        sellerRating: 0.0, // Will be calculated based on reviews
        createdAt: widget.editListing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.editListing != null) {
        // Updating existing listing - pass new images if any
        final success = await MarketplaceService.updateListing(
          listing,
          newImageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        if (success) {
          _showSnackBar('Listing updated successfully!', Colors.green);
          if (mounted) {
            Navigator.pop(context, listing.id);
          }
        } else {
          throw Exception('Failed to update listing');
        }
      } else {
        // Creating new listing - pass all selected images
        final listingId = await MarketplaceService.createListing(
          listing,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        if (listingId != null) {
          _showSnackBar('Listing created successfully!', Colors.green);
          if (mounted) {
            Navigator.pop(context, listingId);
          }
        } else {
          throw Exception('Failed to create listing');
        }
      }
    } catch (e) {
      _showSnackBar('Error saving listing: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
        title: Text(widget.editListing != null ? 'Edit Listing' : 'Create Listing'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitListing,
              child: Text(
                widget.editListing != null ? 'UPDATE' : 'PUBLISH',
                style: const TextStyle(
                  color: Color(0xFF9C27B0),
                  fontWeight: FontWeight.bold,
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
              // Images Section
              const Text(
                'Photos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images
                    ..._existingImageUrls.asMap().entries.map((entry) {
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                entry.value,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key, isExisting: true),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    // New images
                    ..._selectedImages.asMap().entries.map((entry) {
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                entry.value,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    // Add Image Button
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF9C27B0),
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: Color(0xFF9C27B0),
                              size: 32,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Color(0xFF9C27B0),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Brand *',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'e.g., Canon, Nikon, Sony, DJI',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a brand';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                dropdownColor: const Color(0xFF1A1A1A),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),

              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: const InputDecoration(
                  labelText: 'Sale Price *',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Condition
              DropdownButtonFormField<MarketplaceCondition>(
                value: _condition,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Condition *',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                dropdownColor: const Color(0xFF1A1A1A),
                items: MarketplaceCondition.values.map((condition) {
                  String text;
                  switch (condition) {
                    case MarketplaceCondition.new_:
                      text = 'New';
                      break;
                    case MarketplaceCondition.excellent:
                      text = 'Excellent';
                      break;
                    case MarketplaceCondition.good:
                      text = 'Good';
                      break;
                    case MarketplaceCondition.fair:
                      text = 'Fair';
                      break;
                    case MarketplaceCondition.poor:
                      text = 'Poor';
                      break;
                  }
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(text),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _condition = value!);
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  labelStyle: TextStyle(color: Colors.grey),
                  alignLabelWithHint: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Location
              LocationDropdown(
                selectedLocation: _selectedLocation.isEmpty ? null : _selectedLocation,
                onLocationSelected: (location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                hintText: 'Select Location in Lebanon *',
              ),

              const SizedBox(height: 16),

              // Contact Info
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Will be saved to your profile',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'e.g. canon, dslr, professional',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Negotiable checkbox
              CheckboxListTile(
                title: const Text(
                  'Price is negotiable',
                  style: TextStyle(color: Colors.white),
                ),
                value: _isNegotiable,
                activeColor: const Color(0xFF9C27B0),
                onChanged: (value) {
                  setState(() => _isNegotiable = value ?? false);
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
