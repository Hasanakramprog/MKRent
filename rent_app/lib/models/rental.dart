import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalStatus { pending, approved, rejected, active, completed, cancelled }

extension RentalStatusExtension on RentalStatus {
  String get displayName {
    switch (this) {
      case RentalStatus.pending:
        return 'Pending Approval';
      case RentalStatus.approved:
        return 'Approved';
      case RentalStatus.rejected:
        return 'Rejected';
      case RentalStatus.active:
        return 'Active Rental';
      case RentalStatus.completed:
        return 'Completed';
      case RentalStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (this) {
      case RentalStatus.pending:
        return const Color(0xFFFFD700); // Yellow
      case RentalStatus.approved:
        return Colors.green;
      case RentalStatus.rejected:
        return Colors.red;
      case RentalStatus.active:
        return Colors.blue;
      case RentalStatus.completed:
        return Colors.grey;
      case RentalStatus.cancelled:
        return Colors.orange;
    }
  }
}

class RentalRequest {
  final String id;
  final String productId;
  final String userId;
  final String productOwnerId; // ID of the store owner
  final int quantity;
  final int days;
  final String deliveryLocation;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final RentalStatus status;
  final DateTime requestDate;
  final String? storeResponse;
  final String? rejectionReason;
  final DateTime? updatedAt;

  RentalRequest({
    required this.id,
    required this.productId,
    required this.userId,
    required this.productOwnerId,
    required this.quantity,
    required this.days,
    required this.deliveryLocation,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = RentalStatus.pending,
    required this.requestDate,
    this.storeResponse,
    this.rejectionReason,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'productOwnerId': productOwnerId,
      'quantity': quantity,
      'days': days,
      'deliveryLocation': deliveryLocation,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'requestDate': Timestamp.fromDate(requestDate),
      'storeResponse': storeResponse,
      'rejectionReason': rejectionReason,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory RentalRequest.fromMap(Map<String, dynamic> map) {
    return RentalRequest(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      productOwnerId: map['productOwnerId'] ?? '',
      quantity: map['quantity'] ?? 1,
      days: map['days'] ?? 1,
      deliveryLocation: map['deliveryLocation'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: RentalStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => RentalStatus.pending,
      ),
      requestDate: (map['requestDate'] as Timestamp).toDate(),
      storeResponse: map['storeResponse'],
      rejectionReason: map['rejectionReason'],
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  RentalRequest copyWith({
    RentalStatus? status,
    String? storeResponse,
    String? rejectionReason,
    DateTime? updatedAt,
  }) {
    return RentalRequest(
      id: id,
      productId: productId,
      userId: userId,
      productOwnerId: productOwnerId,
      quantity: quantity,
      days: days,
      deliveryLocation: deliveryLocation,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      status: status ?? this.status,
      requestDate: requestDate,
      storeResponse: storeResponse ?? this.storeResponse,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Legacy data manager for backward compatibility
class RentalData {
  static List<RentalRequest> _rentalRequests = [];

  static List<RentalRequest> getAllRentals() {
    return _rentalRequests;
  }

  static void addRental(RentalRequest rental) {
    _rentalRequests.add(rental);
  }

  static void updateRental(RentalRequest updatedRental) {
    final index = _rentalRequests.indexWhere((r) => r.id == updatedRental.id);
    if (index != -1) {
      _rentalRequests[index] = updatedRental;
    }
  }

  static List<RentalRequest> getRentalsByUser(String userId) {
    return _rentalRequests.where((rental) => rental.userId == userId).toList();
  }

  static List<RentalRequest> getRentalsByStore(String storeId) {
    return _rentalRequests.where((rental) => rental.productOwnerId == storeId).toList();
  }

  static List<RentalRequest> getPendingRentals(String storeId) {
    return _rentalRequests
        .where((rental) => 
            rental.productOwnerId == storeId && 
            rental.status == RentalStatus.pending)
        .toList();
  }

  static RentalRequest? getRentalById(String id) {
    try {
      return _rentalRequests.firstWhere((rental) => rental.id == id);
    } catch (e) {
      return null;
    }
  }
}
