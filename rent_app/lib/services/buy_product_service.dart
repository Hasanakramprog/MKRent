import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/buy_product.dart';
import '../services/google_auth_service.dart';

class BuyProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'buy_products';

  // Get all buy products
  static Future<List<BuyProduct>> getAllProducts() async {
    try {
      print('Fetching all buy products...');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final products = querySnapshot.docs
          .map((doc) => BuyProduct.fromMap(doc.data(), doc.id))
          .toList();

      print('Fetched ${products.length} buy products');
      return products;
    } catch (e) {
      print('Error fetching buy products: $e');
      return [];
    }
  }

  // Get products by category
  static Future<List<BuyProduct>> getProductsByCategory(String category) async {
    try {
      print('Fetching buy products for category: $category');
      
      Query query = _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true);
      
      if (category != 'All') {
        query = query.where('category', isEqualTo: category);
      }
      
      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      final products = querySnapshot.docs
          .map((doc) => BuyProduct.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('Fetched ${products.length} buy products for category: $category');
      return products;
    } catch (e) {
      print('Error fetching buy products by category: $e');
      return [];
    }
  }

  // Get products by brand
  static Future<List<BuyProduct>> getProductsByBrand(String brand) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('brand', isEqualTo: brand)
          .where('isAvailable', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BuyProduct.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching buy products by brand: $e');
      return [];
    }
  }

  // Search products
  static Future<List<BuyProduct>> searchProducts(String searchTerm) async {
    try {
      print('Searching buy products for: $searchTerm');
      
      // Get all products first, then filter locally
      // (Firestore doesn't support complex text search)
      final allProducts = await getAllProducts();
      
      final searchResults = allProducts.where((product) {
        final searchLower = searchTerm.toLowerCase();
        return product.name.toLowerCase().contains(searchLower) ||
               product.description.toLowerCase().contains(searchLower) ||
               product.category.toLowerCase().contains(searchLower) ||
               product.brand.toLowerCase().contains(searchLower);
      }).toList();

      print('Found ${searchResults.length} buy products matching: $searchTerm');
      return searchResults;
    } catch (e) {
      print('Error searching buy products: $e');
      return [];
    }
  }

  // Get product by ID
  static Future<BuyProduct?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      
      if (doc.exists) {
        return BuyProduct.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching buy product by ID: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  static Future<String> _uploadImage(File imageFile, String productId) async {
    try {
      print('Starting image upload for buy product: $productId');
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
          .child('buy_products')
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

  // Add new product (for store owners) - DEPRECATED, use addProductWithImage instead
  static Future<String?> addProduct(BuyProduct product) async {
    try {
      if (!GoogleAuthService.isAdmin) {
        throw Exception('Only store owners can add products');
      }

      print('Adding new buy product: ${product.name}');
      
      final docRef = await _firestore.collection(_collection).add(product.toMap());
      
      print('Buy product added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding buy product: $e');
      return null;
    }
  }

  // Add new product with image upload (for store owners)
  static Future<String?> addProductWithImage(BuyProduct product, File? imageFile) async {
    try {
      if (!GoogleAuthService.isAdmin) {
        throw Exception('Only store owners can add products');
      }

      print('Adding new buy product with image: ${product.name}');
      
      String imageUrl = product.imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, product.id);
      }
      
      // Create product with image URL
      final productWithImage = product.copyWith(imageUrl: imageUrl);
      
      await _firestore.collection(_collection).doc(product.id).set(productWithImage.toMap());
      
      print('Buy product added successfully with ID: ${product.id}');
      return product.id;
    } catch (e) {
      print('Error adding buy product with image: $e');
      return null;
    }
  }

  // Update product
  static Future<bool> updateProduct(String productId, BuyProduct product) async {
    try {
      if (!GoogleAuthService.isAdmin) {
        throw Exception('Only store owners can update products');
      }

      await _firestore
          .collection(_collection)
          .doc(productId)
          .update(product.toMap());
      
      print('Buy product updated successfully: $productId');
      return true;
    } catch (e) {
      print('Error updating buy product: $e');
      return false;
    }
  }

  // Delete product
  static Future<bool> deleteProduct(String productId) async {
    try {
      if (!GoogleAuthService.isAdmin) {
        throw Exception('Only store owners can delete products');
      }

      await _firestore.collection(_collection).doc(productId).delete();
      
      print('Buy product deleted successfully: $productId');
      return true;
    } catch (e) {
      print('Error deleting buy product: $e');
      return false;
    }
  }

  // Get available categories
  static Future<List<String>> getCategories() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      final categories = querySnapshot.docs
          .map((doc) => doc.data()['category'] as String?)
          .where((category) => category != null)
          .cast<String>()
          .toSet()
          .toList();
      
      categories.sort();
      return ['All', ...categories];
    } catch (e) {
      print('Error fetching buy product categories: $e');
      return ['All'];
    }
  }

  // Get available brands
  static Future<List<String>> getBrands() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      final brands = querySnapshot.docs
          .map((doc) => doc.data()['brand'] as String?)
          .where((brand) => brand != null)
          .cast<String>()
          .toSet()
          .toList();
      
      brands.sort();
      return brands;
    } catch (e) {
      print('Error fetching buy product brands: $e');
      return [];
    }
  }

  // Update stock quantity
  static Future<bool> updateStock(String productId, int newQuantity) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(productId)
          .update({
        'stockQuantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  // Check if product is in stock
  static Future<bool> isInStock(String productId, int requestedQuantity) async {
    try {
      final product = await getProductById(productId);
      return product != null && 
             product.isAvailable && 
             product.stockQuantity >= requestedQuantity;
    } catch (e) {
      print('Error checking stock: $e');
      return false;
    }
  }

  // Filter products by price range
  static List<BuyProduct> filterByPriceRange(
    List<BuyProduct> products,
    double minPrice,
    double maxPrice,
  ) {
    return products.where((product) {
      return product.price >= minPrice && product.price <= maxPrice;
    }).toList();
  }

  // Filter products by rating
  static List<BuyProduct> filterByRating(
    List<BuyProduct> products,
    double minRating,
  ) {
    return products.where((product) {
      return product.rating >= minRating;
    }).toList();
  }

  // Sort products
  static List<BuyProduct> sortProducts(
    List<BuyProduct> products,
    String sortBy,
  ) {
    switch (sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        // Keep original order
        break;
    }
    return products;
  }
}
