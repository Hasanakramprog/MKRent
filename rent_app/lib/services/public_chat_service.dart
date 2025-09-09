import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/public_chat_message.dart';
import '../services/google_auth_service.dart';

class PublicChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _publicChatCollection = 'public_chat';
  static const int _messagesPerPage = 50;

  // Send a message to the public chat room
  static Future<void> sendMessage({
    required String text,
  }) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      final messageDoc = _firestore.collection(_publicChatCollection).doc();
      
      final message = PublicChatMessage(
        id: messageDoc.id,
        senderId: currentUser.id,
        senderName: currentUser.name,
        text: text,
        timestamp: DateTime.now(),
      );
      
      await messageDoc.set(message.toMap());
      
    } catch (e) {
      print('Error sending public message: $e');
      rethrow;
    }
  }

  // Get public chat messages stream (real-time)
  static Stream<List<PublicChatMessage>> getMessagesStream({
    int limit = _messagesPerPage,
  }) {
    return _firestore
        .collection(_publicChatCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PublicChatMessage.fromMap(doc.data(), documentId: doc.id))
            .toList());
  }

  // Load more messages (pagination)
  static Future<List<PublicChatMessage>> loadMoreMessages({
    required DocumentSnapshot lastDocument,
    int limit = _messagesPerPage,
  }) async {
    try {
      final query = await _firestore
          .collection(_publicChatCollection)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();
      
      return query.docs
          .map((doc) => PublicChatMessage.fromMap(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      print('Error loading more public messages: $e');
      return [];
    }
  }

  // Delete a message (only by sender or admin)
  static Future<void> deleteMessage(String messageId) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      
      // Get the message to check ownership
      final messageDoc = await _firestore
          .collection(_publicChatCollection)
          .doc(messageId)
          .get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }
      
      final message = PublicChatMessage.fromMap(messageDoc.data()!);
      
      // Only allow deletion by sender or admin
      if (message.senderId != currentUser.id && !currentUser.isAdmin) {
        throw Exception('Not authorized to delete this message');
      }
      
      await _firestore
          .collection(_publicChatCollection)
          .doc(messageId)
          .update({
        'text': 'This message was deleted',
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {'deleted': true},
      });
      
    } catch (e) {
      print('Error deleting public message: $e');
      rethrow;
    }
  }

  // Edit a message (only by sender)
  static Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      
      // Get the message to check ownership
      final messageDoc = await _firestore
          .collection(_publicChatCollection)
          .doc(messageId)
          .get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }
      
      final message = PublicChatMessage.fromMap(messageDoc.data()!);
      
      // Only allow editing by sender
      if (message.senderId != currentUser.id) {
        throw Exception('Not authorized to edit this message');
      }
      
      await _firestore
          .collection(_publicChatCollection)
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });
      
    } catch (e) {
      print('Error editing public message: $e');
      rethrow;
    }
  }

  // Clean up old messages (for admin)
  static Future<void> cleanupOldMessages({
    int daysOld = 30,
    int batchSize = 100,
  }) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      
      if (!currentUser.isAdmin) {
        throw Exception('Only admins can clean up messages');
      }
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final oldMessages = await _firestore
          .collection(_publicChatCollection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(batchSize)
          .get();
      
      if (oldMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final messageDoc in oldMessages.docs) {
          batch.delete(messageDoc.reference);
        }
        await batch.commit();
      }
      
    } catch (e) {
      print('Error cleaning up old public messages: $e');
      rethrow;
    }
  }

  // Search messages in public chat
  static Future<List<PublicChatMessage>> searchMessages({
    required String query,
    int limit = 20,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic search that loads recent messages and filters locally
      final messages = await _firestore
          .collection(_publicChatCollection)
          .orderBy('timestamp', descending: true)
          .limit(200) // Search in recent 200 messages
          .get();
      
      return messages.docs
          .map((doc) => PublicChatMessage.fromMap(doc.data(), documentId: doc.id))
          .where((message) => message.text.toLowerCase().contains(query.toLowerCase()) ||
                             message.senderName.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();
    } catch (e) {
      print('Error searching public messages: $e');
      return [];
    }
  }

  // Get online users count (simplified implementation)
  static Stream<int> getOnlineUsersCountStream() {
    // This would require additional implementation to track online users
    // For now, return a simple stream
    return Stream.periodic(const Duration(seconds: 30), (count) => count % 10 + 1);
  }
}
