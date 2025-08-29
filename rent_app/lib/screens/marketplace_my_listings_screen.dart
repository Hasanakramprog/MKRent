import 'package:flutter/material.dart';
import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/marketplace_listing_card.dart';
import 'marketplace_create_listing_screen.dart';
import 'marketplace_listing_detail_screen.dart';

class MarketplaceMyListingsScreen extends StatefulWidget {
  const MarketplaceMyListingsScreen({super.key});

  @override
  State<MarketplaceMyListingsScreen> createState() => _MarketplaceMyListingsScreenState();
}

class _MarketplaceMyListingsScreenState extends State<MarketplaceMyListingsScreen> {
  List<MarketplaceListing> _myListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyListings();
  }

  Future<void> _loadMyListings() async {
    if (GoogleAuthService.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final listings = await MarketplaceService.getUserListings(GoogleAuthService.currentUser!.id);
      if (mounted) {
        setState(() {
          _myListings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading listings: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteListing(MarketplaceListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Listing', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${listing.title}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await MarketplaceService.deleteListing(listing.id);
        if (success) {
          _showSnackBar('Listing deleted successfully', Colors.green);
          _loadMyListings(); // Reload the list
        } else {
          _showSnackBar('Failed to delete listing', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Error deleting listing: $e', Colors.red);
      }
    }
  }

  Future<void> _toggleAvailability(MarketplaceListing listing) async {
    try {
      if (listing.isAvailable) {
        final success = await MarketplaceService.markAsUnavailable(listing.id);
        if (success) {
          _showSnackBar('Listing marked as unavailable', Colors.orange);
          _loadMyListings();
        }
      } else {
        // Note: You'll need to add a method to mark as available in the service
        _showSnackBar('Feature coming soon', Colors.blue);
      }
    } catch (e) {
      _showSnackBar('Error updating listing: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (GoogleAuthService.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          title: const Text('My Listings'),
        ),
        body: const Center(
          child: Text(
            'Please sign in to view your listings',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('My Listings'),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceCreateListingScreen(),
                ),
              );
              if (result != null) {
                _loadMyListings(); // Reload if a listing was created
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
              ),
            )
          : _myListings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No listings yet',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first listing to start selling',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MarketplaceCreateListingScreen(),
                            ),
                          );
                          if (result != null) {
                            _loadMyListings();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Listing'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyListings,
                  color: const Color(0xFF9C27B0),
                  backgroundColor: const Color(0xFF1A1A1A),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myListings.length,
                    itemBuilder: (context, index) {
                      final listing = _myListings[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          color: const Color(0xFF1A1A1A),
                          child: Column(
                            children: [
                              MarketplaceListingCard(
                                listing: listing,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MarketplaceListingDetailScreen(
                                        listingId: listing.id,
                                        listing: listing,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              // Action buttons
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MarketplaceCreateListingScreen(
                                              editListing: listing,
                                            ),
                                          ),
                                        );
                                        if (result != null) {
                                          _loadMyListings();
                                        }
                                      },
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                      ),
                                    ),
                                    
                                    TextButton.icon(
                                      onPressed: () => _toggleAvailability(listing),
                                      icon: Icon(
                                        listing.isAvailable ? Icons.visibility_off : Icons.visibility,
                                        size: 16,
                                      ),
                                      label: Text(listing.isAvailable ? 'Hide' : 'Show'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: listing.isAvailable ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                    
                                    TextButton.icon(
                                      onPressed: () => _deleteListing(listing),
                                      icon: const Icon(Icons.delete, size: 16),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Status indicator
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: listing.isAvailable 
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                ),
                                child: Text(
                                  listing.isAvailable ? 'ACTIVE' : 'INACTIVE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: listing.isAvailable ? Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _myListings.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MarketplaceCreateListingScreen(),
                  ),
                );
                if (result != null) {
                  _loadMyListings();
                }
              },
              backgroundColor: const Color(0xFF9C27B0),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
