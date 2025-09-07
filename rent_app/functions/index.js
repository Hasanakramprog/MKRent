const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Cloud Function to send FCM notifications
exports.sendFCMNotification = functions.firestore
  .document('fcm_notifications/{docId}')
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      const { token, notification, data: payload } = data;

      console.log('Processing FCM notification...');
      console.log('Token:', token);
      console.log('Notification:', notification);
      console.log('Data payload:', payload);

      // Prepare the FCM message
      const message = {
        token: token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: payload ? Object.fromEntries(
          Object.entries(payload).map(([key, value]) => [key, String(value)])
        ) : {},
        android: {
          notification: {
            channelId: 'rent_app_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: '@mipmap/ic_launcher',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send the FCM message
      const response = await admin.messaging().send(message);
      console.log('Successfully sent FCM message:', response);

      // Delete the notification document after successful sending
      await snap.ref.delete();
      console.log('Notification document deleted after successful send');

      return { success: true, messageId: response };

    } catch (error) {
      console.error('Error sending FCM notification:', error);
      
      // Update the document with error information instead of deleting
      await snap.ref.update({
        error: error.message,
        errorCode: error.code,
        failed: true,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: (data.retryCount || 0) + 1,
      });
      
      // Re-throw the error so Firebase Functions can retry if needed
      throw new functions.https.HttpsError('internal', 'Failed to send FCM notification', error);
    }
  });

// Cloud Function for manual retry of failed notifications
exports.retryFailedNotification = functions.https.onCall(async (data, context) => {
  try {
    // Verify the user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { docId } = data;
    
    if (!docId) {
      throw new functions.https.HttpsError('invalid-argument', 'Document ID is required');
    }

    const doc = await admin.firestore().collection('fcm_notifications').doc(docId).get();
    
    if (!doc.exists) {
      throw new functions.https.HttpsError('not-found', 'Notification document not found');
    }

    const notificationData = doc.data();
    
    // Reset the failed status and try again
    await doc.ref.update({
      failed: false,
      error: admin.firestore.FieldValue.delete(),
      errorCode: admin.firestore.FieldValue.delete(),
      retryAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Retrying failed notification:', docId);
    return { success: true, message: 'Notification queued for retry' };

  } catch (error) {
    console.error('Error retrying notification:', error);
    throw error;
  }
});

// Cloud Function to process notification queue for chat messages
exports.processNotificationQueue = functions.firestore
    .document('notification_queue/{docId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        
        try {
            // Check if already processed
            if (data.processed) {
                console.log('Notification already processed');
                return null;
            }

            // Additional check for duplicate messageId if present
            if (data.data && data.data.messageId) {
                const existingNotifications = await admin.firestore()
                    .collection('notification_queue')
                    .where('data.messageId', '==', data.data.messageId)
                    .where('processed', '==', true)
                    .limit(1)
                    .get();

                if (!existingNotifications.empty) {
                    console.log('Duplicate notification prevented for messageId:', data.data.messageId);
                    await snap.ref.update({
                        processed: true,
                        duplicate: true,
                        processed_at: admin.firestore.FieldValue.serverTimestamp()
                    });
                    return null;
                }
            }

            // Send the notification
            const message = {
                token: data.to,
                notification: data.notification,
                data: data.data || {},
                android: {
                    notification: {
                        channelId: 'chat_messages',
                        priority: 'high',
                        sound: 'default',
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            alert: data.notification,
                            sound: 'default',
                            badge: 1
                        }
                    }
                }
            };

            const response = await admin.messaging().send(message);
            console.log('Successfully sent chat message notification:', response);

            // Mark as processed
            await snap.ref.update({
                processed: true,
                processed_at: admin.firestore.FieldValue.serverTimestamp(),
                message_id: response
            });

        } catch (error) {
            console.error('Error sending chat notification:', error);
            
            // Mark as failed
            await snap.ref.update({
                processed: true,
                failed: true,
                error: error.message,
                processed_at: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        return null;
    });

// Cloud Function to send chat notifications via callable function
exports.sendChatNotification = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { receiverId, senderName, messageText, chatId, productTitle } = data;
    
    if (!receiverId || !senderName || !messageText || !chatId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    try {
        // Get receiver's FCM token
        const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
        
        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Receiver not found');
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        if (!fcmToken) {
            console.log(`No FCM token for user ${receiverId}`);
            return { success: false, reason: 'No FCM token' };
        }

        // Check notification settings
        const notificationSettings = userData.notificationSettings || {};
        if (notificationSettings.chatMessages === false) {
            console.log(`Chat notifications disabled for user ${receiverId}`);
            return { success: false, reason: 'Notifications disabled' };
        }

        // Prepare notification
        const title = productTitle ? `New message about ${productTitle}` : `New message from ${senderName}`;
        const body = messageText.length > 100 ? `${messageText.substring(0, 100)}...` : messageText;

        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body
            },
            data: {
                chatId: chatId,
                type: 'chat_message',
                senderName: senderName,
                ...(productTitle && { productTitle: productTitle })
            },
            android: {
                notification: {
                    channelId: 'chat_messages',
                    priority: 'high',
                    sound: 'default',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                }
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: title,
                            body: body
                        },
                        sound: 'default',
                        badge: 1,
                        category: 'CHAT_MESSAGE'
                    }
                }
            }
        };

        // Send notification
        const response = await admin.messaging().send(message);
        console.log('Successfully sent chat notification via callable:', response);

        return { success: true, messageId: response };

    } catch (error) {
        console.error('Error sending chat notification via callable:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send notification');
    }
});

// Cloud Function to clean up old notification queue entries
exports.cleanupNotificationQueue = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - 7); // Keep records for 7 days
        
        try {
            const oldNotifications = await admin.firestore()
                .collection('notification_queue')
                .where('created_at', '<', admin.firestore.Timestamp.fromDate(cutoff))
                .get();
            
            const batch = admin.firestore().batch();
            oldNotifications.docs.forEach((doc) => {
                batch.delete(doc.ref);
            });
            
            await batch.commit();
            console.log(`Cleaned up ${oldNotifications.docs.length} old notification records`);
        } catch (error) {
            console.error('Error cleaning up notification queue:', error);
        }
        
        return null;
    });
