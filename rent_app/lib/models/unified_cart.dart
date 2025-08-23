import 'package:cloud_firestore/cloud_firestore.dart';

enum CartItemType { rental, purchase }

class UnifiedCartItem {
  final String productId;
  final String productName;
  final String productImageUrl;
  final CartItemType type;
  final int quantity;
  final double subtotal;
  
  // For rental items
  final double? dailyRate;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? totalDays;
  
  // For purchase items
  final double? unitPrice;

  UnifiedCartItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.type,
    required this.quantity,
    required this.subtotal,
    this.dailyRate,
    this.startDate,
    this.endDate,
    this.totalDays,
    this.unitPrice,
  });

  // Create rental cart item
  factory UnifiedCartItem.rental({
    required String productId,
    required String productName,
    required String productImageUrl,
    required double dailyRate,
    required int quantity,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
  }) {
    final subtotal = dailyRate * quantity * totalDays;
    return UnifiedCartItem(
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      type: CartItemType.rental,
      quantity: quantity,
      subtotal: subtotal,
      dailyRate: dailyRate,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
    );
  }

  // Create purchase cart item
  factory UnifiedCartItem.purchase({
    required String productId,
    required String productName,
    required String productImageUrl,
    required double unitPrice,
    required int quantity,
  }) {
    final subtotal = unitPrice * quantity;
    return UnifiedCartItem(
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      type: CartItemType.purchase,
      quantity: quantity,
      subtotal: subtotal,
      unitPrice: unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'type': type.toString(),
      'quantity': quantity,
      'subtotal': subtotal,
    };

    if (type == CartItemType.rental) {
      if (dailyRate != null) map['dailyRate'] = dailyRate!;
      if (startDate != null) map['startDate'] = Timestamp.fromDate(startDate!);
      if (endDate != null) map['endDate'] = Timestamp.fromDate(endDate!);
      if (totalDays != null) map['totalDays'] = totalDays!;
    } else {
      if (unitPrice != null) map['unitPrice'] = unitPrice!;
    }

    return map;
  }

  factory UnifiedCartItem.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String;
    final type = typeString.contains('rental') 
        ? CartItemType.rental 
        : CartItemType.purchase;

    return UnifiedCartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      type: type,
      quantity: map['quantity'] ?? 1,
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      dailyRate: map['dailyRate']?.toDouble(),
      startDate: map['startDate'] != null 
          ? (map['startDate'] as Timestamp).toDate() 
          : null,
      endDate: map['endDate'] != null 
          ? (map['endDate'] as Timestamp).toDate() 
          : null,
      totalDays: map['totalDays'],
      unitPrice: map['unitPrice']?.toDouble(),
    );
  }

  UnifiedCartItem copyWith({
    String? productId,
    String? productName,
    String? productImageUrl,
    CartItemType? type,
    int? quantity,
    double? subtotal,
    double? dailyRate,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    double? unitPrice,
  }) {
    return UnifiedCartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      dailyRate: dailyRate ?? this.dailyRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  String toString() {
    return 'UnifiedCartItem(id: $productId, name: $productName, type: $type, quantity: $quantity, subtotal: $subtotal)';
  }
}

class UnifiedCart {
  final String userId;
  final List<UnifiedCartItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UnifiedCart({
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate total amount
  static double calculateTotal(List<UnifiedCartItem> items) {
    return items.fold(0.0, (total, item) => total + item.subtotal);
  }

  // Get rental items only
  List<UnifiedCartItem> get rentalItems {
    return items.where((item) => item.type == CartItemType.rental).toList();
  }

  // Get purchase items only
  List<UnifiedCartItem> get purchaseItems {
    return items.where((item) => item.type == CartItemType.purchase).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UnifiedCart.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
        ?.map((itemMap) => UnifiedCartItem.fromMap(itemMap as Map<String, dynamic>))
        .toList() ?? [];

    return UnifiedCart(
      userId: map['userId'] ?? '',
      items: itemsList,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  UnifiedCart copyWith({
    String? userId,
    List<UnifiedCartItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnifiedCart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UnifiedCart(userId: $userId, items: ${items.length}, total: $totalAmount)';
  }
}
