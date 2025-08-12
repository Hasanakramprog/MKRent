import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/product.dart';

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'products';

  // Get all products
  static Future<List<Product>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  // Get products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      print('Getting products by category: $category');
      
      if (category == 'All') {
        return await getAllProducts();
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final products = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();

      print('Found ${products.length} products for category: $category');
      if (products.isEmpty) {
        // Debug: Show what categories actually exist
        final allProducts = await getAllProducts();
        final existingCategories = allProducts.map((p) => p.category).toSet();
        print('Existing categories in database: $existingCategories');
      }

      return products;
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  // Get products by owner
  static Future<List<Product>> getProductsByOwner(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting products by owner: $e');
      return [];
    }
  }

  // Get product by ID
  static Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      
      if (doc.exists && doc.data() != null) {
        return Product.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }

  // Search products
  static Future<List<Product>> searchProducts(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .get();

      final allProducts = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();

      // Filter products based on search query
      final lowerQuery = query.toLowerCase();
      return allProducts.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
            product.description.toLowerCase().contains(lowerQuery) ||
            product.category.toLowerCase().contains(lowerQuery) ||
            product.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Upload image to Firebase Storage
  static Future<String> _uploadImage(File imageFile, String productId) async {
    try {
      print('Starting image upload for product: $productId');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${productId}_$timestamp.jpg';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('products')
          .child(fileName);
      
      print('Upload reference path: ${storageRef.fullPath}');
      
      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'productId': productId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload the file
      print('Starting file upload...');
      final uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      print('Upload completed. State: ${snapshot.state}');
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      
      // More specific error handling
      if (e.toString().contains('object-not-found')) {
        throw Exception('Firebase Storage not properly configured. Please check your Firebase Storage rules.');
      } else if (e.toString().contains('unauthorized')) {
        throw Exception('Unauthorized access to Firebase Storage. Please check authentication.');
      } else if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check Firebase Storage security rules.');
      } else {
        throw Exception('Failed to upload image: ${e.toString()}');
      }
    }
  }

  // Add new product with image (for store owners)
  static Future<bool> addProduct(Product product, File? imageFile) async {
    try {
      String imageUrl = product.imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, product.id);
      }
      
      // Create product with image URL
      final productWithImage = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        category: product.category,
        price: product.price,
        imageUrl: imageUrl,
        rating: product.rating,
        specifications: product.specifications,
        isAvailable: product.isAvailable,
        tags: product.tags,
        ownerId: product.ownerId,
        createdAt: product.createdAt,
      );
      
      await _firestore.collection(_collection).doc(product.id).set(productWithImage.toMap());
      print('Product added successfully: ${product.name}');
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  // Add new product without image (backward compatibility)
  static Future<bool> addProductWithoutImage(Product product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).set(product.toMap());
      print('Product added successfully: ${product.name}');
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  // Update product
  static Future<bool> updateProduct(Product product) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(product.id)
          .update(product.toMap());
      print('Product updated successfully: ${product.name}');
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
      print('Product deleted successfully: $productId');
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Update product availability
  static Future<bool> updateProductAvailability(String productId, bool isAvailable) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });
      print('Product availability updated: $productId -> $isAvailable');
      return true;
    } catch (e) {
      print('Error updating product availability: $e');
      return false;
    }
  }

  // Get available categories
  static Future<List<String>> getCategories() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      final categories = <String>{};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category']);
        }
      }
      
      print('Categories found in database: $categories');
      
      final categoryList = categories.toList()..sort();
      return ['All', ...categoryList];
    } catch (e) {
      print('Error getting categories: $e');
      // Updated fallback categories to match AddProductScreen
      return [
        'All', 
        'DSLR Camera',
        'Mirrorless Camera',
        'Action Camera',
        'Video Camera',
        'Lens',
        'Tripod',
        'Lighting',
        'Audio Equipment',
        'Drone',
        'Accessories'
      ];
    }
  }

  // Stream for real-time updates
  static Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data()))
            .toList());
  }

  // Stream for owner's products
  static Stream<List<Product>> getOwnerProductsStream(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data()))
            .toList());
  }
}
