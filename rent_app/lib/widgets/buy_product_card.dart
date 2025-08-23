import 'package:flutter/material.dart';
import 'cached_image_widget.dart';
import 'asset_image_widget.dart';
import '../models/buy_product.dart';
import '../screens/buy_product_detail_screen.dart';
import '../services/buy_cart_service.dart';
import '../services/google_auth_service.dart';

class BuyProductCard extends StatefulWidget {
  final BuyProduct product;
  final VoidCallback? onProductUpdated;
  final VoidCallback? onTap;

  const BuyProductCard({
    super.key, 
    required this.product, 
    this.onProductUpdated,
    this.onTap,
  });

  @override
  State<BuyProductCard> createState() => _BuyProductCardState();
}

class _BuyProductCardState extends State<BuyProductCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Only animate if product is available (in stock)
    if (widget.product.stockQuantity > 0) {
      _animationController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );
      
      _pulseAnimation = Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      // Start repeating animation
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.product.stockQuantity > 0) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap ?? () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyProductDetailScreen(product: widget.product),
          ),
        );
        
        // If product was updated or deleted, refresh the parent
        if (result == true && widget.onProductUpdated != null) {
          print('BuyProductCard: Product was updated/deleted, calling refresh callback');
          widget.onProductUpdated!();
        } else {
          print('BuyProductCard: Navigation result: $result');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Dark gray card
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Main Product Image
                    CachedImageWidget(
                      imageUrl: widget.product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      showCacheIndicator: false,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      placeholder: (context, url) => const ProductPlaceholder(
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => const ProductPlaceholder(
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                    // Category Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.product.category,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Condition Badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getConditionColor(widget.product.condition),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.product.condition.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name and Stock Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Stock Status Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.product.stockQuantity > 0 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.product.stockQuantity > 0 
                                  ? Colors.green
                                  : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated stock indicator
                              widget.product.stockQuantity > 0
                                  ? AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(_pulseAnimation.value),
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                              const SizedBox(width: 3),
                              // Stock text
                              Text(
                                widget.product.stockQuantity > 0
                                    ? '${widget.product.stockQuantity} in stock'
                                    : 'Out of stock',
                                style: TextStyle(
                                  color: widget.product.stockQuantity > 0 
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Product Brand
                    Flexible(
                      child: Text(
                        widget.product.brand,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Rating and Price Row
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          widget.product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.product.reviewCount})',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${widget.product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Actions Row
                    Row(
                      children: [
                        const Spacer(),
                        // Add to Cart Button (only for customers with stock, not admins)
                        if (widget.product.stockQuantity > 0 && !GoogleAuthService.isAdmin) ...[
                          InkWell(
                            onTap: () => _showAddToCartDialog(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 14,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Edit Button (only for admins)
                        if (GoogleAuthService.isAdmin) ...[
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BuyProductDetailScreen(product: widget.product),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // View Button
                        SizedBox(
                          height: 24,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BuyProductDetailScreen(product: widget.product),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
        return Colors.green;
      case 'used':
        return Colors.orange;
      case 'refurbished':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddToCartDialog(BuildContext context) {
    // Check if user is authenticated
    if (!GoogleAuthService.isLoggedIn) {
      _showGuestSignInDialog(context);
      return;
    }
    
    // User is authenticated, show add to cart dialog
    _showAuthenticatedAddToCartDialog(context);
  }

  void _showGuestSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.login, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text(
              'Sign In Required',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Please sign in to add items to your cart',
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/google-signin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showAuthenticatedAddToCartDialog(BuildContext context) {
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.shopping_cart, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text(
                'Add to Cart',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImageWidget(
                      imageUrl: widget.product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ProductPlaceholder(
                        width: 50,
                        height: 50,
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
                          widget.product.brand,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '\$${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quantity selector
              const Text(
                'Quantity:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? () {
                      setState(() {
                        quantity--;
                      });
                    } : null,
                    icon: const Icon(Icons.remove),
                    color: Colors.white,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: quantity < widget.product.stockQuantity ? () {
                      setState(() {
                        quantity++;
                      });
                    } : null,
                    icon: const Icon(Icons.add),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ${widget.product.stockQuantity}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
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
              onPressed: () async {
                try {
                  await BuyCartService.addToCart(
                    productId: widget.product.id,
                    productName: widget.product.name,
                    productImageUrl: widget.product.imageUrl,
                    price: widget.product.price,
                    quantity: quantity,
                    condition: widget.product.condition,
                    stockQuantity: widget.product.stockQuantity,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.product.name} added to cart'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
