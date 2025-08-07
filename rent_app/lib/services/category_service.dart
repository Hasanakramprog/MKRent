import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'categories';

  // Get all active categories
  static Future<List<Category>> getActiveCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Category.fromMap(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      print('Error getting active categories: $e');
      return [];
    }
  }

  // Get all categories (for admin)
  static Future<List<Category>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Category.fromMap(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      print('Error getting all categories: $e');
      return [];
    }
  }

  // Add new category
  static Future<bool> addCategory(Category category) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final categoryWithId = category.copyWith(id: docRef.id);
      
      await docRef.set(categoryWithId.toMap());
      print('Category added successfully: ${category.name}');
      return true;
    } catch (e) {
      print('Error adding category: $e');
      return false;
    }
  }

  // Update category
  static Future<bool> updateCategory(Category category) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(category.id)
          .update(category.toMap());
      print('Category updated successfully: ${category.name}');
      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  // Delete category (soft delete - set isActive to false)
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(categoryId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('Category deleted successfully: $categoryId');
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  // Hard delete category (permanent deletion)
  static Future<bool> permanentDeleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_collection).doc(categoryId).delete();
      print('Category permanently deleted: $categoryId');
      return true;
    } catch (e) {
      print('Error permanently deleting category: $e');
      return false;
    }
  }

  // Get category by ID
  static Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(categoryId).get();
      if (doc.exists) {
        return Category.fromMap(doc.data()!, documentId: doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  // Check if category name already exists
  static Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true);

      final querySnapshot = await query.get();
      
      if (excludeId != null) {
        // When updating, exclude the current category from the check
        return querySnapshot.docs.any((doc) => doc.id != excludeId);
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking category name existence: $e');
      return false;
    }
  }

  // Initialize default categories if none exist
  static Future<void> initializeDefaultCategories() async {
    try {
      final categories = await getAllCategories();
      if (categories.isEmpty) {
        final defaultCategories = [
          Category(
            id: '',
            name: 'DSLR Camera',
            description: 'Digital Single-Lens Reflex cameras for professional photography',
            iconName: 'camera',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Mirrorless Camera',
            description: 'Compact mirrorless cameras with interchangeable lenses',
            iconName: 'camera_alt',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Action Camera',
            description: 'Compact cameras for action and adventure photography',
            iconName: 'videocam',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Video Camera',
            description: 'Professional video cameras and camcorders',
            iconName: 'movie',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Lens',
            description: 'Camera lenses for various photography needs',
            iconName: 'lens',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Tripod',
            description: 'Tripods and stabilization equipment',
            iconName: 'tripod',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Lighting',
            description: 'Lighting equipment for photography and videography',
            iconName: 'lightbulb',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Audio Equipment',
            description: 'Microphones and audio recording equipment',
            iconName: 'mic',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Drone',
            description: 'Drones and aerial photography equipment',
            iconName: 'flight',
            createdAt: DateTime.now(),
          ),
          Category(
            id: '',
            name: 'Accessories',
            description: 'Camera accessories and additional equipment',
            iconName: 'settings',
            createdAt: DateTime.now(),
          ),
        ];

        for (final category in defaultCategories) {
          await addCategory(category);
        }
        print('Default categories initialized successfully');
      }
    } catch (e) {
      print('Error initializing default categories: $e');
    }
  }
}
