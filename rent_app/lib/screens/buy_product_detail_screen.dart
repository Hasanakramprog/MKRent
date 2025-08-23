import 'package:flutter/material.dart';
import '../models/buy_product.dart';
import '../services/buy_cart_service.dart';
import '../widgets/cached_image_widget.dart';
import '../widgets/asset_image_widget.dart';
import '../services/google_auth_service.dart';
import '../services/buy_product_service.dart';

class BuyProductDetailScreen extends StatefulWidget {
  final BuyProduct product;

  const BuyProductDetailScreen({super.key, required this.product});

  @override
  State<BuyProductDetailScreen> createState() => _BuyProductDetailScreenState();
}

class _BuyProductDetailScreenState extends State<BuyProductDetailScreen> {
  late BuyProduct _currentProduct;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  Future<void> _refreshProduct() async {
    try {
      setState(() {
        _isRefreshing = true;
      });
      
      // Fetch updated product data from Firebase
      final updatedProduct = await BuyProductService.getProductById(widget.product.id);
      if (updatedProduct != null && mounted) {
        setState(() {
          _currentProduct = updatedProduct;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error refreshing product: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _currentProduct.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isRefreshing)
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: CachedImageWidget(
                imageUrl: _currentProduct.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ProductPlaceholder(
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Product Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand and Condition
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentProduct.brand,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getConditionColor(_currentProduct.condition),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentProduct.condition.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Product Name
                  Text(
                    _currentProduct.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Category
                  Text(
                    _currentProduct.category,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price and Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${_currentProduct.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_currentProduct.stockQuantity > 0)
                            Text(
                              '${_currentProduct.stockQuantity} in stock',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            const Text(
                              'Out of stock',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (_currentProduct.rating > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_currentProduct.rating.toStringAsFixed(1)} (${_currentProduct.reviewCount})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentProduct.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Features
                  if (_currentProduct.features.isNotEmpty) ...[
                    const Text(
                      'Features',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_currentProduct.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))),
                    const SizedBox(height: 24),
                  ],
                  
                  // Specifications
                  if (_currentProduct.specifications.isNotEmpty) ...[
                    const Text(
                      'Specifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _currentProduct.specifications.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Warranty
                  if (_currentProduct.warranty.isNotEmpty) ...[
                    const Text(
                      'Warranty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentProduct.warranty,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // Admin Actions (Edit & Delete) or Customer Buy Button
                  if (GoogleAuthService.isAdmin) ...[
                    // Edit Product Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditProductDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text(
                          'Edit Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Delete Product Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmationDialog(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text(
                          'Delete Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Add to Cart Button (only for customers)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _currentProduct.stockQuantity > 0
                            ? () => _handleAddToCart()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentProduct.stockQuantity > 0
                              ? const Color(0xFFFFD700)
                              : Colors.grey,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentProduct.stockQuantity > 0 
                              ? 'Add to Cart - \$${_currentProduct.price.toStringAsFixed(2)}'
                              : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
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
        return Colors.green;
      case 'used':
        return Colors.orange;
      case 'refurbished':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleAddToCart() async {
    try {
      await BuyCartService.addToCart(
        productId: _currentProduct.id,
        productName: _currentProduct.name,
        productImageUrl: _currentProduct.imageUrl,
        price: _currentProduct.price,
        quantity: 1,
        condition: _currentProduct.condition,
        stockQuantity: _currentProduct.stockQuantity,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentProduct.name} added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showEditProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text(
              'Edit Product',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Do you want to edit this product?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImageWidget(
                      imageUrl: widget.product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ProductPlaceholder(
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.product.category,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Edit Product'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete Product',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this product?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImageWidget(
                      imageUrl: widget.product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ProductPlaceholder(
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.product.category,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProduct() async {
    // Navigate to add buy product screen with product data for editing
    final result = await Navigator.pushNamed(
      context,
      '/add-buy-product',
      arguments: _currentProduct, // Pass current product for editing
    );
    
    // Check if product was updated
    if (result == true) {
      print('BuyProductDetailScreen: Product was updated, refreshing...');
      // Refresh the product data first
      await _refreshProduct();
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentProduct.name} updated successfully'),
            backgroundColor: const Color(0xFFFFD700),
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Stay on this screen - don't navigate back
        print('BuyProductDetailScreen: Product refreshed, staying on current screen');
      }
    } else {
      print('BuyProductDetailScreen: Edit result: $result');
    }
  }

  void _deleteProduct() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFD700),
          ),
        ),
      );

      // Delete product from Firebase
      await BuyProductService.deleteProduct(_currentProduct.id);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentProduct.name} deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate back with success indicator
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
