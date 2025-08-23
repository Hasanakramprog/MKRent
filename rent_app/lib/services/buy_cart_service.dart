import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/buy_cart.dart';
import '../models/buy_product.dart';
import 'google_auth_service.dart';

class BuyCartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _buyCartCollection = 'buy_carts';

  // Buy Cart Management
  static Future<void> addToCart({
    required String productId,
    required String productName,
    required String productImageUrl,
    required double price,
    required int quantity,
    required String condition,
    required int stockQuantity,
  }) async {
    try {
      final userId = GoogleAuthService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if requested quantity is available
      if (quantity > stockQuantity) {
        throw Exception('Requested quantity exceeds available stock');
      }

      final subtotal = price * quantity;

      final cartItem = BuyCartItem(
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        price: price,
        quantity: quantity,
        condition: condition,
        subtotal: subtotal,
        addedAt: DateTime.now(),
      );

      // Get current cart or create new one
      final currentCart = await getBuyCart();
      final existingItems = currentCart?.items ?? [];

      // Check if product already exists in cart
      final existingIndex = existingItems.indexWhere((item) =>
          item.productId == productId && item.condition == condition);

      if (existingIndex != -1) {
        // Update quantity of existing item
        final existingItem = existingItems[existingIndex];
        final newQuantity = existingItem.quantity + quantity;
        
        // Check if total quantity doesn't exceed stock
        if (newQuantity > stockQuantity) {
          throw Exception('Total quantity would exceed available stock');
        }

        existingItems[existingIndex] = existingItem.copyWith(
          quantity: newQuantity,
          subtotal: price * newQuantity,
        );
      } else {
        // Add new item
        existingItems.add(cartItem);
      }

      // Calculate new total
      final total = existingItems.fold<double>(
        0.0,
        (sum, item) => sum + item.subtotal,
      );

      final updatedCart = BuyCart(
        userId: userId,
        items: existingItems,
        total: total,
        itemCount: existingItems.length,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection(_buyCartCollection)
          .doc(userId)
          .set(updatedCart.toMap());

      print('Product added to buy cart successfully');
    } catch (e) {
      print('Error adding to buy cart: $e');
      rethrow;
    }
  }

  static Future<void> updateCartItemQuantity({
    required String productId,
    required String condition,
    required int newQuantity,
  }) async {
    try {
      final userId = GoogleAuthService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final currentCart = await getBuyCart();
      if (currentCart == null) return;

      final items = currentCart.items;
      final itemIndex = items.indexWhere((item) =>
          item.productId == productId && item.condition == condition);

      if (itemIndex == -1) return;

      if (newQuantity <= 0) {
        // Remove item
        items.removeAt(itemIndex);
      } else {
        // Update quantity
        final item = items[itemIndex];
        items[itemIndex] = item.copyWith(
          quantity: newQuantity,
          subtotal: item.price * newQuantity,
        );
      }

      // Calculate new total
      final total = items.fold<double>(
        0.0,
        (sum, item) => sum + item.subtotal,
      );

      final updatedCart = currentCart.copyWith(
        items: items,
        total: total,
        itemCount: items.length,
        updatedAt: DateTime.now(),
      );

      if (items.isEmpty) {
        // Delete cart if empty
        await _firestore
            .collection(_buyCartCollection)
            .doc(userId)
            .delete();
      } else {
        // Update cart
        await _firestore
            .collection(_buyCartCollection)
            .doc(userId)
            .set(updatedCart.toMap());
      }
    } catch (e) {
      print('Error updating buy cart item: $e');
      rethrow;
    }
  }

  static Future<void> removeFromCart({
    required String productId,
    required String condition,
  }) async {
    await updateCartItemQuantity(
      productId: productId,
      condition: condition,
      newQuantity: 0,
    );
  }

  static Future<BuyCart?> getBuyCart() async {
    try {
      final userId = GoogleAuthService.currentUser?.id;
      if (userId == null) return null;

      final doc = await _firestore
          .collection(_buyCartCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return BuyCart.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting buy cart: $e');
      return null;
    }
  }

  static Stream<BuyCart?> getBuyCartStream() {
    final userId = GoogleAuthService.currentUser?.id;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection(_buyCartCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return BuyCart.fromMap(doc.data()!);
      }
      return null;
    });
  }

  static Stream<int> getBuyCartItemCountStream() {
    return getBuyCartStream().map((cart) => cart?.itemCount ?? 0);
  }

  static Future<void> clearBuyCart() async {
    try {
      final userId = GoogleAuthService.currentUser?.id;
      if (userId == null) return;

      await _firestore
          .collection(_buyCartCollection)
          .doc(userId)
          .delete();

      print('Buy cart cleared successfully');
    } catch (e) {
      print('Error clearing buy cart: $e');
      rethrow;
    }
  }

  static Future<double> getBuyCartTotal() async {
    final cart = await getBuyCart();
    return cart?.total ?? 0.0;
  }

  static Future<int> getBuyCartItemCount() async {
    final cart = await getBuyCart();
    return cart?.itemCount ?? 0;
  }

  // Validation helpers
  static Future<bool> isProductInCart(String productId, String condition) async {
    final cart = await getBuyCart();
    if (cart == null) return false;

    return cart.items.any((item) =>
        item.productId == productId && item.condition == condition);
  }

  static Future<int> getProductQuantityInCart(String productId, String condition) async {
    final cart = await getBuyCart();
    if (cart == null) return 0;

    final item = cart.items.firstWhere(
      (item) => item.productId == productId && item.condition == condition,
      orElse: () => BuyCartItem(
        productId: '',
        productName: '',
        productImageUrl: '',
        price: 0,
        quantity: 0,
        condition: '',
        subtotal: 0,
        addedAt: DateTime.now(),
      ),
    );

    return item.productId.isEmpty ? 0 : item.quantity;
  }

  // Bulk operations
  static Future<void> addMultipleToCart(List<BuyProduct> products) async {
    for (final product in products) {
      await addToCart(
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
        price: product.price,
        quantity: 1,
        condition: product.condition,
        stockQuantity: product.stockQuantity,
      );
    }
  }

  // Order creation (placeholder for future implementation)
  static Future<String> createOrder() async {
    // TODO: Implement order creation logic
    // This would typically:
    // 1. Validate cart items and stock
    // 2. Create order document
    // 3. Update product stock quantities
    // 4. Clear cart
    // 5. Send confirmation notifications
    throw UnimplementedError('Order creation not yet implemented');
  }
}
