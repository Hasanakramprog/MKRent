import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental.dart';

class RentalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'rentals';

  // Create new rental request
  static Future<bool> createRentalRequest(RentalRequest rental) async {
    try {
      await _firestore.collection(_collection).doc(rental.id).set(rental.toMap());
      print('Rental request created successfully: ${rental.id}');
      return true;
    } catch (e) {
      print('Error creating rental request: $e');
      return false;
    }
  }

  // Get rental requests for a user (customer)
  static Future<List<RentalRequest>> getUserRentals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user rentals: $e');
      return [];
    }
  }

  // Get rental requests for a store owner
  static Future<List<RentalRequest>> getStoreRentals(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('productOwnerId', isEqualTo: ownerId)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting store rentals: $e');
      return [];
    }
  }

  // Get rental by ID
  static Future<RentalRequest?> getRentalById(String rentalId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(rentalId).get();
      
      if (doc.exists && doc.data() != null) {
        return RentalRequest.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting rental by ID: $e');
      return null;
    }
  }

  // Update rental status (approve/reject)
  static Future<bool> updateRentalStatus({
    required String rentalId,
    required RentalStatus status,
    String? storeResponse,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      };

      if (storeResponse != null) {
        updateData['storeResponse'] = storeResponse;
      }

      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore.collection(_collection).doc(rentalId).update(updateData);
      print('Rental status updated: $rentalId -> $status');
      return true;
    } catch (e) {
      print('Error updating rental status: $e');
      return false;
    }
  }

  // Get pending rentals for a store owner
  static Future<List<RentalRequest>> getPendingRentals(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('productOwnerId', isEqualTo: ownerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pending rentals: $e');
      return [];
    }
  }

  // Get active rentals for a user
  static Future<List<RentalRequest>> getActiveRentals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['approved', 'active'])
          .orderBy('startDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting active rentals: $e');
      return [];
    }
  }

  // Get rental history for a user
  static Future<List<RentalRequest>> getRentalHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting rental history: $e');
      return [];
    }
  }

  // Cancel rental request
  static Future<bool> cancelRental(String rentalId) async {
    try {
      await _firestore.collection(_collection).doc(rentalId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
      print('Rental cancelled: $rentalId');
      return true;
    } catch (e) {
      print('Error cancelling rental: $e');
      return false;
    }
  }

  // Complete rental
  static Future<bool> completeRental(String rentalId) async {
    try {
      await _firestore.collection(_collection).doc(rentalId).update({
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      });
      print('Rental completed: $rentalId');
      return true;
    } catch (e) {
      print('Error completing rental: $e');
      return false;
    }
  }

  // Get rentals by status
  static Future<List<RentalRequest>> getRentalsByStatus({
    String? userId,
    String? ownerId,
    required RentalStatus status,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (ownerId != null) {
        query = query.where('productOwnerId', isEqualTo: ownerId);
      }

      query = query
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('requestDate', descending: true);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => RentalRequest.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting rentals by status: $e');
      return [];
    }
  }

  // Stream for real-time rental updates (for users)
  static Stream<List<RentalRequest>> getUserRentalsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequest.fromMap(doc.data()))
            .toList());
  }

  // Stream for real-time rental updates (for store owners)
  static Stream<List<RentalRequest>> getStoreRentalsStream(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('productOwnerId', isEqualTo: ownerId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequest.fromMap(doc.data()))
            .toList());
  }

  // Stream for pending rentals (for store owners)
  static Stream<List<RentalRequest>> getPendingRentalsStream(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('productOwnerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequest.fromMap(doc.data()))
            .toList());
  }
}
