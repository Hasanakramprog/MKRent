import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/notification_badge.dart';
import '../widgets/brand_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _minPrice = 0;
  double _maxPrice = 150;
  double _minRating = 0;
  bool _isLoading = true;

  // Animation controllers for FAB labels
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isFabExpanded = false;

  // Animation controllers for search section
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();   WidgetsBinding.instance.addObserver(this);
    _loadData();
    
    // Initialize animation controller for FAB
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialize animation controller for search section
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Start with search section visible
    _searchAnimationController.forward();
    
    // Auto-collapse search section after 3 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isSearchVisible) {
        _toggleSearchSection();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Ensure animation controllers are disposed safely
    if (_fabAnimationController.isAnimating) {
      _fabAnimationController.stop();
    }
    _fabAnimationController.dispose();
    
    if (_searchAnimationController.isAnimating) {
      _searchAnimationController.stop();
    }
    _searchAnimationController.dispose();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      print('HomeScreen: App resumed, refreshing products...');
      _refreshProducts();
    }
  }

  Future<void> _loadData() async {
    try {
      // Load categories first
      final categories = await ProductService.getCategories();
      _categories = categories;
      
      // Load products for selected category (initially 'All')
      await _loadProductsByCategory();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Capture ScaffoldMessenger early
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    if (!mounted) return;
    
    setState(() {
      _filteredProducts = _products.where((product) {
        // Category filtering is now done at Firebase level, so skip it here
        
        // Search filter
        bool searchMatch =
            _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            product.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
            );

        // Price filter
        bool priceMatch =
            product.price >= _minPrice && product.price <= _maxPrice;

        // Rating filter
        bool ratingMatch = product.rating >= _minRating;

        return searchMatch && priceMatch && ratingMatch;
      }).toList();
      
      print('Filtered to ${_filteredProducts.length} products');
    });
  }

  void _onCategorySelected(String category) {
    if (!mounted) return;
    
    setState(() {
      _selectedCategory = category;
    });
    _loadProductsByCategory();
  }

  Future<void> _loadProductsByCategory() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      print('Loading products for category: $_selectedCategory');
      
      List<Product> products;
      if (_selectedCategory == 'All') {
        products = await ProductService.getAllProducts();
      } else {
        products = await ProductService.getProductsByCategory(_selectedCategory);
      }
      
      print('Loaded ${products.length} products for category: $_selectedCategory');
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
        
        // Apply other filters after loading category products
        _filterProducts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        print('Error loading products by category: $e');
        
        // Capture ScaffoldMessenger early
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;
    
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  Future<void> _refreshProducts() async {
    // Add debug logging
    print('HomeScreen: Refreshing products...');
    
    // Add a small delay to ensure Firebase operations are complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Refresh the products list after update/delete operations
    await _loadProductsByCategory();
    
    print('HomeScreen: Products refreshed successfully');
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
          if (!mounted) return;
          
          setState(() {
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _minRating = minRating;
          });
          _filterProducts();
        },
      ),
    );
  }

  void _toggleFabLabels() {
    if (!mounted) return;
    
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
    if (_isFabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
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

  Widget _buildAnimatedFab({
    required String heroTag,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            30 * (1 - _fabAnimation.value), // Slide up animation
          ),
          child: Opacity(
            opacity: _fabAnimation.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Animated label
                Transform.translate(
                  offset: Offset(
                    -20 + (20 * _fabAnimation.value), // Slide from right
                    0,
                  ),
                  child: Opacity(
                    opacity: _fabAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: backgroundColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: backgroundColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: backgroundColor == const Color(0xFF1A1A1A) 
                              ? const Color(0xFFFFD700) 
                              : backgroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // FloatingActionButton with scale animation
                Transform.scale(
                  scale: 0.8 + (0.2 * _fabAnimation.value),
                  child: FloatingActionButton(
                    heroTag: heroTag,
                    onPressed: _isFabExpanded ? onPressed : null,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    child: Icon(icon),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
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
              // Capture navigator and scaffold messenger early
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              navigator.pop(); // Close dialog first
              
              // Check if widget is still mounted before proceeding
              if (!mounted) return;
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                  ),
                ),
              );
              
              try {
                await AuthService.signOut();
                
                // Check if widget is still mounted before navigation
                if (!mounted) return;
                
                // Navigate to welcome screen and clear all previous routes
                navigator.pushNamedAndRemoveUntil(
                  '/welcome', 
                  (route) => false,
                );
              } catch (e) {
                // Check if widget is still mounted before showing UI updates
                if (!mounted) return;
                
                // Close loading dialog
                navigator.pop();
                
                // Show error message
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                }
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
        title: Row(
          children: [
            const Icon(Icons.apps, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            const Text('Switch App', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose which app you want to use:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Current App (Rent App)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rent App',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Currently Active',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Color(0xFFFFD700)),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Buy App (Coming Soon)
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buy App',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/app-selection', (route) => false);
            },
            child: const Text(
              'Go to App Selection',
              style: TextStyle(color: Color(0xFFFFD700)),
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
          'The Buy App is currently under development. We\'ll notify you when it\'s available!',
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // MKPro Logo Image
                  Container(
                    height: 55, // Height that matches the original location section
                    width: 130, // Width to fit the content area
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logos/MKPro.jpg',
                        height: 55,
                        width: 130,
                        fit: BoxFit.cover, // Fill the container while maintaining aspect ratio
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 55,
                            width: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'MKPro',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  // App Switcher button
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A), // Dark gray
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        _showAppSwitcher();
                      },
                      icon: const Icon(
                        Icons.apps,
                        color: Color(0xFFFFD700),
                      ),
                      tooltip: 'Switch App',
                    ),
                  ),
                  // Notification button
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A), // Dark gray
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const NotificationIconButton(
                      iconColor: Color(0xFFFFD700),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A), // Dark gray
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.person, color: Color(0xFFFFD700)),
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
                                AuthService.currentUser?.name ?? 'User',
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
                                AuthService.isAdmin
                                    ? Icons.business
                                    : Icons.person,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AuthService.isAdmin
                                    ? 'Store Owner'
                                    : 'Customer',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // Show Category Management only for admin users
                        if (AuthService.isAdmin)
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
                        if (AuthService.isAdmin) const PopupMenuDivider(),
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
                              onChanged: _onSearchChanged,
                              onFilterTap: _showFilterBottomSheet,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // Categories
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CategoryChip(
                      label: category,
                      isSelected: _selectedCategory == category,
                      onTap: () => _onCategorySelected(category),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Results Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Found ${_filteredProducts.length} Items',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.sort, color: const Color(0xFFFFD700)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Products Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD700),
                      ),
                    )
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No cameras found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[300],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshProducts,
                          color: const Color(0xFFFFD700),
                          backgroundColor: const Color(0xFF1A1A1A),
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCard(
                                product: _filteredProducts[index],
                                onProductUpdated: () {
                                  // Refresh products when a product is updated or deleted
                                  _refreshProducts();
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show Store Management only for admin users
          if (AuthService.isAdmin) ...[
            _buildAnimatedFab(
              heroTag: "add_product",
              onPressed: () async {
                if (!mounted) return;
                
                final result = await Navigator.pushNamed(context, '/add-product');
                if (result == true && mounted) {
                  // Refresh products when a new one is added
                  _refreshProducts();
                }
              },
              icon: Icons.add,
              label: "Add Product",
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 16),
            _buildAnimatedFab(
              heroTag: "store_management",
              onPressed: () {
                if (!mounted) return;
                Navigator.pushNamed(context, '/store-management');
              },
              icon: Icons.business,
              label: "Store Management",
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 16),
          ],
          // Show My Requests only for customer users (not admin)
          if (!AuthService.isAdmin) ...[
            _buildAnimatedFab(
              heroTag: "my_requests",
              onPressed: () {
                if (!mounted) return;
                Navigator.pushNamed(context, '/rental-requests');
              },
              icon: Icons.receipt_long,
              label: "My Requests",
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 16),
          ],
          // Main toggle FAB
          FloatingActionButton(
            heroTag: "main_toggle",
            onPressed: _toggleFabLabels,
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            child: AnimatedBuilder(
              animation: _fabAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _fabAnimation.value * 0.785398, // 45 degrees in radians
                  child: Icon(
                    _isFabExpanded ? Icons.close : Icons.menu,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
