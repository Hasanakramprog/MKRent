import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final List<String> specifications;
  final double rating;
  final bool isAvailable;
  final String ownerId; // Store owner who added this product
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.tags,
    this.specifications = const [],
    this.rating = 0.0,
    this.isAvailable = true,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'specifications': specifications,
      'rating': rating,
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      specifications: List<String>.from(map['specifications'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      ownerId: map['ownerId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    List<String>? tags,
    double? rating,
    bool? isAvailable,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
