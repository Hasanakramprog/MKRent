# Firebase Cloud Functions Setup for Rent App Notifications

## Overview
This setup enables automatic FCM (Firebase Cloud Messaging) push notifications for the Rent App using Firebase Cloud Functions.

## How it Works
1. When a notification is sent in the app, it creates a document in the `fcm_notifications` Firestore collection
2. A Cloud Function automatically triggers when a new document is created
3. The Cloud Function sends the actual FCM push notification to the user's device
4. The document is deleted after successful sending, or marked as failed if there's an error

## Setup Instructions

### 1. Enable Required APIs
Make sure these APIs are enabled in your Firebase project:
- Cloud Functions API
- Cloud Build API
- Artifact Registry API

### 2. Deploy Functions
From the main app directory, run:
```bash
firebase deploy --only functions --project rent-app-mkpro
```

### 3. Test the Notifications
Once deployed, the app will automatically:
- Queue notifications in Firestore when events occur (rental requests, approvals, etc.)
- The Cloud Function will process these and send push notifications
- Background notifications will work even when the app is closed

## Monitoring
- Check Firebase Console > Functions to see function executions
- Check Firebase Console > Firestore > fcm_notifications collection for any failed notifications
- Check device logs for notification delivery confirmation

## Functions Included

### sendFCMNotification
- **Trigger**: New document in `fcm_notifications` collection
- **Purpose**: Sends FCM push notification to user's device
- **Behavior**: Deletes document on success, marks as failed on error

### retryFailedNotification
- **Trigger**: HTTP callable function
- **Purpose**: Manually retry failed notifications
- **Usage**: Can be called from the app to retry failed notifications

## Troubleshooting
- If notifications aren't working, check that FCM tokens are being saved properly
- Verify that the Cloud Functions are deployed and active
- Check the Functions logs in Firebase Console for error details
