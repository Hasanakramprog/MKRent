# 🧪 Testing Notifications Guide

## How to Test Background Notifications

### 1. **Test Button Added**
I've added a test notification button (📳+) to the home screen next to the notification bell.

### 2. **Testing Steps:**

#### **Test 1: In-App Notifications**
1. Open the app and login
2. Tap the test notification button (📳+) in the top-right header
3. You should see:
   - Loading message: "Sending test notification..."
   - Success message: "Test notification sent!"
   - Notification appears in your notifications screen

#### **Test 2: Background Notifications**
1. Open the app and tap the test button
2. **Minimize the app** (don't close completely)
3. Wait 5-10 seconds
4. You should see a notification in your device's notification panel

#### **Test 3: App Closed Notifications**
1. Open the app and tap the test button
2. **Completely close the app** (swipe up and remove from recent apps)
3. Wait 5-10 seconds
4. You should see a notification in your device's notification panel
5. Tap the notification - it should open the app

### 3. **What to Expect:**
- **Title**: "Test Notification"
- **Message**: "This is a test notification to verify the system is working!"
- **Channel**: "Rent App Notifications"
- **Sound & Vibration**: Yes (if enabled in device settings)

### 4. **Monitoring:**
- Check Firebase Console > Functions for execution logs
- Check Firebase Console > Firestore > `fcm_notifications` collection
- Check device notification settings if notifications don't appear

### 5. **Troubleshooting:**
If notifications don't work:
1. Check app notification permissions in device settings
2. Verify Firebase Cloud Functions are deployed
3. Check that FCM token is being saved (check console logs)
4. Ensure device has internet connection

### 6. **Real-World Testing:**
Once test notifications work, try:
- Making a rental request (should notify admin)
- Admin approving/rejecting requests (should notify customer)
- All these should work in background/closed app scenarios

## 🎉 Success Criteria:
✅ Test notification appears in notification panel when app is minimized
✅ Test notification appears when app is completely closed
✅ Tapping notification opens the app
✅ In-app notifications work in the notifications screen
