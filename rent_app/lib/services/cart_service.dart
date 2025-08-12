import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart.dart';
import '../models/notification.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _cartCollection = 'carts';
  static final String _bulkRentalRequestsCollection = 'bulk_rental_requests';

  // Cart Management
  static Future<void> addToCart({
    required String productId,
    required String productName,
    required String productImageUrl,
    required double dailyRate,
    required int quantity,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final totalDays = endDate.difference(startDate).inDays + 1;
      final subtotal = CartItem.calculateSubtotal(dailyRate, quantity, totalDays);

      final cartItem = CartItem(
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        dailyRate: dailyRate,
        quantity: quantity,
        startDate: startDate,
        endDate: endDate,
        totalDays: totalDays,
        subtotal: subtotal,
      );

      // Get current cart or create new one
      final currentCart = await getCart();
      final existingItems = currentCart?.items ?? [];

      // Check if product with same dates already exists
      final existingIndex = existingItems.indexWhere((item) =>
          item.productId == productId &&
          item.startDate.isAtSameMomentAs(startDate) &&
          item.endDate.isAtSameMomentAs(endDate));

      List<CartItem> updatedItems;
      if (existingIndex != -1) {
        // Update existing item quantity
        updatedItems = List.from(existingItems);
        updatedItems[existingIndex] = existingItems[existingIndex].copyWith(
          quantity: existingItems[existingIndex].quantity + quantity,
          subtotal: CartItem.calculateSubtotal(
            dailyRate,
            existingItems[existingIndex].quantity + quantity,
            totalDays,
          ),
        );
      } else {
        // Add new item
        updatedItems = [...existingItems, cartItem];
      }

      final updatedCart = Cart(
        userId: userId,
        items: updatedItems,
        totalAmount: Cart.calculateTotal(updatedItems),
        createdAt: currentCart?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .set(updatedCart.toMap());

      print('Product added to cart successfully');
    } catch (e) {
      print('Error adding to cart: $e');
      throw e;
    }
  }

  static Future<void> removeFromCart(String productId, DateTime startDate, DateTime endDate) async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final currentCart = await getCart();
      if (currentCart == null) return;

      final updatedItems = currentCart.items.where((item) =>
          !(item.productId == productId &&
            item.startDate.isAtSameMomentAs(startDate) &&
            item.endDate.isAtSameMomentAs(endDate))).toList();

      if (updatedItems.isEmpty) {
        // Delete cart if empty
        await _firestore.collection(_cartCollection).doc(userId).delete();
      } else {
        // Update cart
        final updatedCart = currentCart.copyWith(
          items: updatedItems,
          totalAmount: Cart.calculateTotal(updatedItems),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(_cartCollection)
            .doc(userId)
            .set(updatedCart.toMap());
      }

      print('Item removed from cart successfully');
    } catch (e) {
      print('Error removing from cart: $e');
      throw e;
    }
  }

  static Future<void> updateCartItemQuantity({
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
    required int newQuantity,
  }) async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final currentCart = await getCart();
      if (currentCart == null) return;

      final updatedItems = currentCart.items.map((item) {
        if (item.productId == productId &&
            item.startDate.isAtSameMomentAs(startDate) &&
            item.endDate.isAtSameMomentAs(endDate)) {
          return item.copyWith(
            quantity: newQuantity,
            subtotal: CartItem.calculateSubtotal(
              item.dailyRate,
              newQuantity,
              item.totalDays,
            ),
          );
        }
        return item;
      }).toList();

      final updatedCart = currentCart.copyWith(
        items: updatedItems,
        totalAmount: Cart.calculateTotal(updatedItems),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .set(updatedCart.toMap());

      print('Cart item quantity updated successfully');
    } catch (e) {
      print('Error updating cart item quantity: $e');
      throw e;
    }
  }

  static Future<Cart?> getCart() async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return null;

      final doc = await _firestore.collection(_cartCollection).doc(userId).get();
      if (!doc.exists) return null;

      return Cart.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting cart: $e');
      return null;
    }
  }

  static Stream<Cart?> getCartStream() {
    final userId = AuthService.currentUser?.id;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection(_cartCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Cart.fromMap(doc.data()!);
    });
  }

  static Future<void> clearCart() async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection(_cartCollection).doc(userId).delete();
      print('Cart cleared successfully');
    } catch (e) {
      print('Error clearing cart: $e');
      throw e;
    }
  }

  // Rental Request Management
  static Future<String> submitBulkRentalRequest() async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final user = AuthService.currentUser;
      if (user == null) throw Exception('User data not found');

      final cart = await getCart();
      if (cart == null || cart.isEmpty) {
        throw Exception('Cart is empty');
      }

      final requestId = _firestore.collection(_bulkRentalRequestsCollection).doc().id;

      final bulkRequest = BulkRentalRequest(
        id: requestId,
        userId: userId,
        userName: user.name,
        userPhone: user.phone,
        items: cart.items,
        originalTotal: cart.totalAmount,
        status: 'pending',
        requestDate: DateTime.now(),
      );

      await _firestore
          .collection(_bulkRentalRequestsCollection)
          .doc(requestId)
          .set(bulkRequest.toMap());

      // Clear cart after successful submission
      await clearCart();

      // Send notification to admin (you can implement this based on your notification system)
      await _notifyAdminOfNewRequest(bulkRequest);

      print('Rental request submitted successfully');
      return requestId;
    } catch (e) {
      print('Error submitting rental request: $e');
      throw e;
    }
  }

  static Future<void> _notifyAdminOfNewRequest(BulkRentalRequest request) async {
    try {
      // Get all admin users and send notifications
      final adminUsers = await _getAdminUsers();
      
      for (final adminId in adminUsers) {
        await NotificationService.sendNotification(
          toUserId: adminId,
          type: NotificationType.rentalRequest,
          title: 'New Rental Request',
          message: '${request.userName} submitted a rental request for ${request.totalItems} items (Total: \$${request.originalTotal.toStringAsFixed(2)})',
          data: {
            'requestId': request.id,
            'requestType': 'rental_request',
            'userId': request.userId,
            'userName': request.userName,
            'totalItems': request.totalItems.toString(),
            'totalAmount': request.originalTotal.toString(),
          },
        );
      }
      
      print('Admin notifications sent for rental request: ${request.id}');
    } catch (e) {
      print('Error notifying admin: $e');
    }
  }

  static Future<List<String>> _getAdminUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting admin users: $e');
      return [];
    }
  }

  // Admin Functions
  static Future<void> updateBulkRentalRequestStatus({
    required String requestId,
    required String status,
    double? adjustedTotal,
    String? adminNotes,
  }) async {
    try {
      final adminId = AuthService.currentUser?.id;
      if (adminId == null) throw Exception('Admin not authenticated');

      final updateData = {
        'status': status,
        'responseDate': Timestamp.fromDate(DateTime.now()),
        'adminId': adminId,
      };

      if (adjustedTotal != null) {
        updateData['adminAdjustedTotal'] = adjustedTotal;
      }

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      await _firestore
          .collection(_bulkRentalRequestsCollection)
          .doc(requestId)
          .update(updateData);

      // Notify user about status update
      final request = await getBulkRentalRequest(requestId);
      if (request != null) {
        await _notifyUserOfStatusUpdate(request);
      }

      print('Rental request status updated successfully');
    } catch (e) {
      print('Error updating rental request status: $e');
      throw e;
    }
  }

  static Future<void> _notifyUserOfStatusUpdate(BulkRentalRequest request) async {
    try {
      String title = '';
      String message = '';
      NotificationType notificationType;
      
      switch (request.status) {
        case 'approved':
          title = 'Rental Request Approved!';
          message = 'Your rental request has been approved. Total: \$${request.finalTotal.toStringAsFixed(2)}';
          notificationType = NotificationType.rentalApproved;
          break;
        case 'rejected':
          title = 'Rental Request Declined';
          message = 'Your rental request has been declined. ${request.adminNotes ?? ''}';
          notificationType = NotificationType.rentalRejected;
          break;
        case 'price_adjusted':
          title = 'Price Adjusted';
          message = 'Admin adjusted your rental price to \$${request.finalTotal.toStringAsFixed(2)}. ${request.adminNotes ?? ''}';
          notificationType = NotificationType.rentalRequest; // Using general for price adjustment
          break;
        default:
          title = 'Request Status Updated';
          message = 'Your rental request status has been updated to ${request.status}';
          notificationType = NotificationType.general;
      }

      await NotificationService.sendNotification(
        toUserId: request.userId,
        type: notificationType,
        title: title,
        message: message,
        data: {
          'requestId': request.id,
          'requestType': 'rental_request',
          'status': request.status,
          'totalItems': request.totalItems.toString(),
          'finalTotal': request.finalTotal.toString(),
          'adminNotes': request.adminNotes ?? '',
        },
      );
      
      print('User notification sent for request: ${request.id}');
    } catch (e) {
      print('Error notifying user: $e');
    }
  }

  static Future<BulkRentalRequest?> getBulkRentalRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_bulkRentalRequestsCollection)
          .doc(requestId)
          .get();

      if (!doc.exists) return null;
      return BulkRentalRequest.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting bulk rental request: $e');
      return null;
    }
  }

  static Stream<List<BulkRentalRequest>> getBulkRentalRequestsStream({
    String? userId,
    String? status,
  }) {
    Query query = _firestore.collection(_bulkRentalRequestsCollection);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BulkRentalRequest.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  static Future<List<BulkRentalRequest>> getUserBulkRentalRequests() async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection(_bulkRentalRequestsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BulkRentalRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user bulk rental requests: $e');
      return [];
    }
  }

  static Future<List<BulkRentalRequest>> getAllBulkRentalRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_bulkRentalRequestsCollection)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BulkRentalRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all bulk rental requests: $e');
      return [];
    }
  }

  // Helper Methods
  static Future<int> getCartItemCount() async {
    final cart = await getCart();
    return cart?.totalQuantity ?? 0;
  }

  static Stream<int> getCartItemCountStream() {
    return getCartStream().map((cart) => cart?.totalQuantity ?? 0);
  }
}
