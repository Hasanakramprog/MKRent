import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Force account picker to show every time
    forceCodeForRefreshToken: true,
  );
  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
  static bool get isAdmin => _currentUser?.isAdmin ?? false;
  static bool get isCustomer => _currentUser?.isCustomer ?? false;
  static String? get userId => _currentUser?.id;
  static bool get needsPhoneNumber => _currentUser?.phone == null || _currentUser!.phone!.isEmpty;

  // Initialize auth state
  static Future<void> initialize() async {
    try {
      print('Initializing GoogleAuthService...');
      final user = _auth.currentUser;
      if (user != null) {
        print('Found existing user: ${user.uid}');
        await _loadUserData(user.uid);
        
        // For existing logged-in users, validate FCM token freshness
        await NotificationService.validateTokenForLongTermUser();
      } else {
        print('No existing user found');
      }
      print('GoogleAuthService initialization completed');
    } catch (e) {
      print('Error during GoogleAuthService initialization: $e');
      // Don't throw - let the app continue
    }
  }

  // Load user data from Firestore
  static Future<void> _loadUserData(String userId) async {
    try {
      print('Loading user data for: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        print('User document found in Firestore');
        _currentUser = AppUser.fromMap(doc.data()!);
        print('User data loaded: ${_currentUser?.name}');
        
        // Save to SharedPreferences for offline access
        await _saveUserToPrefs(_currentUser!);
        print('User data saved to SharedPreferences');
      } else {
        print('User document not found in Firestore');
        _currentUser = null;
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Try to load from SharedPreferences as fallback
      await _loadUserFromPrefs();
    }
  }

  // Google Sign-In with Account Picker
  static Future<AppUser?> signInWithGoogleAccountPicker() async {
    try {
      print('Starting Google Sign-In with account picker...');
      
      // Disconnect completely to force account selection
      await _googleSignIn.disconnect();
      print('Disconnected from Google to force account picker');
      
      // Trigger the authentication flow - this will show account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }

      print('Google user selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google user credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('Failed to sign in with Firebase');
        return null;
      }

      print('Firebase user signed in: ${firebaseUser.uid}');

      // Check if this is a new user or existing user
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        print('New user detected, creating user record...');
        // Create new user record
        final newUser = AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? googleUser.displayName ?? 'Unknown User',
          email: firebaseUser.email ?? googleUser.email,
          phone: null, // Phone will be collected later
          role: UserRole.customer, // Default role
          createdAt: DateTime.now(),
          photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
        );

        // Save to Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        _currentUser = newUser;
        print('New user created and saved to Firestore');
      } else {
        print('Existing user, loading data...');
        // Load existing user data
        await _loadUserData(firebaseUser.uid);
      }

      // Initialize notifications
      await NotificationService.initialize();
      print('Notifications initialized for user');

      // Handle FCM token for logged-in user
      await NotificationService.onUserLogin();
      print('FCM token handling completed for user');

      // On real devices, sometimes FCM token needs a manual refresh
      // Try to refresh if no token was saved in the previous step
      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!userDoc.exists || userDoc.data()?['fcmToken'] == null) {
          print('No FCM token found, attempting manual refresh...');
          await NotificationService.refreshFCMToken();
        }
      } catch (e) {
        print('Note: Could not verify FCM token status: $e');
      }

      return _currentUser;
    } catch (e) {
      print('Error during Google Sign-In with account picker: $e');
      return null;
    }
  }

  // Google Sign-In
  static Future<AppUser?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();
      print('Signed out from previous Google account');
      
      // Trigger the authentication flow - this will show account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }

      print('Google user selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google user credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('Failed to sign in with Firebase');
        return null;
      }

      print('Firebase user signed in: ${firebaseUser.uid}');

      // Check if this is a new user or existing user
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        print('New user detected, creating user record...');
        // Create new user record (without phone initially)
        final newUser = AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? googleUser.displayName ?? 'Unknown User',
          email: firebaseUser.email ?? googleUser.email,
          phone: null, // Will be collected later
          role: UserRole.customer, // Default role
          createdAt: DateTime.now(),
          photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
        );

        // Save to Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        _currentUser = newUser;
        print('New user created and saved to Firestore');
        
        // Return user but mark as needing phone number
        return newUser;
      } else {
        print('Existing user, loading data...');
        // Load existing user data
        await _loadUserData(firebaseUser.uid);
      }

      // Initialize notifications
      await NotificationService.initialize();
      print('Notifications initialized for user');

      // Handle FCM token for logged-in user
      await NotificationService.onUserLogin();
      print('FCM token handling completed for user');

      // On real devices, sometimes FCM token needs a manual refresh
      // Try to refresh if no token was saved in the previous step
      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!userDoc.exists || userDoc.data()?['fcmToken'] == null) {
          print('No FCM token found, attempting manual refresh...');
          await NotificationService.refreshFCMToken();
        }
      } catch (e) {
        print('Note: Could not verify FCM token status: $e');
      }

      return _currentUser;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      print('Signing out...');
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Clear user data
      _currentUser = null;
      
      // Clear SharedPreferences
      await _clearUserFromPrefs();
      
      print('User signed out successfully');
    } catch (e) {
      print('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Check if email is already registered
  static Future<bool> isEmailRegistered(String email) async {
    try {
      print('Checking if email is registered: $email');
      
      // Query Firestore to check if a user with this email exists
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      final isRegistered = query.docs.isNotEmpty;
      print('Email registration check result: $isRegistered');
      return isRegistered;
    } catch (e) {
      print('Error checking email registration: $e');
      return false;
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      if (_currentUser == null) {
        print('No current user to update');
        return false;
      }

      print('Updating user profile...');
      
      // Check if this is the first time adding a phone number
      final isFirstTimePhoneAdd = phone != null && 
          (_currentUser!.phone == null || _currentUser!.phone!.isEmpty);
      
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      // Update Firestore
      await _firestore.collection('users').doc(_currentUser!.id).update(updates);
      
      // Update local user object
      final updatedUser = AppUser(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        email: email ?? _currentUser!.email,
        role: _currentUser!.role,
        storeId: _currentUser!.storeId,
        storeName: _currentUser!.storeName,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
        photoUrl: _currentUser!.photoUrl,
      );
      
      _currentUser = updatedUser;
      await _saveUserToPrefs(_currentUser!);
      
      // If this is the first time adding a phone number, ensure FCM token is properly set up
      if (isFirstTimePhoneAdd) {
        print('First time phone number added, ensuring FCM token is set up...');
        try {
          // Check if user already has an FCM token
          final userDoc = await _firestore.collection('users').doc(_currentUser!.id).get();
          final existingToken = userDoc.data()?['fcmToken'];
          
          if (existingToken == null || existingToken.isEmpty) {
            print('No existing FCM token found, initializing...');
            
            // Initialize notifications if not already done
            await NotificationService.initialize();
            
            // Handle FCM token for the newly completed user profile
            await NotificationService.onUserLogin();
            
            print('FCM token initialization completed for first-time phone user');
          } else {
            print('FCM token already exists: $existingToken');
            
            // Token exists but let's refresh it to make sure it's current
            await NotificationService.onUserLogin();
            print('FCM token refreshed for completed profile');
          }
        } catch (e) {
          print('Error setting up FCM token for first-time phone user: $e');
          // Don't fail the profile update if FCM fails
        }
      }
      
      print('User profile updated successfully');
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Save user to SharedPreferences
  static Future<void> _saveUserToPrefs(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);
      if (user.phone != null) await prefs.setString('user_phone', user.phone!);
      await prefs.setString('user_role', user.role.toString());
      if (user.storeId != null) await prefs.setString('user_store_id', user.storeId!);
      if (user.storeName != null) await prefs.setString('user_store_name', user.storeName!);
      if (user.photoUrl != null) await prefs.setString('user_photo_url', user.photoUrl!);
    } catch (e) {
      print('Error saving user to SharedPreferences: $e');
    }
  }

  // Load user from SharedPreferences
  static Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        final name = prefs.getString('user_name') ?? '';
        final email = prefs.getString('user_email') ?? '';
        final phone = prefs.getString('user_phone');
        final roleString = prefs.getString('user_role') ?? 'UserRole.customer';
        final storeId = prefs.getString('user_store_id');
        final storeName = prefs.getString('user_store_name');
        final photoUrl = prefs.getString('user_photo_url');
        
        final role = UserRole.values.firstWhere(
          (r) => r.toString() == roleString,
          orElse: () => UserRole.customer,
        );
        
        _currentUser = AppUser(
          id: userId,
          name: name,
          email: email,
          phone: phone,
          role: role,
          storeId: storeId,
          storeName: storeName,
          createdAt: DateTime.now(), // We don't store this in prefs
          photoUrl: photoUrl,
        );
        
        print('User loaded from SharedPreferences: $name');
      }
    } catch (e) {
      print('Error loading user from SharedPreferences: $e');
    }
  }

  // Clear user from SharedPreferences
  static Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_role');
      await prefs.remove('user_store_id');
      await prefs.remove('user_store_name');
      await prefs.remove('user_photo_url');
    } catch (e) {
      print('Error clearing user from SharedPreferences: $e');
    }
  }

  // Delete user account
  static Future<bool> deleteAccount() async {
    try {
      if (_currentUser == null) return false;

      print('Deleting user account...');
      
      // Delete from Firestore
      await _firestore.collection('users').doc(_currentUser!.id).delete();
      
      // Delete Firebase Auth account
      await _auth.currentUser?.delete();
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear local data
      _currentUser = null;
      await _clearUserFromPrefs();
      
      print('User account deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }

  // Get current Firebase user
  static User? get firebaseUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
