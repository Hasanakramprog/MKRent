import 'package:flutter/material.dart';
import 'dart:async';
import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../services/google_auth_service.dart';
import '../services/category_service.dart';
import '../services/chat_service.dart';
import '../widgets/marketplace_listing_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chip.dart';
import 'marketplace_create_listing_screen.dart';
import 'marketplace_listing_detail_screen.dart';
import 'marketplace_my_listings_screen.dart';
import 'chat_list_screen.dart';
import 'chat_detail_screen.dart';
import 'public_chat_screen.dart';
import 'welcome_screen.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  List<MarketplaceListing> _allListings = [];
  List<MarketplaceListing> _filteredListings = [];
  
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedLocation;
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'newest'; // newest, oldest, price_low, price_high, most_viewed
  bool _isLoading = true;
  
  List<String> _categories = []; // Will be loaded from Firebase
  Timer? _debounceTimer; // Timer for debouncing price filter input
  
  // Text controllers for price fields to maintain cursor position
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final List<String> _conditions = [
    'New',
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Price: Low to High',
    'Price: High to Low',
    'Most Viewed',
  ];

  final List<String> _locations = [
    'Beirut',
    'Tripoli',
    'Sidon',
    'Tyre',
    'Nabatieh',
    'Baalbek',
    'Jounieh',
    'Zahlé',
    'Byblos',
    'Anjar',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Cancel any pending timer
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _debouncedApplyFilters() {
    _debounceTimer?.cancel(); // Cancel previous timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFilters(); // Apply filters after 500ms delay
      print('Filters applied after debounce');
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize default categories if none exist
      await CategoryService.initializeDefaultCategories();
      
      final futures = await Future.wait([
        MarketplaceService.getListings(),
        MarketplaceService.getCategories(), // Load categories from Firebase
      ]);
      
      _allListings = futures[0] as List<MarketplaceListing>;
      _categories = futures[1] as List<String>; // Set categories from Firebase
      _filteredListings = _allListings;
    } catch (e) {
      print('Error loading marketplace data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    List<MarketplaceListing> filtered = _allListings;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((listing) {
        return listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               listing.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               listing.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               listing.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((listing) => listing.category == _selectedCategory).toList();
    }
    
    // Apply condition filter
    if (_selectedCondition != null) {
      filtered = filtered.where((listing) => listing.conditionText == _selectedCondition).toList();
    }
    
    // Apply location filter
    if (_selectedLocation != null) {
      filtered = filtered.where((listing) => listing.location.contains(_selectedLocation!)).toList();
    }
    
    // Apply price range filter
    filtered = filtered.where((listing) {
      return listing.price >= _minPrice && listing.price <= _maxPrice;
    }).toList();
    
    // Apply sorting
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'most_viewed':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }
    
    setState(() {
      _filteredListings = filtered;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
    _applyFilters();
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedCondition != null) count++;
    if (_selectedLocation != null) count++;
    if (_minPrice > 0 || _maxPrice < 10000) count++;
    if (_sortBy != 'newest') count++;
    return count;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          // Local state variables for immediate UI updates
          String localSortBy = _sortBy;
          String? localSelectedCategory = _selectedCategory;
          String? localSelectedCondition = _selectedCondition;
          String? localSelectedLocation = _selectedLocation;
          double localMinPrice = _minPrice;
          double localMaxPrice = _maxPrice;
          
          // Initialize controllers with current values if not already set
          if (_minPriceController.text.isEmpty || _minPriceController.text != localMinPrice.toStringAsFixed(0)) {
            _minPriceController.text = localMinPrice.toStringAsFixed(0);
          }
          if (_maxPriceController.text.isEmpty || _maxPriceController.text != localMaxPrice.toStringAsFixed(0)) {
            _maxPriceController.text = localMaxPrice.toStringAsFixed(0);
          }
          
          return DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Filter Results',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Sort By
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sortOptions.asMap().entries.map((entry) {
                    int index = entry.key;
                    String option = entry.value;
                    String value = ['newest', 'oldest', 'price_low', 'price_high', 'most_viewed'][index];
                    bool isSelected = localSortBy == value;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setModalState(() {
                            localSortBy = value; // Update local state immediately
                          });
                          setState(() {
                            _sortBy = value; // Update parent state
                          });
                          _applyFilters(); // Apply filters immediately
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFFFD700).withOpacity(0.8)
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              if (isSelected) const SizedBox(width: 4),
                              Text(
                                option,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Category Filter
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    bool isSelected = localSelectedCategory == category;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setModalState(() {
                            localSelectedCategory = isSelected ? null : category;
                          });
                          setState(() {
                            _selectedCategory = isSelected ? null : category;
                          });
                          _applyFilters(); // Apply filters immediately
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFFFD700).withOpacity(0.8)
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              if (isSelected) const SizedBox(width: 4),
                              Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Condition Filter
                const Text(
                  'Condition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _conditions.map((condition) {
                    bool isSelected = localSelectedCondition == condition;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setModalState(() {
                            localSelectedCondition = isSelected ? null : condition;
                          });
                          setState(() {
                            _selectedCondition = isSelected ? null : condition;
                          });
                          _applyFilters(); // Apply filters immediately
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFFFD700).withOpacity(0.8)
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              if (isSelected) const SizedBox(width: 4),
                              Text(
                                condition,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Location Filter
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _locations.map((location) {
                    bool isSelected = localSelectedLocation == location;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setModalState(() {
                            localSelectedLocation = isSelected ? null : location;
                          });
                          setState(() {
                            _selectedLocation = isSelected ? null : location;
                          });
                          _applyFilters(); // Apply filters immediately
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFFFD700).withOpacity(0.8)
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              if (isSelected) const SizedBox(width: 4),
                              Text(
                                location,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Price Range
                const Text(
                  'Price Range (\$)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '\$${localMinPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '\$${localMaxPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: RangeValues(localMinPrice, localMaxPrice),
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        activeColor: const Color(0xFFFFD700),
                        inactiveColor: Colors.grey,
                        onChanged: (values) {
                          setModalState(() {
                            localMinPrice = values.start;
                            localMaxPrice = values.end;
                          });
                          setState(() {
                            _minPrice = values.start;
                            _maxPrice = values.end;
                          });
                          _applyFilters(); // Apply filters immediately
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Min Price',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFFFD700)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              controller: _minPriceController,
                              onChanged: (value) {
                                final price = double.tryParse(value) ?? 0;
                                setModalState(() {
                                  localMinPrice = price.clamp(0, localMaxPrice);
                                });
                                setState(() {
                                  _minPrice = price.clamp(0, _maxPrice);
                                });
                                _debouncedApplyFilters(); // Use debounced filtering
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Max Price',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFFFD700)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              controller: _maxPriceController,
                              onChanged: (value) {
                                final price = double.tryParse(value) ?? 10000;
                                setModalState(() {
                                  localMaxPrice = price.clamp(localMinPrice, 10000);
                                });
                                setState(() {
                                  _maxPrice = price.clamp(_minPrice, 10000);
                                });
                                _debouncedApplyFilters(); // Use debounced filtering
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _selectedCondition = null;
                            _selectedLocation = null;
                            _minPrice = 0;
                            _maxPrice = 10000;
                            _sortBy = 'newest';
                          });
                          setModalState(() {
                            // Update modal state for immediate visual feedback
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Close button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        );
        },
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await GoogleAuthService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Column(
        children: [
          // Custom Header
          Container(
            color: const Color(0xFF000000), // Black background
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
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
                  // "Marketplace" label
                  const Text(
                    'Marketplace',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 3.0,
                          color: Color(0xFFFFD700),
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // App Switcher button
                  _buildCompactIconButton(
                    onPressed: () => _showAppSwitcher(),
                    icon: Icons.apps,
                    tooltip: 'Switch App',
                    marginRight: 4,
                  ),
                  // Chat button with badge
                  StreamBuilder<int>(
                    stream: GoogleAuthService.currentUser != null 
                        ? ChatService.getUnreadCountStream()
                        : Stream.value(0),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return _buildCompactIconButtonWithBadge(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatListScreen(),
                            ),
                          );
                        },
                        icon: Icons.chat,
                        tooltip: 'My Chats',
                        marginRight: 4,
                        badgeCount: unreadCount,
                      );
                    },
                  ),
                  // Profile menu button
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
                        switch (value) {
                          case 'my_listings':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MarketplaceMyListingsScreen(),
                              ),
                            );
                            break;
                          case 'logout':
                            _signOut();
                            break;
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
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'my_listings',
                          child: Row(
                            children: [
                              Icon(Icons.list, color: Color(0xFFFFD700)),
                              SizedBox(width: 8),
                              Text(
                                'My Listings',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
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
          ),
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: SearchBarWidget(
              onChanged: _onSearchChanged,
              onFilterTap: _showFilterSheet,
            ),
          ),
          
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onTap: () => _onCategorySelected(category),
                  ),
                );
              },
            ),
          ),
          
          // Active Filters Display
          if (_getActiveFilterCount() > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Active Filters:',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _selectedCondition = null;
                            _selectedLocation = null;
                            _minPrice = 0;
                            _maxPrice = 10000;
                            _sortBy = 'newest';
                          });
                          _applyFilters();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (_selectedCategory != null)
                        _buildActiveFilterChip('Category: $_selectedCategory', () {
                          setState(() => _selectedCategory = null);
                          _applyFilters();
                        }),
                      if (_selectedCondition != null)
                        _buildActiveFilterChip('Condition: $_selectedCondition', () {
                          setState(() => _selectedCondition = null);
                          _applyFilters();
                        }),
                      if (_selectedLocation != null)
                        _buildActiveFilterChip('Location: $_selectedLocation', () {
                          setState(() => _selectedLocation = null);
                          _applyFilters();
                        }),
                      if (_minPrice > 0 || _maxPrice < 10000)
                        _buildActiveFilterChip('Price: \$${_minPrice.toInt()}-\$${_maxPrice.toInt()}', () {
                          setState(() {
                            _minPrice = 0;
                            _maxPrice = 10000;
                          });
                          _applyFilters();
                        }),
                      if (_sortBy != 'newest')
                        _buildActiveFilterChip('Sort: ${_getSortDisplayName(_sortBy)}', () {
                          setState(() => _sortBy = 'newest');
                          _applyFilters();
                        }),
                    ],
                  ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  )
                : _buildListingsGrid(_filteredListings),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Discussion FAB with label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PublicChatScreen(),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF404040),
                foregroundColor: Colors.white,
                heroTag: "discussion_fab",
                child: const Icon(Icons.forum),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Discussion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Add Product FAB with label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarketplaceCreateListingScreen(),
                    ),
                  ).then((_) => _loadData()); // Refresh after creating listing
                },
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                heroTag: "add_product_fab",
                child: const Icon(Icons.add_box),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingsGrid(List<MarketplaceListing> listings) {
    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No listings found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to list your equipment!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF1A1A1A),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return MarketplaceListingCard(
            listing: listing,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketplaceListingDetailScreen(
                    listingId: listing.id,
                  ),
                ),
              );
            },
            onChatTap: () => _startProductChat(listing),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortDisplayName(String sortValue) {
    switch (sortValue) {
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      case 'most_viewed':
        return 'Most Viewed';
      default:
        return 'Newest First';
    }
  }

  Future<void> _startProductChat(MarketplaceListing listing) async {
    try {
      final currentUser = GoogleAuthService.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to chat about this product'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      );

      // Create or get existing chat for this product (will connect to admin with random name)
      final chatId = await ChatService.createOrGetProductChat(
        product: listing,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to chat detail screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chatId: chatId),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error starting product chat: $e');
    }
  }

  Widget _buildCompactIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    required double marginRight,
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
        icon: Icon(icon, color: const Color(0xFFFFD700), size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildCompactIconButtonWithBadge({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    required double marginRight,
    required int badgeCount,
  }) {
    return Container(
      margin: EdgeInsets.only(right: marginRight),
      child: Stack(
        children: [
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
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: const Color(0xFFFFD700), size: 20),
              tooltip: tooltip,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(badgeCount > 99 ? 4 : 6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
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
            
            // Current App (Marketplace App)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:  Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:  Colors.purple,
                  width: 2,
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
                          'Currently Active',
                          style: TextStyle(
                            color: Colors.purple,
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
            
            // Rent App
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFFFFD700).withOpacity(0.5),
                    width: 1,
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
                            'Rent Equipment',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700), size: 16),
                  ],
                ),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Colors.green),
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
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 16),
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
}
