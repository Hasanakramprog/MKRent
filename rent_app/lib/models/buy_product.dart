class BuyProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String brand;
  final double rating;
  final int reviewCount;
  final List<String> features;
  final Map<String, dynamic> specifications;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final int stockQuantity;
  final String condition; // new, used, refurbished
  final String warranty; // warranty information
  final List<String> additionalImages;

  BuyProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.brand,
    required this.rating,
    required this.reviewCount,
    required this.features,
    required this.specifications,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    required this.updatedAt,
    required this.isAvailable,
    required this.stockQuantity,
    required this.condition,
    required this.warranty,
    required this.additionalImages,
  });

  // Create BuyProduct from Firestore document
  factory BuyProduct.fromMap(Map<String, dynamic> map, String id) {
    return BuyProduct(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      features: List<String>.from(map['features'] ?? []),
      specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isAvailable: map['isAvailable'] ?? true,
      stockQuantity: map['stockQuantity'] ?? 0,
      condition: map['condition'] ?? 'new',
      warranty: map['warranty'] ?? '',
      additionalImages: List<String>.from(map['additionalImages'] ?? []),
    );
  }

  // Convert BuyProduct to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'brand': brand,
      'rating': rating,
      'reviewCount': reviewCount,
      'features': features,
      'specifications': specifications,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'condition': condition,
      'warranty': warranty,
      'additionalImages': additionalImages,
    };
  }

  // Create a copy with updated fields
  BuyProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? brand,
    double? rating,
    int? reviewCount,
    List<String>? features,
    Map<String, dynamic>? specifications,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    int? stockQuantity,
    String? condition,
    String? warranty,
    List<String>? additionalImages,
  }) {
    return BuyProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      features: features ?? this.features,
      specifications: specifications ?? this.specifications,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      condition: condition ?? this.condition,
      warranty: warranty ?? this.warranty,
      additionalImages: additionalImages ?? this.additionalImages,
    );
  }

  @override
  String toString() {
    return 'BuyProduct(id: $id, name: $name, price: $price, category: $category, condition: $condition, stock: $stockQuantity)';
  }
}
