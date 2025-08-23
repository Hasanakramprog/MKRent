import 'package:flutter/material.dart';
import '../models/buy_product.dart';
import '../services/buy_product_service.dart';
import '../services/buy_cart_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/buy_product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/notification_badge.dart';
import '../widgets/brand_slider.dart';
import 'welcome_screen.dart';

class BuyAppHomeScreen extends StatefulWidget {
  final bool isGuestMode;
  
  const BuyAppHomeScreen({super.key, this.isGuestMode = false});

  @override
  State<BuyAppHomeScreen> createState() => _BuyAppHomeScreenState();
}

class _BuyAppHomeScreenState extends State<BuyAppHomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  List<BuyProduct> _products = [];
  List<BuyProduct> _filteredProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _minPrice = 0;
  double _maxPrice = 10000; // Higher max for camera equipment
  double _minRating = 0;
  bool _isLoading = true;
  
  bool get _isGuestMode => widget.isGuestMode;

  // ScaffoldMessenger reference for safe SnackBar usage
  ScaffoldMessengerState? _scaffoldMessenger;

  // Animation controllers for search section
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearchVisible = true;

  // Animation controllers for "Buy" text
  late AnimationController _buyTextAnimationController;
  late Animation<double> _buyTextScaleAnimation;
  late Animation<Color?> _buyTextColorAnimation;
  bool _isAnimationInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  void _showSnackBar(String message, {Color? backgroundColor, SnackBarAction? action}) {
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
          action: action,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    
    // Initialize animation controllers
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _searchAnimationController.forward();

    // Initialize "Buy" text animation
    _buyTextAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _buyTextScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _buyTextAnimationController,
      curve: Curves.elasticInOut,
    ));

    _buyTextColorAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFFFFD700),
    ).animate(CurvedAnimation(
      parent: _buyTextAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start the "Buy" text animation and repeat
    _buyTextAnimationController.repeat(reverse: true);
    
    // Mark animation as initialized
    _isAnimationInitialized = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchAnimationController.dispose();
    if (_isAnimationInitialized) {
      _buyTextAnimationController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      print('BuyAppHomeScreen: App resumed, refreshing products...');
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load categories and products
      final categories = await BuyProductService.getCategories();
      final products = await BuyProductService.getAllProducts();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading buy app data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategoryProducts(String category) async {
    setState(() => _isLoading = true);
    
    try {
      final products = await BuyProductService.getProductsByCategory(category);
      
      if (mounted) {
        setState(() {
          _products = products;
          _selectedCategory = category;
          _isLoading = false;
        });
        
        // Apply other filters after loading category products
        _applyFilters();
      }
    } catch (e) {
      print('Error loading category products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final matchesSearch = product.name.toLowerCase().contains(searchLower) ||
                               product.description.toLowerCase().contains(searchLower) ||
                               product.brand.toLowerCase().contains(searchLower);
          if (!matchesSearch) return false;
        }

        // Price filter
        if (product.price < _minPrice || product.price > _maxPrice) {
          return false;
        }

        // Rating filter
        if (product.rating < _minRating) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        onApplyFilters: (double minPrice, double maxPrice, double minRating) {
          setState(() {
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _minRating = minRating;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _toggleSearchSection() {
    if (!mounted) return;
    
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
    if (_isSearchVisible) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }

  Widget _buildCartButton() {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<int>(
        stream: BuyCartService.getBuyCartItemCountStream(),
        builder: (context, snapshot) {
          final itemCount = snapshot.data ?? 0;
          return Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/buy-cart');
                },
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                tooltip: 'Buy Cart',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount > 99 ? '99+' : '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestSignInButton() {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/welcome');
        },
        icon: const Icon(
          Icons.login,
          color: Color(0xFFFFD700),
          size: 16,
        ),
        label: const Text(
          'Sign In',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
        ),
      ),
    );
  }

  Widget _buildCompactIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    double marginRight = 8,
  }) {
    return Container(
      margin: EdgeInsets.only(right: marginRight),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: const Color(0xFFFFD700),
          size: 20,
        ),
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  Future<void> _addToCart(BuyProduct product) async {
    try {
      if (!GoogleAuthService.isLoggedIn) {
        // Show sign-in dialog for guests
        _showSignInRequiredDialog();
        return;
      }

      await BuyCartService.addToCart(
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
        price: product.price,
        quantity: 1,
        condition: product.condition,
        stockQuantity: product.stockQuantity,
      );

      _showSnackBar(
        '${product.name} added to cart',
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/buy-cart');
          },
        ),
      );
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', backgroundColor: Colors.red);
    }
  }

  void _showSignInRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.login, color: Color(0xFF4CAF50)),
            SizedBox(width: 12),
            Text(
              'Sign In Required',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'You need to sign in to add items to your cart and make purchases.',
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
              Navigator.pushReplacementNamed(context, '/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop(); // Close dialog first
              
              try {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                );

                await GoogleAuthService.signOut();
                
                // Close loading dialog
                navigator.pop();
                
                // Navigate to welcome screen
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              } catch (e) {
                // Close loading dialog
                navigator.pop();
                
                _showSnackBar('Error signing out: $e', backgroundColor: Colors.red);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAppSwitcher() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.apps, color: Color(0xFFFFD700), size: 24),
            SizedBox(width: 12),
            Text(
              'Switch App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose which app you want to use:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              
              // Rent App Option
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to main rent app home screen
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rent App',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Rent professional equipment',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Buy App - Currently Active
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buy App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Currently Active',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Marketplace - Coming Soon
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonDialog();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Marketplace',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Coming Soon',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'The Marketplace is currently under development. We\'ll notify you when it\'s available!',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Black background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  // MKPro Logo Image - Made smaller to fit better
                  Container(
                    height: 40,
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logos/MKPro.jpg',
                        height: 40,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 40,
                            width: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'MKPro',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "Buy" label with animation
                  _isAnimationInitialized
                      ? AnimatedBuilder(
                          animation: _buyTextAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buyTextScaleAnimation.value,
                              child: Text(
                                'Buy App',
                                style: TextStyle(
                                  color: _buyTextColorAnimation.value,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3.0,
                                      color: (_buyTextColorAnimation.value ?? const Color(0xFFFFD700)).withOpacity(0.5),
                                      offset: const Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const Text(
                          'Buy App',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const Spacer(),
                  // Cart button with badge (authenticated users) or Sign In button (guests)
                  _isGuestMode
                      ? _buildGuestSignInButton()
                      : _buildCartButton(),
                  // App Switcher button - Made more compact
                  _buildCompactIconButton(
                    onPressed: () => _showAppSwitcher(),
                    icon: Icons.apps,
                    tooltip: 'Switch App',
                    marginRight: 4,
                  ),
                  // Notification button - Made more compact
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const NotificationIconButton(
                      iconColor: Color(0xFFFFD700),
                    ),
                  ),
                  // Profile menu button - Made more compact
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.person, color: Color(0xFFFFD700), size: 20),
                      color: const Color(0xFF1A1A1A),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _showLogoutDialog();
                        } else if (value == 'categories') {
                          Navigator.pushNamed(context, '/category-management');
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                GoogleAuthService.currentUser?.name ?? 'User',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'role',
                          child: Row(
                            children: [
                              Icon(
                                GoogleAuthService.isAdmin
                                    ? Icons.business
                                    : Icons.person,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                GoogleAuthService.isAdmin
                                    ? 'Store Owner'
                                    : 'Customer',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // Show Category Management only for admin users
                        if (GoogleAuthService.isAdmin)
                          const PopupMenuItem(
                            value: 'categories',
                            child: Row(
                              children: [
                                Icon(Icons.category, color: Color(0xFFFFD700)),
                                SizedBox(width: 8),
                                Text(
                                  'Manage Categories',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        if (GoogleAuthService.isAdmin) const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Brand Slider
            const CompactBrandSlider(),

            // Search Toggle Button and Search Section
            AnimatedBuilder(
              animation: _searchAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    // Search Toggle Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Search & Filter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _toggleSearchSection,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: AnimatedRotation(
                                turns: _isSearchVisible ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: Color(0xFFFFD700),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Animated Search Section
                    SizeTransition(
                      sizeFactor: _searchAnimation,
                      child: Column(
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SearchBarWidget(
                              onChanged: _performSearch,
                              onFilterTap: _showFilterBottomSheet,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Category Chips
                          SizedBox(
                            height: 45,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: CategoryChip(
                                    label: category,
                                    isSelected: _selectedCategory == category,
                                    onTap: () {
                                      if (category == 'All') {
                                        setState(() {
                                          _selectedCategory = 'All';
                                        });
                                        _loadData();
                                      } else {
                                        _loadCategoryProducts(category);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Filter Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${_filteredProducts.length} cameras',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _showFilterBottomSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.filter_list,
                                          color: Color(0xFFFFD700),
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Filter',
                                          style: TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Products Grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFFFFD700),
                backgroundColor: Colors.grey[900],
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No cameras found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search or filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return BuyProductCard(
                                product: product,
                                // Let the card handle its own navigation
                                // onTap: () => _addToCart(product),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isGuestMode && GoogleAuthService.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/add-buy-product');
                if (result == true) {
                  _loadData(); // Refresh the product list
                }
              },
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
