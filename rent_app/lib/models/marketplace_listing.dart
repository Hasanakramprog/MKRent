import 'package:cloud_firestore/cloud_firestore.dart';

enum MarketplaceCondition { new_, excellent, good, fair, poor }

class MarketplaceListing {
  final String id;
  final String title;
  final String description;
  final String brand;
  final double price;
  final List<String> imageUrls;
  final String category;
  final List<String> tags;
  final MarketplaceCondition condition;
  final String location;
  final String contactPhone;
  final String contactEmail;
  final bool isNegotiable;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final bool isAvailable;
  final bool isFeatured;
  final int viewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? boostedUntil;

  MarketplaceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.brand,
    required this.price,
    required this.imageUrls,
    required this.category,
    this.tags = const [],
    required this.condition,
    required this.location,
    required this.contactPhone,
    required this.contactEmail,
    this.isNegotiable = false,
    required this.sellerId,
    required this.sellerName,
    this.sellerRating = 0.0,
    this.isAvailable = true,
    this.isFeatured = false,
    this.viewCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.boostedUntil,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'brand': brand,
      'price': price,
      'imageUrls': imageUrls,
      'category': category,
      'tags': tags,
      'condition': condition.toString(),
      'location': location,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'isNegotiable': isNegotiable,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRating': sellerRating,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'boostedUntil': boostedUntil != null ? Timestamp.fromDate(boostedUntil!) : null,
    };
  }

  // Create from Firestore Map
  factory MarketplaceListing.fromMap(Map<String, dynamic> map) {
    return MarketplaceListing(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      condition: MarketplaceCondition.values.firstWhere(
        (e) => e.toString() == map['condition'],
        orElse: () => MarketplaceCondition.good,
      ),
      location: map['location'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      isNegotiable: map['isNegotiable'] ?? false,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerRating: (map['sellerRating'] ?? 0.0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      viewCount: map['viewCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      boostedUntil: (map['boostedUntil'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method for updates
  MarketplaceListing copyWith({
    String? id,
    String? title,
    String? description,
    String? brand,
    double? price,
    List<String>? imageUrls,
    String? category,
    List<String>? tags,
    MarketplaceCondition? condition,
    String? location,
    String? contactPhone,
    String? contactEmail,
    bool? isNegotiable,
    String? sellerId,
    String? sellerName,
    double? sellerRating,
    bool? isAvailable,
    bool? isFeatured,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? boostedUntil,
  }) {
    return MarketplaceListing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRating: sellerRating ?? this.sellerRating,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      boostedUntil: boostedUntil ?? this.boostedUntil,
    );
  }

  // Helper methods
  String get formattedPrice {
    return '\$${price.toStringAsFixed(0)}';
  }

  String get conditionText {
    switch (condition) {
      case MarketplaceCondition.new_:
        return 'New';
      case MarketplaceCondition.excellent:
        return 'Excellent';
      case MarketplaceCondition.good:
        return 'Good';
      case MarketplaceCondition.fair:
        return 'Fair';
      case MarketplaceCondition.poor:
        return 'Poor';
    }
  }
}
