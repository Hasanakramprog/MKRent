import 'package:flutter/material.dart';
import '../models/marketplace_listing.dart';

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final VoidCallback onTap;

  const MarketplaceListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: listing.isFeatured 
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            width: listing.isFeatured ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: listing.imageUrls.isNotEmpty
                      ? Image.network(
                          listing.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Brand
                    Text(
                      listing.brand,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Price
                    Text(
                      listing.formattedPrice,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Condition and Location in one compact row
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: _getConditionColor(listing.condition),
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          listing.conditionText,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Featured badge
            if (listing.isFeatured)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8,
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

  Color _getConditionColor(MarketplaceCondition condition) {
    switch (condition) {
      case MarketplaceCondition.new_:
        return Colors.green;
      case MarketplaceCondition.excellent:
        return Colors.lightGreen;
      case MarketplaceCondition.good:
        return Colors.yellow;
      case MarketplaceCondition.fair:
        return Colors.orange;
      case MarketplaceCondition.poor:
        return Colors.red;
    }
  }
}
