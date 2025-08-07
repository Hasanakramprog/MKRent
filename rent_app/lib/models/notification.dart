import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  rentalRequest,
  rentalApproved,
  rentalRejected,
  rentalStarted,
  rentalExtended,
  rentalReturned,
  rentalOverdue,
  paymentDue,
  paymentReceived,
  general,
}

enum NotificationStatus {
  unread,
  read,
  archived,
}

class AppNotification {
  final String id;
  final String userId; // Recipient user ID
  final String fromUserId; // Sender user ID
  final String fromUserName; // Sender name for display
  final NotificationType type;
  final NotificationStatus status;
  final String title;
  final String message;
  final Map<String, dynamic> data; // Additional data (rental ID, product ID, etc.)
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    required this.type,
    required this.title,
    required this.message,
    this.status = NotificationStatus.unread,
    this.data = const {},
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.general,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => NotificationStatus.unread,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      readAt: map['readAt'] != null ? (map['readAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'type': type.toString(),
      'status': status.toString(),
      'title': title,
      'message': message,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? fromUserId,
    String? fromUserName,
    NotificationType? type,
    NotificationStatus? status,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Helper methods for notification display
  String get typeDisplayName {
    switch (type) {
      case NotificationType.rentalRequest:
        return 'Rental Request';
      case NotificationType.rentalApproved:
        return 'Request Approved';
      case NotificationType.rentalRejected:
        return 'Request Rejected';
      case NotificationType.rentalStarted:
        return 'Rental Started';
      case NotificationType.rentalExtended:
        return 'Rental Extended';
      case NotificationType.rentalReturned:
        return 'Item Returned';
      case NotificationType.rentalOverdue:
        return 'Rental Overdue';
      case NotificationType.paymentDue:
        return 'Payment Due';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.general:
        return 'Notification';
    }
  }

  bool get isUnread => status == NotificationStatus.unread;
  bool get isRead => status == NotificationStatus.read;
}