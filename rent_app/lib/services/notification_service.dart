import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../models/rental.dart';
import '../models/product.dart';
import '../services/google_auth_service.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
  print('Background message data: ${message.data}');
  
  // Show local notification when app is in background
  await NotificationService._showLocalNotification(message);
}

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Track sent notifications to prevent duplicates
  static final Set<String> _sentNotificationIds = <String>{};
  static const int _deduplicationWindowMinutes = 5; // 5 minute window for deduplication

  // Generate unique notification ID for deduplication
  static String _generateNotificationId({
    required String toUserId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    // Create a unique ID based on content and recipient
    final contentHash = '$toUserId:${type.toString()}:$title:$message:${data?.toString() ?? ''}';
    return contentHash.hashCode.toString();
  }

  // Check if notification was recently sent (deduplication)
  static bool _isRecentlySent(String notificationId) {
    return _sentNotificationIds.contains(notificationId);
  }

  // Mark notification as sent with expiration
  static void _markAsSent(String notificationId) {
    _sentNotificationIds.add(notificationId);
    
    // Clean up old notification IDs after the deduplication window
    Timer(Duration(minutes: _deduplicationWindowMinutes), () {
      _sentNotificationIds.remove(notificationId);
    });
  }
  static Future<void> initialize() async {
    try {
      print('Initializing NotificationService...');
      
      // Check if Firebase Messaging is available (Google Play Services check)
      bool isSupported = await _messaging.isSupported();
      if (!isSupported) {
        print('Firebase Messaging is not supported on this device');
        return;
      }
      print('Firebase Messaging is supported');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      // Check if permission was granted
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('Notification permissions granted');
      } else {
        print('Notification permissions denied: ${settings.authorizationStatus}');
      }

      // Get FCM token for this device - with retry mechanism for real devices
      String? token;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (token == null && retryCount < maxRetries) {
        try {
          token = await _messaging.getToken();
          if (token != null) {
            print('FCM Token obtained: $token');
            break;
          } else {
            retryCount++;
            print('FCM Token is null, retrying... ($retryCount/$maxRetries)');
            if (retryCount < maxRetries) {
              await Future.delayed(Duration(seconds: retryCount * 2)); // Progressive delay
            }
          }
        } catch (e) {
          retryCount++;
          print('Error getting FCM token (attempt $retryCount): $e');
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      if (token == null) {
        print('Failed to obtain FCM token after $maxRetries attempts');
      }

      // Save token to user document if logged in
      if (GoogleAuthService.isLoggedIn && token != null) {
        await _saveFCMToken(token);
      }

      // Handle token refresh - this ensures tokens stay fresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        // Always save the new token regardless of current auth state
        // because the token refresh might happen when user is logged in later
        if (GoogleAuthService.isLoggedIn) {
          await _saveFCMToken(newToken);
        } else {
          // Store token temporarily for when user logs in
          await _storeTemporaryToken(newToken);
        }
      });

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen to messages when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from terminated state via notification: ${initialMessage.data}');
        _handleBackgroundMessage(initialMessage);
      }

      print('Notification service initialized');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Manually refresh FCM token - useful for real devices
  static Future<String?> refreshFCMToken() async {
    try {
      print('Manually refreshing FCM token...');
      
      // Check if messaging is supported
      bool isSupported = await _messaging.isSupported();
      if (!isSupported) {
        print('Firebase Messaging not supported');
        return null;
      }
      
      // Delete current token to force refresh
      await _messaging.deleteToken();
      print('Deleted current FCM token');
      
      // Wait a moment for cleanup
      await Future.delayed(const Duration(seconds: 2));
      
      // Get new token
      String? newToken = await _messaging.getToken();
      if (newToken != null) {
        print('New FCM token generated: $newToken');
        
        // Save if user is logged in
        if (GoogleAuthService.isLoggedIn) {
          await _saveFCMToken(newToken);
        } else {
          await _storeTemporaryToken(newToken);
        }
        
        return newToken;
      } else {
        print('Failed to generate new FCM token');
        return null;
      }
    } catch (e) {
      print('Error refreshing FCM token: $e');
      return null;
    }
  }

  // Check and refresh token for long-term logged-in users
  static Future<void> validateTokenForLongTermUser() async {
    try {
      if (!GoogleAuthService.isLoggedIn) return;
      
      print('Validating FCM token for long-term user...');
      
      // Check if messaging is supported
      bool isSupported = await _messaging.isSupported();
      if (!isSupported) {
        print('Firebase Messaging not supported');
        return;
      }
      
      // Get user document to check token age
      final userDoc = await _firestore.collection('users').doc(GoogleAuthService.userId).get();
      if (!userDoc.exists) return;
      
      final data = userDoc.data();
      final tokenUpdatedAt = data?['tokenUpdatedAt'] as Timestamp?;
      final currentToken = data?['fcmToken'] as String?;
      
      if (tokenUpdatedAt != null) {
        final daysSinceUpdate = DateTime.now().difference(tokenUpdatedAt.toDate()).inDays;
        print('FCM token was last updated $daysSinceUpdate days ago');
        
        // Refresh token if it's older than 7 days
        if (daysSinceUpdate >= 7) {
          print('Token is stale (${daysSinceUpdate} days), refreshing...');
          await refreshFCMToken();
        } else if (daysSinceUpdate >= 3) {
          // For tokens 3-6 days old, verify they still work
          print('Token is aging (${daysSinceUpdate} days), verifying...');
          final freshToken = await _messaging.getToken();
          if (freshToken != null && freshToken != currentToken) {
            print('Token has changed, updating...');
            await _saveFCMToken(freshToken);
          }
        }
      } else {
        // No timestamp, likely old user - refresh token
        print('No token timestamp found, refreshing for safety...');
        await refreshFCMToken();
      }
    } catch (e) {
      print('Error validating token for long-term user: $e');
    }
  }

  // Save FCM token to user document
  static Future<void> _saveFCMToken(String token) async {
    try {
      if (GoogleAuthService.userId != null) {
        print('Saving FCM token for user: ${GoogleAuthService.userId}');
        
        // First try to update
        await _firestore
            .collection('users')
            .doc(GoogleAuthService.userId)
            .update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
          'fcmTokenActive': true, // Mark as active
        });
        
        print('FCM token saved successfully for user: ${GoogleAuthService.userId}');
        
        // Clear any temporary token since we've saved the real one
        await _clearTemporaryToken();
      } else {
        print('Cannot save FCM token: user not logged in');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
      // If update fails, try to create/merge the field
      if (e.toString().contains('No document to update') || 
          e.toString().contains('not found')) {
        try {
          print('Document not found, creating with merge...');
          await _firestore
              .collection('users')
              .doc(GoogleAuthService.userId)
              .set({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
            'lastActiveAt': FieldValue.serverTimestamp(),
            'fcmTokenActive': true,
          }, SetOptions(merge: true));
          print('FCM token created successfully for user: ${GoogleAuthService.userId}');
        } catch (createError) {
          print('Error creating FCM token field: $createError');
        }
      }
    }
  }

  // Store token temporarily when user is not logged in
  static Future<void> _storeTemporaryToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_fcm_token', token);
      await prefs.setInt('token_timestamp', DateTime.now().millisecondsSinceEpoch);
      print('Temporary FCM token stored');
    } catch (e) {
      print('Error storing temporary token: $e');
    }
  }

  // Clear temporary token
  static Future<void> _clearTemporaryToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_fcm_token');
      await prefs.remove('token_timestamp');
    } catch (e) {
      print('Error clearing temporary token: $e');
    }
  }

  // Handle user login - save any pending token
  static Future<void> onUserLogin() async {
    try {
      print('Handling user login for FCM token...');
      
      // Check if messaging is supported
      bool isSupported = await _messaging.isSupported();
      if (!isSupported) {
        print('Firebase Messaging not supported, skipping FCM token handling');
        return;
      }
      
      // Get current token with retry mechanism
      String? currentToken;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (currentToken == null && retryCount < maxRetries) {
        try {
          currentToken = await _messaging.getToken();
          if (currentToken != null) {
            print('Current FCM token obtained for logged-in user: $currentToken');
            await _saveFCMToken(currentToken);
            break;
          } else {
            retryCount++;
            print('Current FCM token is null, retrying... ($retryCount/$maxRetries)');
            if (retryCount < maxRetries) {
              await Future.delayed(Duration(seconds: retryCount * 2));
            }
          }
        } catch (e) {
          retryCount++;
          print('Error getting current FCM token (attempt $retryCount): $e');
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      // Check for any pending token
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString('pending_fcm_token');
      final tokenTimestamp = prefs.getInt('token_timestamp');
      
      if (pendingToken != null && tokenTimestamp != null) {
        // Check if token is still fresh (less than 24 hours old)
        final tokenAge = DateTime.now().millisecondsSinceEpoch - tokenTimestamp;
        const maxAge = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
        
        if (tokenAge < maxAge) {
          await _saveFCMToken(pendingToken);
          print('Saved pending FCM token after login: $pendingToken');
        } else {
          print('Pending token expired, using current token');
        }
        
        await _clearTemporaryToken();
      }
      
      // Set up periodic token validation for long-term users
      await _setupPeriodicTokenValidation();
      
      if (currentToken == null) {
        print('Warning: No FCM token available after login');
      }
    } catch (e) {
      print('Error handling user login token: $e');
    }
  }

  // Set up periodic token validation for long-term logged-in users
  static Future<void> _setupPeriodicTokenValidation() async {
    try {
      // Check when token was last updated
      if (GoogleAuthService.userId != null) {
        final userDoc = await _firestore.collection('users').doc(GoogleAuthService.userId).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final tokenUpdatedAt = data?['tokenUpdatedAt'] as Timestamp?;
          
          if (tokenUpdatedAt != null) {
            final daysSinceUpdate = DateTime.now().difference(tokenUpdatedAt.toDate()).inDays;
            
            // If token is older than 5 days, proactively refresh
            if (daysSinceUpdate >= 5) {
              print('Token is $daysSinceUpdate days old, proactively refreshing...');
              await refreshFCMToken();
            } else {
              print('Token is $daysSinceUpdate days old, still fresh');
            }
          }
        }
      }
    } catch (e) {
      print('Error in periodic token validation: $e');
    }
  }

  // Handle user logout - clean up token
  static Future<void> onUserLogout() async {
    try {
      if (GoogleAuthService.userId != null) {
        // Mark token as inactive instead of deleting
        await _firestore
            .collection('users')
            .doc(GoogleAuthService.userId)
            .update({
          'fcmTokenActive': false,
          'lastLogoutAt': FieldValue.serverTimestamp(),
        });
        print('FCM token marked as inactive for logged out user');
      }
    } catch (e) {
      print('Error handling user logout: $e');
    }
  }

  // Refresh token manually if needed
  static Future<void> refreshToken() async {
    try {
      // Delete current token to force refresh
      await _messaging.deleteToken();
      
      // Get new token
      final newToken = await _messaging.getToken();
      if (newToken != null) {
        print('Manual token refresh: $newToken');
        if (GoogleAuthService.isLoggedIn) {
          await _saveFCMToken(newToken);
        } else {
          await _storeTemporaryToken(newToken);
        }
      }
    } catch (e) {
      print('Error refreshing token manually: $e');
    }
  }

  // Handle app lifecycle changes
  static Future<void> onAppResumed() async {
    try {
      // Check if token needs refresh (older than 24 hours)
      if (GoogleAuthService.isLoggedIn) {
        final userDoc = await _firestore
            .collection('users')
            .doc(GoogleAuthService.userId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final tokenUpdatedAt = data['tokenUpdatedAt'] as Timestamp?;
          
          if (tokenUpdatedAt != null) {
            final hoursSinceUpdate = DateTime.now()
                .difference(tokenUpdatedAt.toDate())
                .inHours;
            
            // Refresh token if older than 20 hours
            if (hoursSinceUpdate > 20) {
              print('Token is $hoursSinceUpdate hours old, refreshing...');
              await refreshToken();
            }
          } else {
            // No timestamp, refresh token
            print('No token timestamp found, refreshing...');
            await refreshToken();
          }
        }
      }
    } catch (e) {
      print('Error handling app resume: $e');
    }
  }

  // Validate current token
  static Future<bool> isTokenValid() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return false;
      
      if (GoogleAuthService.isLoggedIn) {
        final userDoc = await _firestore
            .collection('users')
            .doc(GoogleAuthService.userId)
            .get();
        
        if (userDoc.exists) {
          final storedToken = userDoc.data()!['fcmToken'] as String?;
          return storedToken == token;
        }
      }
      
      return true; // For non-logged in users, assume token is valid if it exists
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    // Show local notification even when app is in foreground
    _showLocalNotification(message);
  }

  // Handle background messages
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Received background message: ${message.notification?.title}');
    // Show local notification when app is opened from background
    _showLocalNotification(message);
    // Handle navigation based on notification data
  }

  // Send notification to user
  static Future<void> sendNotification({
    required String toUserId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      // Generate unique notification ID for deduplication
      final notificationId = _generateNotificationId(
        toUserId: toUserId,
        type: type,
        title: title,
        message: message,
        data: data,
      );

      // Check if this notification was recently sent
      if (_isRecentlySent(notificationId)) {
        print('Duplicate notification prevented: $title to $toUserId');
        return;
      }

      // Mark as sent to prevent duplicates
      _markAsSent(notificationId);

      print('Sending notification to: $toUserId');
      print('Type: ${type.toString()}');
      print('Title: $title');
      print('Message: $message');

      final notification = AppNotification(
        id: _firestore.collection('notifications').doc().id,
        userId: toUserId,
        fromUserId: GoogleAuthService.userId ?? '',
        fromUserName: GoogleAuthService.currentUser?.name ?? 'System',
        type: type,
        title: title,
        message: message,
        data: data,
        createdAt: DateTime.now(),
      );

      // Save notification to Firestore
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      print('Notification saved to Firestore for user: $toUserId');

      // Send push notification if user has FCM token
      await _sendPushNotification(toUserId, title, message, data);
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send push notification via FCM
  static Future<void> _sendPushNotification(
    String toUserId,
    String title,
    String message,
    Map<String, dynamic> data,
  ) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // Generate unique FCM notification ID to prevent duplicates
        final fcmNotificationId = 'fcm_${_generateNotificationId(
          toUserId: toUserId,
          type: NotificationType.general, // Use general type for FCM deduplication
          title: title,
          message: message,
          data: data,
        )}';

        // Check for recent FCM notifications to same user
        final recentFcmQuery = await _firestore
            .collection('fcm_notifications')
            .where('token', isEqualTo: fcmToken)
            .where('notification.title', isEqualTo: title)
            .where('notification.body', isEqualTo: message)
            .where('timestamp', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(Duration(minutes: _deduplicationWindowMinutes))
            ))
            .limit(1)
            .get();

        if (recentFcmQuery.docs.isNotEmpty) {
          print('Duplicate FCM notification prevented for user: $toUserId');
          return;
        }

        // Queue notification for Cloud Function to send
        await _firestore.collection('fcm_notifications').add({
          'id': fcmNotificationId,
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': message,
          },
          'data': data,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': toUserId, // Add userId for easier tracking
        });
        
        print('FCM notification queued for Cloud Function processing');
        print('Title: $title');
        print('Message: $message');
        print('User: $toUserId');
      } else {
        print('No FCM token found for user: $toUserId');
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Send rental request notification to admin
  static Future<void> sendRentalRequestNotification({
    required String adminId,
    required RentalRequest rental,
    required Product product,
  }) async {
    await sendNotification(
      toUserId: adminId,
      type: NotificationType.rentalRequest,
      title: 'New Rental Request',
      message: '${GoogleAuthService.currentUser?.name} wants to rent ${product.name}',
      data: {
        'rentalId': rental.id,
        'productId': product.id,
        'productName': product.name,
        'customerName': GoogleAuthService.currentUser?.name,
      },
    );
  }

  // Send rental approved notification to customer
  static Future<void> sendRentalApprovedNotification({
    required String customerId,
    required RentalRequest rental,
    required Product product,
  }) async {
    await sendNotification(
      toUserId: customerId,
      type: NotificationType.rentalApproved,
      title: 'Rental Request Approved!',
      message: 'Your rental request for ${product.name} has been approved',
      data: {
        'rentalId': rental.id,
        'productId': product.id,
        'productName': product.name,
      },
    );
  }

  // Send rental rejected notification to customer
  static Future<void> sendRentalRejectedNotification({
    required String customerId,
    required RentalRequest rental,
    required Product product,
    String? reason,
  }) async {
    final message = reason != null
        ? 'Your rental request for ${product.name} was rejected. Reason: $reason'
        : 'Your rental request for ${product.name} was rejected';

    await sendNotification(
      toUserId: customerId,
      type: NotificationType.rentalRejected,
      title: 'Rental Request Rejected',
      message: message,
      data: {
        'rentalId': rental.id,
        'productId': product.id,
        'productName': product.name,
        'reason': reason,
      },
    );
  }

  // Send rental started notification
  static Future<void> sendRentalStartedNotification({
    required String customerId,
    required RentalRequest rental,
    required Product product,
  }) async {
    await sendNotification(
      toUserId: customerId,
      type: NotificationType.rentalStarted,
      title: 'Rental Started',
      message: 'Your rental of ${product.name} has started. Enjoy!',
      data: {
        'rentalId': rental.id,
        'productId': product.id,
        'productName': product.name,
      },
    );
  }

  // Send rental return reminder
  static Future<void> sendReturnReminderNotification({
    required String customerId,
    required RentalRequest rental,
    required Product product,
    required int daysUntilReturn,
  }) async {
    final message = daysUntilReturn > 0
        ? 'Please return ${product.name} in $daysUntilReturn days'
        : 'Please return ${product.name} today';

    await sendNotification(
      toUserId: customerId,
      type: NotificationType.rentalOverdue,
      title: 'Return Reminder',
      message: message,
      data: {
        'rentalId': rental.id,
        'productId': product.id,
        'productName': product.name,
        'daysUntilReturn': daysUntilReturn,
      },
    );
  }

  // Send item returned notification to admin
  static Future<void> sendItemReturnedNotification({
    required String adminId,
    required RentalRequest rental,
    required Product product,
    required String customerName,
  }) async {
    await sendNotification(
      toUserId: adminId,
      type: NotificationType.rentalReturned,
      title: 'Item Returned',
      message: '$customerName has returned ${product.name}',
      data: {
        'rentalId': rental.id,
        'productId': product.id,
        'productName': product.name,
        'customerName': customerName,
      },
    );
  }

  // Get user notifications
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': NotificationStatus.read.toString(),
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.toString())
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.toString(),
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: NotificationStatus.unread.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions on Android 13+
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      print('Local notification permission granted: $granted');
    }

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rent_app_channel',
      'Rent App Notifications',
      description: 'Notifications for rental requests and updates',
      importance: Importance.high,
    );

    await android?.createNotificationChannel(channel);
    print('Local notifications initialized successfully');
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      print('Attempting to show local notification...');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'rent_app_channel',
        'Rent App Notifications',
        channelDescription: 'Notifications for rental requests and updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        color: Color(0xFFFFD700), // Yellow color
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final title = message.notification?.title ?? 'Rent App';
      final body = message.notification?.body ?? 'You have a new notification';
      final payload = message.data.isNotEmpty ? message.data.toString() : '';

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      print('Local notification shown successfully!');
    } catch (e) {
      print('Error showing local notification: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    // Handle navigation based on payload data
    // This will be handled by the app's navigation system
  }
}
