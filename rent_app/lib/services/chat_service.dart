import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/marketplace_listing.dart';
import '../services/google_auth_service.dart';
import '../services/fcm_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';
  static const int _messagesPerPage = 20;

  // Create or get existing chat between two users for a specific product
  static Future<String> createOrGetProductChat({
    required String otherUserId,
    required String otherUserName,
    required MarketplaceListing product,
  }) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      final participantIds = [currentUser.id, otherUserId]..sort();
      
      // Create a unique chat ID for this product conversation
      final chatId = '${participantIds.join('_')}_${product.id}';
      
      final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create new chat
        final chat = Chat(
          id: chatId,
          participantIds: participantIds,
          participantNames: {
            currentUser.id: currentUser.name,
            otherUserId: otherUserName,
          },
          lastReadTimestamp: {
            currentUser.id: DateTime.now(),
            otherUserId: DateTime.now(),
          },
          productId: product.id,
          productTitle: product.title,
          productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _firestore.collection(_chatsCollection).doc(chatId).set(chat.toMap());
      }
      
      return chatId;
    } catch (e) {
      print('Error creating/getting product chat: $e');
      rethrow;
    }
  }

  // Create or get existing direct chat between two users (not product specific)
  static Future<String> createOrGetDirectChat({
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      final participantIds = [currentUser.id, otherUserId]..sort();
      
      // Look for existing direct chat (no product)
      final existingChat = await _firestore
          .collection(_chatsCollection)
          .where('participantIds', isEqualTo: participantIds)
          .where('productId', isNull: true)
          .limit(1)
          .get();
      
      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }
      
      // Create new direct chat
      final chatDoc = _firestore.collection(_chatsCollection).doc();
      final chat = Chat(
        id: chatDoc.id,
        participantIds: participantIds,
        participantNames: {
          currentUser.id: currentUser.name,
          otherUserId: otherUserName,
        },
        lastReadTimestamp: {
          currentUser.id: DateTime.now(),
          otherUserId: DateTime.now(),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await chatDoc.set(chat.toMap());
      return chatDoc.id;
    } catch (e) {
      print('Error creating/getting direct chat: $e');
      rethrow;
    }
  }

  // Send a text message
  static Future<void> sendMessage({
    required String chatId,
    required String text,
    required String receiverId,
  }) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      final messageDoc = _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc();
      
      final message = Message(
        id: messageDoc.id,
        chatId: chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        receiverId: receiverId,
        text: text,
        timestamp: DateTime.now(),
      );
      
      // Use a batch to update both message and chat
      final batch = _firestore.batch();
      
      // Add message
      batch.set(messageDoc, message.toMap());
      
      // Update chat with last message info
      batch.update(_firestore.collection(_chatsCollection).doc(chatId), {
        'lastMessage': text,
        'lastTimestamp': Timestamp.fromDate(message.timestamp),
        'lastSenderId': currentUser.id,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      await batch.commit();
      
      // Send FCM notification
      await _sendFCMNotification(chatId, receiverId, currentUser.name, text, messageDoc.id);
      
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send a product sharing message
  static Future<void> sendProductMessage({
    required String chatId,
    required String receiverId,
    required MarketplaceListing product,
  }) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      final messageDoc = _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc();
      
      final message = Message.productShare(
        chatId: chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        receiverId: receiverId,
        productId: product.id,
        productTitle: product.title,
        productPrice: '\$${product.price}',
        productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      ).copyWith(id: messageDoc.id);
      
      // Use a batch to update both message and chat
      final batch = _firestore.batch();
      
      // Add message
      batch.set(messageDoc, message.toMap());
      
      // Update chat with last message info
      batch.update(_firestore.collection(_chatsCollection).doc(chatId), {
        'lastMessage': message.text,
        'lastTimestamp': Timestamp.fromDate(message.timestamp),
        'lastSenderId': currentUser.id,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      await batch.commit();
      
      // Send FCM notification for product share
      await _sendFCMNotification(chatId, receiverId, currentUser.name, message.text, messageDoc.id);
      
    } catch (e) {
      print('Error sending product message: $e');
      rethrow;
    }
  }

  // Get user's chats stream (real-time)
  static Stream<List<Chat>> getUserChatsStream() {
    final currentUser = GoogleAuthService.currentUser!;
    
    return _firestore
        .collection(_chatsCollection)
        .where('participantIds', arrayContains: currentUser.id)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromMap(doc.data(), documentId: doc.id))
            .toList());
  }

  // Get messages stream for a specific chat (real-time with pagination)
  static Stream<List<Message>> getMessagesStream({
    required String chatId,
    DocumentSnapshot? lastDocument,
    int limit = _messagesPerPage,
  }) {
    Query query = _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, documentId: doc.id))
        .toList());
  }

  // Load more messages (pagination)
  static Future<List<Message>> loadMoreMessages({
    required String chatId,
    required DocumentSnapshot lastDocument,
    int limit = _messagesPerPage,
  }) async {
    try {
      final query = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();
      
      return query.docs
          .map((doc) => Message.fromMap(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      print('Error loading more messages: $e');
      return [];
    }
  }

  // Mark chat as read for current user
  static Future<void> markChatAsRead(String chatId) async {
    try {
      final currentUser = GoogleAuthService.currentUser!;
      
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastReadTimestamp.${currentUser.id}': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  // Get specific chat
  static Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (doc.exists) {
        return Chat.fromMap(doc.data()!, documentId: doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }

  // Delete a message (soft delete - mark as deleted)
  static Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'text': 'This message was deleted',
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {'deleted': true},
      });
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Edit a message
  static Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    try {
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  // Get total unread count for current user
  static Stream<int> getUnreadCountStream() {
    final currentUser = GoogleAuthService.currentUser!;
    
    return getUserChatsStream().map((chats) {
      return chats.fold<int>(0, (total, chat) => total + chat.getUnreadCount(currentUser.id));
    });
  }

  // Search messages in a chat
  static Future<List<Message>> searchMessages({
    required String chatId,
    required String query,
    int limit = 20,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic search that loads recent messages and filters locally
      final messages = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(100) // Search in recent 100 messages
          .get();
      
      return messages.docs
          .map((doc) => Message.fromMap(doc.data(), documentId: doc.id))
          .where((message) => message.text.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  // Clean up old messages (optional - for maintenance)
  static Future<void> cleanupOldMessages({
    int daysOld = 90,
    int batchSize = 500,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // This would typically be done in a Cloud Function
      // Here's the basic logic for reference
      
      final chats = await _firestore.collection(_chatsCollection).get();
      
      for (final chatDoc in chats.docs) {
        final oldMessages = await chatDoc.reference
            .collection(_messagesCollection)
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
      }
    } catch (e) {
      print('Error cleaning up old messages: $e');
    }
  }

  // Private method to send FCM notification
  static Future<void> _sendFCMNotification(String chatId, String receiverId, String senderName, String message, String messageId) async {
    try {
      // Get chat information to determine if this is a product chat
      final chat = await getChat(chatId);
      final productTitle = chat?.productTitle;
      
      // Send FCM notification with product context
      await FCMService.sendNewMessageNotification(
        receiverId: receiverId,
        senderName: senderName,
        messageText: message,
        chatId: chatId,
        messageId: messageId, // Pass messageId for duplicate prevention
        productTitle: productTitle,
      );
    } catch (e) {
      print('Error sending FCM notification: $e');
      // Don't throw here - message was already sent successfully
    }
  }

  // Get chat participants (useful for group chats or admin features)
  static Future<List<String>> getChatParticipants(String chatId) async {
    try {
      final chat = await getChat(chatId);
      return chat?.participantIds ?? [];
    } catch (e) {
      print('Error getting chat participants: $e');
      return [];
    }
  }

  // Check if user can access chat
  static Future<bool> canUserAccessChat(String chatId, String userId) async {
    try {
      final participants = await getChatParticipants(chatId);
      return participants.contains(userId);
    } catch (e) {
      print('Error checking chat access: $e');
      return false;
    }
  }

  // Admin: Get all chats (for moderation)
  static Stream<List<Chat>> getAllChatsStream() {
    return _firestore
        .collection(_chatsCollection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromMap(doc.data(), documentId: doc.id))
            .toList());
  }
}
