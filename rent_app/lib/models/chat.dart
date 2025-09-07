import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames; // userId -> userName
  final String? lastMessage;
  final DateTime? lastTimestamp;
  final String? lastSenderId;
  final Map<String, DateTime> lastReadTimestamp; // userId -> timestamp
  final String? productId; // For marketplace product discussions
  final String? productTitle;
  final String? productImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    this.lastTimestamp,
    this.lastSenderId,
    required this.lastReadTimestamp,
    this.productId,
    this.productTitle,
    this.productImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get unread message count for a specific user
  int getUnreadCount(String userId) {
    if (lastTimestamp == null || lastSenderId == userId) return 0;
    
    final userLastRead = lastReadTimestamp[userId];
    if (userLastRead == null) return 1;
    
    return lastTimestamp!.isAfter(userLastRead) ? 1 : 0;
  }

  // Get the other participant's name (for 1-on-1 chats)
  String getOtherParticipantName(String currentUserId) {
    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantNames[otherUserId] ?? 'Unknown User';
  }

  // Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp != null ? Timestamp.fromDate(lastTimestamp!) : null,
      'lastSenderId': lastSenderId,
      'lastReadTimestamp': lastReadTimestamp.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory Chat.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Chat(
      id: documentId ?? map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'],
      lastTimestamp: map['lastTimestamp'] is Timestamp
          ? (map['lastTimestamp'] as Timestamp).toDate()
          : null,
      lastSenderId: map['lastSenderId'],
      lastReadTimestamp: (map['lastReadTimestamp'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key, 
          value is Timestamp ? value.toDate() : DateTime.now(),
        ),
      ) ?? {},
      productId: map['productId'],
      productTitle: map['productTitle'],
      productImageUrl: map['productImageUrl'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create a copy with updated fields
  Chat copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    String? lastMessage,
    DateTime? lastTimestamp,
    String? lastSenderId,
    Map<String, DateTime>? lastReadTimestamp,
    String? productId,
    String? productTitle,
    String? productImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastReadTimestamp: lastReadTimestamp ?? this.lastReadTimestamp,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, participants: $participantIds, lastMessage: $lastMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
