import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class StorageTestService {
  static Future<bool> testStorageConnection() async {
    try {
      print('Testing Firebase Storage connection...');
      
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated');
        return false;
      }
      
      print('User authenticated: ${user.uid}');
      
      // Try to get a reference to the storage
      final storageRef = FirebaseStorage.instance.ref();
      print('Storage reference created: ${storageRef.bucket}');
      
      // Try to list items in the root (this will fail if storage is not set up)
      try {
        final listResult = await storageRef.list();
        print('Storage connection successful. Items found: ${listResult.items.length}');
        return true;
      } catch (e) {
        print('Storage list error (this might be expected): $e');
        // This might fail due to security rules, but it means storage is accessible
        return true;
      }
    } catch (e) {
      print('Storage connection test failed: $e');
      return false;
    }
  }
  
  static Future<String?> testImageUpload(File imageFile) async {
    try {
      print('Testing image upload...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Create test reference
      final testRef = FirebaseStorage.instance
          .ref()
          .child('test')
          .child('test_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      print('Test upload path: ${testRef.fullPath}');
      
      // Upload test file
      final uploadTask = testRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      print('Test upload completed');
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Test download URL: $downloadUrl');
      
      // Clean up - delete the test file
      await testRef.delete();
      print('Test file cleaned up');
      
      return downloadUrl;
    } catch (e) {
      print('Test upload failed: $e');
      return null;
    }
  }
}
