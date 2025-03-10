import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Service to handle authentication and user profile management
class AuthService {
  // Singleton implementation
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User stream
  Stream<User?> get userStream => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  /// Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e, stack) {
      Logger.logError('Sign in failed', e, stack);
      rethrow;
    }
  }
  
  /// Create a new user account
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile document
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'preferences': {
            'darkMode': false,
            'useMetric': true,
            'autoTracking': true,
          }
        });
      } catch (e, stack) {
        Logger.logError("Profile creation error", e, stack);
        // Don't block sign-up if profile creation fails
        // We'll retry later
      }
      
      return userCredential.user;
    } catch (e, stack) {
      Logger.logError('Sign up failed', e, stack);
      rethrow;
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e, stack) {
      Logger.logError('Sign out failed', e, stack);
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, stack) {
      Logger.logError('Password reset failed', e, stack);
      rethrow;
    }
  }
  
  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;
      
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.data();
    } catch (e, stack) {
      Logger.logError('Get user profile failed', e, stack);
      return null;
    }
  }
  
  /// Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (currentUser == null) return false;
      
      await _firestore.collection('users').doc(currentUser!.uid).update(data);
      return true;
    } catch (e, stack) {
      Logger.logError('Update user profile failed', e, stack);
      return false;
    }
  }
  
  /// Update user preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      if (currentUser == null) return false;
      
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'preferences': preferences,
      });
      return true;
    } catch (e, stack) {
      Logger.logError('Update preferences failed', e, stack);
      return false;
    }
  }
}