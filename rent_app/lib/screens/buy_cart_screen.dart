import 'package:flutter/material.dart';
import '../models/buy_cart.dart';
import '../services/buy_cart_service.dart';

class BuyCartScreen extends StatefulWidget {
  const BuyCartScreen({super.key});

  @override
  State<BuyCartScreen> createState() => _BuyCartScreenState();
}

class _BuyCartScreenState extends State<BuyCartScreen> {
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? const Color(0xFF4CAF50),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<BuyCart?>(
            stream: BuyCartService.getBuyCartStream(),
            builder: (context, snapshot) {
              final cart = snapshot.data;
              if (cart != null && cart.items.isNotEmpty) {
                return TextButton(
                  onPressed: _showClearCartDialog,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<BuyCart?>(
        stream: BuyCartService.getBuyCartStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            );
          }

          final cart = snapshot.data;
          if (cart == null || cart.items.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              // Cart Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(item);
                  },
                ),
              ),
              
              // Cart Summary
              _buildCartSummary(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add some cameras to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuyCartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.productImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.grey,
                    size: 32,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Condition
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getConditionColor(item.condition).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.condition,
                    style: TextStyle(
                      color: _getConditionColor(item.condition),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Price and Quantity Controls
                Row(
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuantityButton(
                            icon: Icons.remove,
                            onPressed: () => _updateQuantity(item, item.quantity - 1),
                            enabled: item.quantity > 1,
                          ),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          _buildQuantityButton(
                            icon: Icons.add,
                            onPressed: () => _updateQuantity(item, item.quantity + 1),
                            enabled: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Subtotal and Remove
                Row(
                  children: [
                    Text(
                      'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    IconButton(
                      onPressed: () => _removeItem(item),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF4CAF50) : Colors.grey,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuyCart cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Total Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${cart.itemCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return const Color(0xFF4CAF50);
      case 'excellent':
        return const Color(0xFF2196F3);
      case 'good':
        return const Color(0xFFFF9800);
      case 'fair':
        return const Color(0xFFFF5722);
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateQuantity(BuyCartItem item, int newQuantity) async {
    try {
      await BuyCartService.updateCartItemQuantity(
        productId: item.productId,
        condition: item.condition,
        newQuantity: newQuantity,
      );
    } catch (e) {
      _showSnackBar('Error updating quantity: ${e.toString()}', backgroundColor: Colors.red);
    }
  }

  Future<void> _removeItem(BuyCartItem item) async {
    try {
      await BuyCartService.removeFromCart(
        productId: item.productId,
        condition: item.condition,
      );
      
      _showSnackBar('${item.productName} removed from cart');
    } catch (e) {
      _showSnackBar('Error removing item: ${e.toString()}', backgroundColor: Colors.red);
    }
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Clear Cart',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BuyCartService.clearBuyCart();
                _showSnackBar('Cart cleared');
              } catch (e) {
                _showSnackBar('Error clearing cart: ${e.toString()}', backgroundColor: Colors.red);
              }
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _checkout() {
    // TODO: Implement checkout functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Checkout functionality will be implemented soon!',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }
}
