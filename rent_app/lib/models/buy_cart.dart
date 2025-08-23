class BuyCart {
  final String userId;
  final List<BuyCartItem> items;
  final double total;
  final int itemCount;
  final DateTime updatedAt;

  BuyCart({
    required this.userId,
    required this.items,
    required this.total,
    required this.itemCount,
    required this.updatedAt,
  });

  factory BuyCart.fromMap(Map<String, dynamic> map) {
    return BuyCart(
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => BuyCartItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (map['total'] ?? 0).toDouble(),
      itemCount: map['itemCount'] ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'itemCount': itemCount,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  BuyCart copyWith({
    String? userId,
    List<BuyCartItem>? items,
    double? total,
    int? itemCount,
    DateTime? updatedAt,
  }) {
    return BuyCart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BuyCartItem {
  final String productId;
  final String productName;
  final String productImageUrl;
  final double price;
  final int quantity;
  final String condition;
  final double subtotal;
  final DateTime addedAt;

  BuyCartItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.price,
    required this.quantity,
    required this.condition,
    required this.subtotal,
    required this.addedAt,
  });

  factory BuyCartItem.fromMap(Map<String, dynamic> map) {
    return BuyCartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      condition: map['condition'] ?? '',
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'price': price,
      'quantity': quantity,
      'condition': condition,
      'subtotal': subtotal,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  BuyCartItem copyWith({
    String? productId,
    String? productName,
    String? productImageUrl,
    double? price,
    int? quantity,
    String? condition,
    double? subtotal,
    DateTime? addedAt,
  }) {
    return BuyCartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      subtotal: subtotal ?? this.subtotal,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'BuyCartItem(productId: $productId, productName: $productName, quantity: $quantity, price: $price, condition: $condition, subtotal: $subtotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuyCartItem &&
        other.productId == productId &&
        other.condition == condition;
  }

  @override
  int get hashCode {
    return productId.hashCode ^ condition.hashCode;
  }
}
