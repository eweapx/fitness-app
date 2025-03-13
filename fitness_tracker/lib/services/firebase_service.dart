import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/nutrition_model.dart';

/// Service class for Firebase interactions
class FirebaseService {
  // Singletons for Firebase services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Authentication methods
  
  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Check if user is signed in
  bool get isUserSignedIn => _auth.currentUser != null;
  
  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Create a new user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
  
  // User profile methods
  
  /// Create a new user profile
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get a user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update a user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Upload profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
  
  // Activity methods
  
  /// Add a new activity
  Future<String> addActivity(ActivityModel activity) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(activity.userId)
          .collection('activities')
          .add(activity.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update an activity
  Future<void> updateActivity(ActivityModel activity) async {
    try {
      await _firestore
          .collection('users')
          .doc(activity.userId)
          .collection('activities')
          .doc(activity.id)
          .update(activity.toMap());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Delete an activity
  Future<void> deleteActivity(String userId, String activityId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get all activities for a user
  Future<List<ActivityModel>> getUserActivities(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get activities for a specific date
  Future<List<ActivityModel>> getActivitiesByDate(
      String userId, DateTime date) async {
    try {
      // Create datetime range for the given date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Nutrition methods
  
  /// Add a new food entry
  Future<String> addFoodEntry(NutritionModel food) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(food.userId)
          .collection('nutrition')
          .add(food.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update a food entry
  Future<void> updateFoodEntry(NutritionModel food) async {
    try {
      await _firestore
          .collection('users')
          .doc(food.userId)
          .collection('nutrition')
          .doc(food.id)
          .update(food.toMap());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Delete a food entry
  Future<void> deleteFoodEntry(String userId, String foodId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .doc(foodId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get all food entries for a user
  Future<List<NutritionModel>> getUserNutrition(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => NutritionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get food entries for a specific date
  Future<List<NutritionModel>> getNutritionByDate(
      String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();
      
      return querySnapshot.docs
          .map((doc) => NutritionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Goal tracking methods
  
  /// Set user goals
  Future<void> setUserGoals(String userId, Map<String, dynamic> goals) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'goals': goals,
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get user goals
  Future<Map<String, dynamic>?> getUserGoals(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return data['goals'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Statistics and aggregation methods
  
  /// Get activity statistics for a date range
  Future<Map<String, dynamic>> getActivityStats(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      
      final activities = querySnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Calculate stats
      int totalActivities = activities.length;
      int totalCaloriesBurned = 0;
      int totalDuration = 0;
      Map<String, int> activityTypeCount = {};
      
      for (var activity in activities) {
        totalCaloriesBurned += activity.caloriesBurned;
        totalDuration += activity.duration;
        
        // Count by activity type
        activityTypeCount[activity.type] = 
            (activityTypeCount[activity.type] ?? 0) + 1;
      }
      
      return {
        'totalActivities': totalActivities,
        'totalCaloriesBurned': totalCaloriesBurned,
        'totalDuration': totalDuration,
        'activityTypeCount': activityTypeCount,
      };
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get nutrition statistics for a date range
  Future<Map<String, dynamic>> getNutritionStats(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      
      final foodEntries = querySnapshot.docs
          .map((doc) => NutritionModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Calculate stats
      int totalCaloriesConsumed = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;
      Map<String, int> categoryCount = {};
      
      for (var entry in foodEntries) {
        totalCaloriesConsumed += entry.calories;
        totalProtein += entry.protein;
        totalCarbs += entry.carbs;
        totalFat += entry.fat;
        
        // Count by food category
        categoryCount[entry.category] = 
            (categoryCount[entry.category] ?? 0) + 1;
      }
      
      return {
        'totalCaloriesConsumed': totalCaloriesConsumed,
        'totalProtein': totalProtein,
        'totalCarbs': totalCarbs,
        'totalFat': totalFat,
        'categoryCount': categoryCount,
      };
    } catch (e) {
      rethrow;
    }
  }
}