# Firebase Storage Configuration Guide

## The "No object exists at the desired reference" Error

This error typically occurs when Firebase Storage is not properly set up or configured. Here are the steps to fix it:

## 1. Enable Firebase Storage in Firebase Console

1. Go to your Firebase Console (https://console.firebase.google.com)
2. Select your project "rent-app-mkpro"
3. Navigate to "Storage" in the left sidebar
4. Click "Get started" if Storage is not enabled
5. Choose "Start in test mode" for now (we'll secure it later)
6. Select a location for your storage bucket (choose one close to your users)

## 2. Update Storage Security Rules

Replace the default rules with the content from `storage.rules` file:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.auth.uid != null
                   && resource == null
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
    
    match /products/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.auth.uid != null
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 3. Check Firebase Configuration

Make sure your `firebase_options.dart` file includes the Storage configuration:
- `storageBucket` should be present in the FirebaseOptions

## 4. Test the Configuration

1. Use the test button (bug icon) in the Add Product screen
2. Check the console logs for detailed error messages
3. Verify that the user is properly authenticated

## 5. Common Issues and Solutions

### Issue: "Permission denied"
- Check that the user is logged in
- Verify storage security rules allow the operation

### Issue: "Storage bucket not configured"
- Make sure Storage is enabled in Firebase Console
- Check that `storageBucket` is set in `firebase_options.dart`

### Issue: "Network error"
- Check internet connection
- Verify Firebase project configuration

## 6. Manual Fix Steps

If the above doesn't work, try these steps:

1. **Re-generate Firebase configuration:**
   ```bash
   flutterfire configure
   ```

2. **Check your Firebase project quotas:**
   - Go to Firebase Console > Usage and billing
   - Make sure you haven't exceeded free tier limits

3. **Test with Firebase Storage Emulator:**
   ```bash
   firebase emulators:start --only storage
   ```

4. **Check Android permissions:**
   Make sure your app has internet permissions in `android/app/src/main/AndroidManifest.xml`

## 7. Debug Information

The app now includes detailed logging. Check the console output when uploading to see:
- User authentication status
- File path and existence
- Storage reference path
- Upload progress and errors
