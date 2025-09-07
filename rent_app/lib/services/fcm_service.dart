import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_auth_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Initialize FCM
  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else {
        debugPrint('User declined notification permission');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _updateUserFCMToken();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Handle app launched from terminated state via notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM Service: $e');
    }
  }

  // Initialize local notifications for Android
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Update user's FCM token in Firestore
  static Future<void> _updateUserFCMToken() async {
    try {
      final currentUser = GoogleAuthService.currentUser;
      if (currentUser == null) return;

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.id)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token updated: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Handle token refresh
  static Future<void> _onTokenRefresh(String token) async {
    debugPrint('FCM token refreshed');
    await _updateUserFCMToken();
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // Don't show local notification when app is in foreground
    // The UI will handle the message display through real-time streams
    // Only handle the data for navigation or other actions if needed
    final chatId = message.data['chatId'];
    if (chatId != null) {
      debugPrint('Foreground message for chat: $chatId');
      // The chat screens will automatically update via Firestore streams
      // No need to show a notification since user is actively using the app
    }
  }

  // Handle notification tap (from background)
  static void _handleMessageTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    
    final chatId = message.data['chatId'];
    if (chatId != null) {
      // TODO: Navigate to chat screen
      // This would typically be handled in main.dart with a global navigator
      debugPrint('Should navigate to chat: $chatId');
    }
  }

  // Handle local notification tap
  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped');
    
    final chatId = response.payload;
    if (chatId != null) {
      // TODO: Navigate to chat screen
      debugPrint('Should navigate to chat: $chatId');
    }
  }

  // Send a push notification to a specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String chatId,
    String? messageId, // Add messageId for duplicate prevention
    Map<String, String>? additionalData,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('User document not found: $userId');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('No FCM token found for user: $userId');
        return;
      }

      // Check for duplicate notifications if messageId is provided
      if (messageId != null) {
        final existingNotification = await FirebaseFirestore.instance
            .collection('notification_queue')
            .where('data.messageId', isEqualTo: messageId)
            .where('to', isEqualTo: fcmToken)
            .limit(1)
            .get();

        if (existingNotification.docs.isNotEmpty) {
          debugPrint('Duplicate notification prevented for message: $messageId');
          return;
        }
      }

      // Prepare notification data
      final data = {
        'chatId': chatId,
        'type': 'chat_message',
        if (messageId != null) 'messageId': messageId,
        ...?additionalData,
      };

      // Send notification via Cloud Function (recommended approach)
      // In a production app, you would call a Cloud Function here
      // For now, we'll store the notification request in Firestore
      // and let a Cloud Function handle the actual sending
      
      await FirebaseFirestore.instance
          .collection('notification_queue')
          .add({
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
        'created_at': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Notification queued for user: $userId');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Send notification when a new message is received
  static Future<void> sendNewMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
    required String messageId, // Make messageId required for duplicate prevention
    String? productTitle,
  }) async {
    final title = productTitle != null 
        ? 'New message about $productTitle'
        : 'New message from $senderName';
    
    final body = messageText.length > 100 
        ? '${messageText.substring(0, 100)}...'
        : messageText;

    await sendNotificationToUser(
      userId: receiverId,
      title: title,
      body: body,
      chatId: chatId,
      messageId: messageId, // Pass messageId for duplicate prevention
      additionalData: {
        'senderName': senderName,
        if (productTitle != null) 'productTitle': productTitle,
      },
    );
  }

  // Clear user's FCM token (on logout)
  static Future<void> clearUserToken() async {
    try {
      final currentUser = GoogleAuthService.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({
        'fcmToken': FieldValue.delete(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      
      debugPrint('FCM token cleared for user');
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic (for broadcast messages)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }
}
