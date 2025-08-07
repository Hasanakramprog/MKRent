import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String productName;
  final String productImageUrl;
  final double dailyRate;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double subtotal;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.dailyRate,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.subtotal,
  });

  // Calculate subtotal
  static double calculateSubtotal(double dailyRate, int quantity, int days) {
    return dailyRate * quantity * days;
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'dailyRate': dailyRate,
      'quantity': quantity,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalDays': totalDays,
      'subtotal': subtotal,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      dailyRate: (map['dailyRate'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      totalDays: map['totalDays'] ?? 1,
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
    );
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    String? productImageUrl,
    double? dailyRate,
    int? quantity,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    double? subtotal,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      dailyRate: dailyRate ?? this.dailyRate,
      quantity: quantity ?? this.quantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

class Cart {
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate total amount
  static double calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (total, item) => total + item.subtotal);
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

  factory Cart.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
        ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [];

    return Cart(
      userId: map['userId'] ?? '',
      items: itemsList,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Cart copyWith({
    String? userId,
    List<CartItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;
  int get totalQuantity => items.fold(0, (total, item) => total + item.quantity);
}

class BulkRentalRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<CartItem> items;
  final double originalTotal;
  final double? adminAdjustedTotal; // Admin can modify the price
  final String status; // 'pending', 'approved', 'rejected', 'price_adjusted'
  final String? adminNotes;
  final DateTime requestDate;
  final DateTime? responseDate;
  final String? adminId;

  BulkRentalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.items,
    required this.originalTotal,
    this.adminAdjustedTotal,
    required this.status,
    this.adminNotes,
    required this.requestDate,
    this.responseDate,
    this.adminId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'originalTotal': originalTotal,
      'adminAdjustedTotal': adminAdjustedTotal,
      'status': status,
      'adminNotes': adminNotes,
      'requestDate': Timestamp.fromDate(requestDate),
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'adminId': adminId,
    };
  }

  factory BulkRentalRequest.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
        ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [];

    return BulkRentalRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      items: itemsList,
      originalTotal: (map['originalTotal'] ?? 0.0).toDouble(),
      adminAdjustedTotal: map['adminAdjustedTotal']?.toDouble(),
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
      requestDate: (map['requestDate'] as Timestamp).toDate(),
      responseDate: map['responseDate'] != null 
          ? (map['responseDate'] as Timestamp).toDate() 
          : null,
      adminId: map['adminId'],
    );
  }

  BulkRentalRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    List<CartItem>? items,
    double? originalTotal,
    double? adminAdjustedTotal,
    String? status,
    String? adminNotes,
    DateTime? requestDate,
    DateTime? responseDate,
    String? adminId,
  }) {
    return BulkRentalRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      items: items ?? this.items,
      originalTotal: originalTotal ?? this.originalTotal,
      adminAdjustedTotal: adminAdjustedTotal ?? this.adminAdjustedTotal,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      requestDate: requestDate ?? this.requestDate,
      responseDate: responseDate ?? this.responseDate,
      adminId: adminId ?? this.adminId,
    );
  }

  double get finalTotal => adminAdjustedTotal ?? originalTotal;
  int get totalItems => items.length;
  int get totalQuantity => items.fold(0, (total, item) => total + item.quantity);
  bool get isPriceAdjusted => adminAdjustedTotal != null && adminAdjustedTotal != originalTotal;
}
