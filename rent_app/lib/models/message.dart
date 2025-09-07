import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  product, // For sharing product details
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isEdited;
  final DateTime? editedAt;
  final Map<String, dynamic>? metadata; // For extra data like image URLs, product info

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.isEdited = false,
    this.editedAt,
    this.metadata,
  });

  // Check if message contains product information
  bool get isProductMessage => type == MessageType.product;

  // Check if message contains image
  bool get isImageMessage => type == MessageType.image;

  // Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  // Get detailed formatted timestamp
  String get detailedFormattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory Message.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Message(
      id: documentId ?? map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] is Timestamp
          ? (map['editedAt'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  // Create a copy with updated fields
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    bool? isEdited,
    DateTime? editedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Create a product sharing message
  factory Message.productShare({
    required String chatId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String productId,
    required String productTitle,
    required String productPrice,
    String? productImageUrl,
  }) {
    return Message(
      id: '', // Will be set when saving to Firestore
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      text: 'Shared a product: $productTitle',
      type: MessageType.product,
      timestamp: DateTime.now(),
      metadata: {
        'productId': productId,
        'productTitle': productTitle,
        'productPrice': productPrice,
        'productImageUrl': productImageUrl,
      },
    );
  }

  // Create an image message
  factory Message.image({
    required String chatId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String imageUrl,
    String caption = '',
  }) {
    return Message(
      id: '', // Will be set when saving to Firestore
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      text: caption.isNotEmpty ? caption : 'Sent an image',
      type: MessageType.image,
      timestamp: DateTime.now(),
      metadata: {
        'imageUrl': imageUrl,
        'caption': caption,
      },
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, text: $text, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
