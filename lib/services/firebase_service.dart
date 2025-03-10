import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Service class for Firebase functionality
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  // Private constructor
  FirebaseService._internal();

  // Factory constructor to return the same instance
  factory FirebaseService() {
    return _instance;
  }

  // Firebase instances
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  
  bool _initialized = false;
  String? _initError;

  // Getters for initialized Firebase instances
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  
  bool get isInitialized => _initialized;
  String? get initError => _initError;

  /// Initialize Firebase using the provided API key
  /// Returns true if initialization was successful
  Future<bool> initialize({required String apiKey}) async {
    if (_initialized) return true;

    try {
      // Set up the Firebase options with the API key
      final options = FirebaseOptions(
        apiKey: apiKey,
        appId: '1:123456789012:android:1234567890123456789012', // Placeholder for now
        messagingSenderId: '123456789012', // Placeholder for now
        projectId: 'fuel-fitness-app', // Placeholder for now
      );

      // Initialize Firebase
      await Firebase.initializeApp(options: options);

      // Initialize the Firebase instances
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      _initialized = true;
      _initError = null;
      return true;
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      _initError = e.toString();
      _initialized = false;
      return false;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Register a new user with email and password
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the user's display name
      await credential.user?.updateDisplayName(displayName);

      // Create a user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    await _auth.signOut();
  }

  /// Get the current signed-in user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Update a user's fitness data
  Future<void> updateFitnessData(String userId, Map<String, dynamic> data) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      await _firestore.collection('fitness_data').doc(userId).set(
        {
          'lastUpdated': FieldValue.serverTimestamp(),
          ...data,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error updating fitness data: $e');
      rethrow;
    }
  }

  /// Get user fitness data
  Future<Map<String, dynamic>?> getFitnessData(String userId) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      final doc = await _firestore.collection('fitness_data').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting fitness data: $e');
      rethrow;
    }
  }

  /// Get a stream of user fitness data
  Stream<DocumentSnapshot> streamFitnessData(String userId) {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    return _firestore.collection('fitness_data').doc(userId).snapshots();
  }

  /// Store health metrics history
  Future<void> storeHealthMetrics(
    String userId, 
    Map<String, dynamic> metrics
  ) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      // Add metrics to history subcollection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_history')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        ...metrics,
      });

      // Update the latest metrics in the user document
      await _firestore.collection('users').doc(userId).update({
        'latestMetrics': {
          'timestamp': FieldValue.serverTimestamp(),
          ...metrics,
        }
      });
    } catch (e) {
      debugPrint('Error storing health metrics: $e');
      rethrow;
    }
  }

  /// Get the user health metrics history
  Future<List<Map<String, dynamic>>> getHealthMetricsHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('health_history')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting health metrics history: $e');
      return [];
    }
  }
}