import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class EmailAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  static Future<AppUser?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      print('Creating user with email: $email');
      
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await firebaseUser.updateDisplayName(name);

      // Send email verification
      await firebaseUser.sendEmailVerification();

      // Create user document in Firestore
      final appUser = AppUser(
        id: firebaseUser.uid,
        email: email,
        name: name,
        phone: phone,
        role: UserRole.customer, // Default role
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(appUser.toMap());

      // Initialize notifications for new user
      try {
        await NotificationService.initialize();
      } catch (e) {
        print('Warning: Failed to initialize notifications: $e');
      }

      print('User created successfully: ${firebaseUser.uid}');
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create account: ${e.toString()}');
    }
  }

  // Sign in with email and password
  static Future<AppUser?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Signing in with email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Sign in failed');
      }

      // Load user data from Firestore
      final appUser = await _loadUserData(firebaseUser.uid);
      if (appUser == null) {
        throw Exception('User data not found');
      }

      // Update last login and notifications
      await _updateLastLogin(firebaseUser.uid);
      try {
        await NotificationService.initialize();
      } catch (e) {
        print('Warning: Failed to initialize notifications: $e');
      }

      print('User signed in successfully: ${firebaseUser.uid}');
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error signing in: $e');
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw Exception('Failed to send password reset email');
    }
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Email verification sent to: ${user.email}');
      } else if (user?.emailVerified == true) {
        print('Email is already verified');
      } else {
        throw Exception('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error sending verification: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error sending email verification: $e');
      throw Exception('Failed to send email verification: ${e.toString()}');
    }
  }

  // Check email verification status
  static Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Check if email is already registered
  static Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email registration: $e');
      return false;
    }
  }

  // Load user data from Firestore
  static Future<AppUser?> _loadUserData(String userId) async {
    try {
      print('Loading user data for: $userId');
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        final appUser = AppUser.fromMap(userData);
        print('User data loaded successfully');
        return appUser;
      } else {
        print('User document not found');
        return null;
      }
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  // Update last login timestamp
  static Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Handle Firebase Auth exceptions
  static Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email address');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'email-already-in-use':
        return Exception('An account already exists with this email address');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'user-disabled':
        return Exception('This account has been disabled');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later');
      case 'operation-not-allowed':
        return Exception('Email/password sign-in is not enabled');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }

  // Get current Firebase user
  static User? get currentFirebaseUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if current user's email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload current user to get updated email verification status
  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}
