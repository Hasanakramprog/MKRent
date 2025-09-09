import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/marketplace_listing.dart';
import '../services/marketplace_service.dart';
import '../services/google_auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/cached_image_widget.dart';
import 'chat_detail_screen.dart';

class MarketplaceListingDetailScreen extends StatefulWidget {
  final String listingId;
  final MarketplaceListing? listing;

  const MarketplaceListingDetailScreen({
    super.key,
    required this.listingId,
    this.listing,
  });

  @override
  State<MarketplaceListingDetailScreen> createState() => _MarketplaceListingDetailScreenState();
}

class _MarketplaceListingDetailScreenState extends State<MarketplaceListingDetailScreen> {
  MarketplaceListing? _listing;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    if (_listing == null) {
      _loadListing();
    }
  }

  Future<void> _loadListing() async {
    setState(() => _isLoading = true);
    try {
      final listing = await MarketplaceService.getListing(widget.listingId);
      if (mounted) {
        setState(() {
          _listing = listing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading listing: $e', Colors.red);
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

  Future<void> _contactSeller(String type) async {
    if (_listing == null) return;

    try {
      Uri uri;
      if (type == 'phone') {
        uri = Uri.parse('tel:${_listing!.contactPhone}');
      } else if (type == 'email') {
        uri = Uri.parse('mailto:${_listing!.contactEmail}?subject=Inquiry about ${_listing!.title}');
      } else if (type == 'whatsapp') {
        uri = Uri.parse('https://wa.me/${_listing!.contactPhone}?text=Hi, I\'m interested in your listing: ${_listing!.title}');
      } else {
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not launch $type', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error contacting seller: $e', Colors.red);
    }
  }

  Future<void> _startProductChat() async {
    try {
      final currentUser = GoogleAuthService.currentUser;
      if (currentUser == null) {
        _showSnackBar('Please sign in to chat about this product', Colors.red);
        return;
      }

      if (_listing == null) {
        _showSnackBar('Listing not found', Colors.red);
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
        product: _listing!,
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
        _showSnackBar('Failed to start chat: $e', Colors.red);
      }
      print('Error starting product chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
        ),
      );
    }

    if (_listing == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          title: const Text('Listing Not Found'),
        ),
        body: const Center(
          child: Text(
            'Listing not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: CustomScrollView(
        slivers: [
          // Image Carousel AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _listing!.imageUrls.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemCount: _listing!.imageUrls.length,
                          itemBuilder: (context, index) {
                            return CachedImageWidget(
                              imageUrl: _listing!.imageUrls[index],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) {
                                return Container(
                                  color: const Color(0xFF2A2A2A),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFF9C27B0),
                                    size: 80,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        if (_listing!.imageUrls.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _listing!.imageUrls.asMap().entries.map((entry) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? const Color(0xFF9C27B0)
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF9C27B0),
                        size: 80,
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _listing!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _listing!.formattedPrice,
                            style: const TextStyle(
                              color: Color(0xFF9C27B0),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_listing!.isNegotiable)
                            const Text(
                              'Negotiable',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status badges
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusChip(_listing!.brand, const Color(0xFFFFD700)),
                      _buildStatusChip(_listing!.conditionText, Colors.blue),
                      _buildStatusChip(_listing!.category, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // MKPro Chat Button
                  GestureDetector(
                    onTap: () => _startProductChat(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
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
                              Icons.chat,
                              color: Color(0xFFFFD700),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MKPro Chat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Get help about this product',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFFFFD700),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _listing!.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow('Brand', _listing!.brand),
                  _buildDetailRow('Location', _listing!.location),
                  _buildDetailRow('Condition', _listing!.conditionText),
                  _buildDetailRow('Views', _listing!.viewCount.toString()),
                  _buildDetailRow('Listed', _formatDate(_listing!.createdAt)),

                  if (_listing!.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _listing!.tags.map((tag) => 
                        Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          backgroundColor: const Color(0xFF2A2A2A),
                          labelStyle: const TextStyle(color: Colors.white),
                          side: const BorderSide(color: Color(0xFF9C27B0)),
                        ),
                      ).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Seller Info (Only visible to admins)
                  if (GoogleAuthService.isAdmin) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Seller Information (Admin Only)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF9C27B0),
                                child: Text(
                                  _listing!.sellerName.isNotEmpty 
                                      ? _listing!.sellerName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _listing!.sellerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.orange, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          _listing!.sellerRating.toStringAsFixed(1),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Contact Information
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.email, color: Color(0xFF9C27B0), size: 16),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Email:',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SelectableText(
                                        _listing!.contactEmail,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, color: Color(0xFF4CAF50), size: 16),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Phone:',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SelectableText(
                                        _listing!.contactPhone,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ),
        ],
      ),

      // Contact Floating Action Buttons (Only for non-admin users who are not the seller)
      // floatingActionButton: !GoogleAuthService.isAdmin && 
      //                      _listing!.sellerId != GoogleAuthService.currentUser?.id
      //     ? Column(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           FloatingActionButton.extended(
      //             heroTag: "phone_fab",
      //             onPressed: () => _contactSeller('phone'),
      //             backgroundColor: const Color(0xFF4CAF50),
      //             icon: const Icon(Icons.phone),
      //             label: const Text('Call'),
      //           ),
      //           const SizedBox(height: 8),
      //           FloatingActionButton.extended(
      //             heroTag: "whatsapp_fab",
      //             onPressed: () => _contactSeller('whatsapp'),
      //             backgroundColor: const Color(0xFF25D366),
      //             icon: const Icon(Icons.message),
      //             label: const Text('WhatsApp'),
      //           ),
      //           const SizedBox(height: 8),
      //           FloatingActionButton.extended(
      //             heroTag: "email_fab",
      //             onPressed: () => _contactSeller('email'),
      //             backgroundColor: const Color(0xFF9C27B0),
      //             icon: const Icon(Icons.email),
      //             label: const Text('Email'),
      //           ),
              // ],
            // )
          // : null,
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}
