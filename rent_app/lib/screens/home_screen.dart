import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/google_auth_service.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/notification_badge.dart';
import '../widgets/brand_slider.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuestMode;
  
  const HomeScreen({super.key, this.isGuestMode = false});

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
  double _maxPrice = 1000;
  double _minRating = 0;
  bool _isLoading = true;
  
  bool get _isGuestMode => widget.isGuestMode;

  // Animation controllers for FAB labels
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isFabExpanded = false;

  // Animation controllers for search section
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearchVisible = true;

  // Animation controllers for "Rent" text
  late AnimationController _rentTextAnimationController;
  late Animation<double> _rentTextScaleAnimation;
  late Animation<Color?> _rentTextColorAnimation;
  bool _isRentAnimationInitialized = false;

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

    // Initialize "Rent" text animation
    _rentTextAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rentTextScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _rentTextAnimationController,
      curve: Curves.elasticInOut,
    ));

    _rentTextColorAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFFFFD700),
    ).animate(CurvedAnimation(
      parent: _rentTextAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start the "Rent" text animation and repeat
    _rentTextAnimationController.repeat(reverse: true);
    
    // Mark animation as initialized
    _isRentAnimationInitialized = true;
    
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
    
    if (_isRentAnimationInitialized) {
      if (_rentTextAnimationController.isAnimating) {
        _rentTextAnimationController.stop();
      }
      _rentTextAnimationController.dispose();
    }
    
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
                    heroTag: "home_${heroTag}_${GoogleAuthService.isAdmin ? 'admin' : 'customer'}",
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
                await GoogleAuthService.signOut();
                
                // Check if widget is still mounted before navigation
                if (!mounted) return;
                
                // Navigate to Welcome screen and clear all previous routes
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
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
            
            // Buy App
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/buy-app-home');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buy App',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Buy Equipment',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF4CAF50), size: 16),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Marketplace App
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/marketplace-home');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: Colors.purple),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marketplace App',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Buy & Sell Equipment',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 16),
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
                  // "Rent" label with animation
                  _isRentAnimationInitialized
                      ? AnimatedBuilder(
                          animation: _rentTextAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _rentTextScaleAnimation.value,
                              child: Text(
                                'Rent App',
                                style: TextStyle(
                                  color: _rentTextColorAnimation.value,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3.0,
                                      color: (_rentTextColorAnimation.value ?? const Color(0xFFFFD700)).withOpacity(0.5),
                                      offset: const Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const Text(
                          'Rent App',
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
                          child: CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                sliver: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return ProductCard(
                                        product: _filteredProducts[index],
                                        onProductUpdated: () {
                                          // Refresh products when a product is updated or deleted
                                          _refreshProducts();
                                        },
                                      );
                                    },
                                    childCount: _filteredProducts.length,
                                  ),
                                ),
                              ),
                              // Social Media Footer
                              SliverToBoxAdapter(
                                child: _buildSocialMediaFooter(),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isGuestMode ? null : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show Admin options only for admin users
          if (GoogleAuthService.isAdmin) ...[
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
              heroTag: "rent_requests_admin",
              onPressed: () {
                if (!mounted) return;
                _showAdminOptionsBottomSheet(context);
              },
              icon: Icons.assignment,
              label: "Rent Requests",
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 16),
          ],
          // Show My Requests only for customer users (not admin)
          if (!GoogleAuthService.isAdmin) ...[
            _buildAnimatedFab(
              heroTag: "my_requests",
              onPressed: () {
                if (!mounted) return;
                Navigator.pushNamed(context, '/bulk-rental-requests');
              },
              icon: Icons.assignment,
              label: "My Requests",
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 16),
          ],
          // Main toggle FAB
          FloatingActionButton(
            heroTag: "home_main_toggle_${GoogleAuthService.isAdmin ? 'admin' : 'customer'}",
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
        stream: CartService.getCartItemCountStream(),
        builder: (context, snapshot) {
          final itemCount = snapshot.data ?? 0;
          return Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                tooltip: 'Cart',
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

  void _showAdminOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Rent Requests Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Rent Requests Option
              _buildAdminOption(
                context: context,
                title: 'View Rent Requests',
                subtitle: 'Manage customer rental requests',
                icon: Icons.assignment_turned_in,
                color: const Color(0xFFFFD700),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/bulk-rental-requests');
                },
              ),
              
              const SizedBox(height: 12),
              
              // Cache Management Option
              _buildAdminOption(
                context: context,
                title: 'Cache Management',
                subtitle: 'Clear Firebase Storage image cache',
                icon: Icons.storage,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/cache-management');
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Connect With Us',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Follow us on social media for updates and exclusive offers',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialMediaButton(
                icon: Icons.camera_alt,
                label: 'Instagram',
                color: const Color(0xFFE4405F),
                onTap: () => _launchSocialMedia('instagram'),
              ),
              _buildSocialMediaButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _launchSocialMedia('whatsapp'),
              ),
              _buildSocialMediaButton(
                icon: Icons.facebook,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => _launchSocialMedia('facebook'),
              ),
              _buildSocialMediaButton(
                icon: Icons.music_note,
                label: 'TikTok',
                color: const Color(0xFF000000),
                onTap: () => _launchSocialMedia('tiktok'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025 MK Rent. All rights reserved.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _launchSocialMedia(String platform) async {
    String url = '';
    switch (platform) {
      case 'instagram':
        url = 'https://www.instagram.com/mkpro_eq/'; // Replace with your actual Instagram
        break;
      case 'whatsapp':
        url = 'https://wa.me/76808887'; // Replace with your actual WhatsApp number
        break;
      case 'facebook':
        url = 'https://www.facebook.com/MKProOffical/'; // Replace with your actual Facebook page
        break;
      case 'tiktok':
        url = 'https://www.tiktok.com/@mkproeq'; // Replace with your actual TikTok
        break;
    }
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $platform'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening $platform: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
