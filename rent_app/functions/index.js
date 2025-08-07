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
