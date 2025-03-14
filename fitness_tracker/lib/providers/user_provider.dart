import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider to manage user data and authentication state
class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User information
  User? _user;
  String? _userName;
  String? _userPhotoUrl;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get user => _user;
  String? get userName => _userName;
  String? get userPhotoUrl => _userPhotoUrl;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAuthenticated => _user != null;
  String get userId => _user?.uid ?? '';
  String? get userEmail => _user?.email;
  
  // Constructor - initialize auth state
  UserProvider() {
    _initializeAuthState();
  }
  
  // Initialize auth state listener
  void _initializeAuthState() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        _userName = user.displayName;
        _userPhotoUrl = user.photoURL;
        await fetchUserProfile();
      } else {
        _userName = null;
        _userPhotoUrl = null;
        _userProfile = null;
      }
      notifyListeners();
    });
  }
  
  // Login with email and password
  Future<bool> loginWithEmailPassword(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }
  
  // Register with email and password
  Future<bool> registerWithEmailPassword(
    String email, 
    String password, 
    String name,
  ) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!.uid, name, email);
      }
      
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }
  
  // Create initial user profile in Firestore
  Future<void> _createUserProfile(String uid, String name, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isOnboardingComplete': false,
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }
  
  // Fetch user profile from Firestore
  Future<void> fetchUserProfile() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userProfile = doc.data();
      } else {
        // If profile doesn't exist in Firestore, create it
        await _createUserProfile(
          _user!.uid, 
          _user!.displayName ?? 'User', 
          _user!.email ?? '',
        );
        final newDoc = await _firestore.collection('users').doc(_user!.uid).get();
        _userProfile = newDoc.data();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;
    
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        ...data,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Refresh the profile data
      await fetchUserProfile();
      
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // Update user profile photo URL
  Future<bool> updateUserPhoto(String photoUrl) async {
    if (_user == null) return false;
    
    try {
      await _user!.updatePhotoURL(photoUrl);
      _userPhotoUrl = photoUrl;
      
      // Update in Firestore too
      await _firestore.collection('users').doc(_user!.uid).update({
        'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user photo: $e');
      return false;
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }
  
  // Update user name
  Future<bool> updateUserName(String name) async {
    if (_user == null) return false;
    
    try {
      await _user!.updateDisplayName(name);
      _userName = name;
      
      // Update in Firestore too
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user name: $e');
      return false;
    }
  }
  
  // Update email
  Future<bool> updateEmail(String newEmail, String password) async {
    if (_user == null) return false;
    
    _setLoading(true);
    try {
      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      await _user!.reauthenticateWithCredential(credential);
      
      // Update email
      await _user!.updateEmail(newEmail);
      
      // Update in Firestore too
      await _firestore.collection('users').doc(_user!.uid).update({
        'email': newEmail,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }
  
  // Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    if (_user == null || _user!.email == null) return false;
    
    _setLoading(true);
    try {
      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);
      
      // Update password
      await _user!.updatePassword(newPassword);
      
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }
  
  // Log out
  Future<void> logout() async {
    try {
      // Update last active time before logging out
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      
      await _auth.signOut();
      _setError(null);
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
  
  // Handle common Firebase Auth errors
  void _handleAuthError(dynamic error) {
    String errorMessage = 'An unknown error occurred';
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'email-already-in-use':
          errorMessage = 'This email is already in use.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operation not allowed.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again before retrying this request.';
          break;
        default:
          errorMessage = error.message ?? 'An unknown error occurred';
      }
    }
    
    _setError(errorMessage);
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error message
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Check if user exists
  Future<bool> checkUserExists(String email) async {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }
  
  // Update onboarding status
  Future<bool> completeOnboarding() async {
    if (_user == null) return false;
    
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'isOnboardingComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Refresh user profile
      await fetchUserProfile();
      
      return true;
    } catch (e) {
      debugPrint('Error updating onboarding status: $e');
      return false;
    }
  }
}