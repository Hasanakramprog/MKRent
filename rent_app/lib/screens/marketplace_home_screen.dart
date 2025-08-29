import 'package:flutter/material.dart';
import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/marketplace_listing_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chip.dart';
import 'marketplace_create_listing_screen.dart';
import 'marketplace_listing_detail_screen.dart';
import 'marketplace_my_listings_screen.dart';
import 'welcome_screen.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<MarketplaceListing> _allListings = [];
  List<MarketplaceListing> _featuredListings = [];
  List<MarketplaceListing> _filteredListings = [];
  
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  
  final List<String> _categories = [
    'Cameras',
    'Lenses',
    'Drones',
    'Lighting',
    'Audio',
    'Accessories',
    'Tripods',
    'Filters',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        MarketplaceService.getListings(),
        MarketplaceService.getFeaturedListings(),
      ]);
      
      _allListings = futures[0];
      _featuredListings = futures[1];
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
               listing.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((listing) => listing.category == _selectedCategory).toList();
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Camera Marketplace',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFFFFD700)),
            onPressed: _showFilterSheet,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
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
              const PopupMenuItem(
                value: 'my_listings',
                child: Row(
                  children: [
                    Icon(Icons.list, color: Color(0xFFFFD700)),
                    SizedBox(width: 8),
                    Text('My Listings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFFD700),
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Featured'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: Column(
        children: [
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
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListingsGrid(_filteredListings),
                      _buildListingsGrid(_featuredListings),
                      _buildListingsGrid(_allListings),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
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
          );
        },
      ),
    );
  }
}
