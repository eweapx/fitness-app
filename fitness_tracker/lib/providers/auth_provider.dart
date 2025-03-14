import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required AuthService authService}) : _authService = authService {
    _init();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Initialize auth state
  void _init() {
    _authService.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.registerWithEmailAndPassword(email, password, displayName);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signOut();
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({String? displayName}) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateProfile(displayName: displayName);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      // First reauthenticate with current password
      final email = _currentUser?.email;
      if (email != null) {
        await _authService.reauthenticate(email, currentPassword);
      }
      
      // Then update to new password
      await _authService.updatePassword(newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper to set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Helper to clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper to convert Firebase Auth errors to user-friendly messages
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'requires-recent-login':
          return 'Please sign in again to complete this action.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    
    return 'An unexpected error occurred.';
  }
}