import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/marketplace_listing.dart';
import '../services/google_auth_service.dart';

class MarketplaceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'marketplace_listings';

  // Get all listings with filters
  static Future<List<MarketplaceListing>> getListings({
    String? category,
    String? searchQuery,
    double? maxPrice,
    double? minPrice,
    String? location,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .orderBy('isFeatured', descending: true)
          .orderBy('createdAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      final querySnapshot = await query.limit(limit).get();
      
      List<MarketplaceListing> listings = querySnapshot.docs
          .map((doc) => MarketplaceListing.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply search filter in memory (Firestore doesn't support text search well)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        listings = listings.where((listing) {
          return listing.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 listing.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 listing.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
        }).toList();
      }

      return listings;
    } catch (e) {
      print('Error getting listings: $e');
      return [];
    }
  }

  // Get listings by user
  static Future<List<MarketplaceListing>> getUserListings(String userId) async {
    try {
      final querySnapshot = await _firestore.collection(_collection)
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MarketplaceListing.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user listings: $e');
      return [];
    }
  }

  // Get single listing
  static Future<MarketplaceListing?> getListing(String listingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(listingId).get();
      if (doc.exists) {
        // Increment view count
        await _firestore.collection(_collection).doc(listingId).update({
          'viewCount': FieldValue.increment(1),
        });
        
        return MarketplaceListing.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting listing: $e');
      return null;
    }
  }

  // Upload images to Firebase Storage
  static Future<List<String>> _uploadImages(List<File> imageFiles, String listingId) async {
    try {
      List<String> imageUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        
        print('Starting image upload ${i + 1}/${imageFiles.length} for listing: $listingId');
        print('Image file path: ${imageFile.path}');
        print('Image file exists: ${await imageFile.exists()}');
        
        // Check if file exists
        if (!await imageFile.exists()) {
          throw Exception('Image file ${i + 1} does not exist');
        }

        // Create a unique filename with timestamp and index
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${listingId}_${timestamp}_$i.jpg';
        
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('marketplace_listings')
            .child(fileName);
        
        print('Upload reference path: ${storageRef.fullPath}');
        
        // Create metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'listingId': listingId,
            'imageIndex': i.toString(),
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
        
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      print('Error uploading images: $e');
      print('Error type: ${e.runtimeType}');
      
      // More specific error handling
      if (e.toString().contains('object-not-found')) {
        throw Exception('Firebase Storage not properly configured. Please check your Firebase Storage rules.');
      } else if (e.toString().contains('unauthorized')) {
        throw Exception('Unauthorized access to Firebase Storage. Please check authentication.');
      } else if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check Firebase Storage security rules.');
      } else {
        throw Exception('Failed to upload images: ${e.toString()}');
      }
    }
  }

  // Create new listing
  static Future<String?> createListing(MarketplaceListing listing, {List<File>? imageFiles}) async {
    try {
      final user = GoogleAuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _firestore.collection(_collection).doc();
      List<String> imageUrls = List.from(listing.imageUrls);
      
      // Upload images if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final uploadedUrls = await _uploadImages(imageFiles, docRef.id);
        imageUrls.addAll(uploadedUrls);
      }
      
      final updatedListing = listing.copyWith(
        id: docRef.id,
        sellerId: user.id,
        sellerName: user.name,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      await docRef.set(updatedListing.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating listing: $e');
      return null;
    }
  }

  // Update listing
  static Future<bool> updateListing(MarketplaceListing listing, {List<File>? newImageFiles}) async {
    try {
      final user = GoogleAuthService.currentUser;
      if (user == null || user.id != listing.sellerId) {
        throw Exception('Unauthorized to update this listing');
      }

      List<String> imageUrls = List.from(listing.imageUrls);
      
      // Upload new images if provided
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final uploadedUrls = await _uploadImages(newImageFiles, listing.id);
        imageUrls.addAll(uploadedUrls);
      }

      final updatedListing = listing.copyWith(
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection(_collection)
          .doc(listing.id)
          .update(updatedListing.toMap());
      
      return true;
    } catch (e) {
      print('Error updating listing: $e');
      return false;
    }
  }

  // Update listing without images (backward compatibility)
  static Future<bool> updateListingInfo(MarketplaceListing listing) async {
    try {
      final user = GoogleAuthService.currentUser;
      if (user == null || user.id != listing.sellerId) {
        throw Exception('Unauthorized to update this listing');
      }

      final updatedListing = listing.copyWith(updatedAt: DateTime.now());
      await _firestore.collection(_collection)
          .doc(listing.id)
          .update(updatedListing.toMap());
      
      return true;
    } catch (e) {
      print('Error updating listing: $e');
      return false;
    }
  }

  // Delete listing
  static Future<bool> deleteListing(String listingId) async {
    try {
      final user = GoogleAuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get listing to check ownership
      final listing = await getListing(listingId);
      if (listing == null || listing.sellerId != user.id) {
        throw Exception('Unauthorized to delete this listing');
      }

      await _firestore.collection(_collection).doc(listingId).delete();
      return true;
    } catch (e) {
      print('Error deleting listing: $e');
      return false;
    }
  }

  // Mark listing as sold/unavailable
  static Future<bool> markAsUnavailable(String listingId) async {
    try {
      await _firestore.collection(_collection).doc(listingId).update({
        'isAvailable': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error marking listing as unavailable: $e');
      return false;
    }
  }

  // Get featured listings
  static Future<List<MarketplaceListing>> getFeaturedListings({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore.collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MarketplaceListing.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting featured listings: $e');
      return [];
    }
  }

  // Get categories with listing counts
  static Future<Map<String, int>> getCategoryCounts() async {
    try {
      final querySnapshot = await _firestore.collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      Map<String, int> categoryCounts = {};
      for (var doc in querySnapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }
      
      return categoryCounts;
    } catch (e) {
      print('Error getting category counts: $e');
      return {};
    }
  }

  // Search suggestions
  static Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) return [];
      
      final querySnapshot = await _firestore.collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      Set<String> suggestions = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final tags = List<String>.from(data['tags'] ?? []);
        
        if (title.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(title);
        }
        
        for (var tag in tags) {
          if (tag.toLowerCase().contains(query.toLowerCase())) {
            suggestions.add(tag);
          }
        }
      }
      
      return suggestions.take(10).toList();
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }
}
