import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, admin }

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? email;
  final String? storeId;
  final String? storeName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.storeId,
    this.storeName,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isCustomer => role == UserRole.customer;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'email': email,
      'storeId': storeId,
      'storeName': storeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == map['role'],
        orElse: () => UserRole.customer,
      ),
      email: map['email'],
      storeId: map['storeId'],
      storeName: map['storeName'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  AppUser copyWith({
    String? name,
    String? phone,
    UserRole? role,
    String? email,
    String? storeId,
    String? storeName,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      email: email ?? this.email,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
