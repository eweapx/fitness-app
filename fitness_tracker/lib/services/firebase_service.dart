import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_model.dart';
import '../models/sleep_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth methods
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }
  
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error registering: $e');
      rethrow;
    }
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // User profile methods
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }
  
  // Habit tracking methods
  Future<List<Habit>> getUserHabits(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting habits: $e');
      rethrow;
    }
  }
  
  Future<String> addHabit(Habit habit) async {
    try {
      final docRef = await _firestore.collection('habits').add(habit.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding habit: $e');
      rethrow;
    }
  }
  
  Future<void> updateHabit(Habit habit) async {
    try {
      if (habit.id == null) {
        throw ArgumentError('Habit ID is required for update');
      }
      
      await _firestore.collection('habits').doc(habit.id).update(habit.toFirestore());
    } catch (e) {
      print('Error updating habit: $e');
      rethrow;
    }
  }
  
  Future<void> deleteHabit(String habitId) async {
    try {
      await _firestore.collection('habits').doc(habitId).delete();
    } catch (e) {
      print('Error deleting habit: $e');
      rethrow;
    }
  }
  
  // Sleep tracking methods
  Future<List<SleepEntry>> getSleepEntriesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('sleep')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      
      return snapshot.docs.map((doc) => SleepEntry.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting sleep entries: $e');
      rethrow;
    }
  }
  
  Future<String> addSleepEntry(SleepEntry entry) async {
    try {
      final docRef = await _firestore.collection('sleep').add(entry.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding sleep entry: $e');
      rethrow;
    }
  }
  
  Future<void> updateSleepEntry(SleepEntry entry) async {
    try {
      if (entry.id == null) {
        throw ArgumentError('Sleep entry ID is required for update');
      }
      
      await _firestore.collection('sleep').doc(entry.id).update(entry.toFirestore());
    } catch (e) {
      print('Error updating sleep entry: $e');
      rethrow;
    }
  }
  
  Future<void> deleteSleepEntry(String entryId) async {
    try {
      await _firestore.collection('sleep').doc(entryId).delete();
    } catch (e) {
      print('Error deleting sleep entry: $e');
      rethrow;
    }
  }
  
  // Nutrition methods
  Future<List<Map<String, dynamic>>> getMealEntriesForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      // Convert to date string to match only the date part
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final snapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .where('dateString', isEqualTo: dateString)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting meal entries: $e');
      rethrow;
    }
  }
  
  Future<String> addMealEntry(Map<String, dynamic> mealData) async {
    try {
      final docRef = await _firestore.collection('meals').add(mealData);
      return docRef.id;
    } catch (e) {
      print('Error adding meal entry: $e');
      rethrow;
    }
  }
  
  Future<void> updateMealEntry(String mealId, Map<String, dynamic> mealData) async {
    try {
      await _firestore.collection('meals').doc(mealId).update(mealData);
    } catch (e) {
      print('Error updating meal entry: $e');
      rethrow;
    }
  }
  
  Future<void> deleteMealEntry(String mealId) async {
    try {
      await _firestore.collection('meals').doc(mealId).delete();
    } catch (e) {
      print('Error deleting meal entry: $e');
      rethrow;
    }
  }
  
  // Activity tracking methods
  Future<List<Map<String, dynamic>>> getActivitiesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting activities: $e');
      rethrow;
    }
  }
  
  Future<String> addActivity(Map<String, dynamic> activityData) async {
    try {
      final docRef = await _firestore.collection('activities').add(activityData);
      return docRef.id;
    } catch (e) {
      print('Error adding activity: $e');
      rethrow;
    }
  }
  
  Future<void> updateActivity(String activityId, Map<String, dynamic> activityData) async {
    try {
      await _firestore.collection('activities').doc(activityId).update(activityData);
    } catch (e) {
      print('Error updating activity: $e');
      rethrow;
    }
  }
  
  Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore.collection('activities').doc(activityId).delete();
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }
  
  // User settings methods
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('settings').doc(userId).get();
      return doc.exists ? doc.data()! : {};
    } catch (e) {
      print('Error getting user settings: $e');
      rethrow;
    }
  }
  
  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('settings').doc(userId).set(
        settings,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating user settings: $e');
      rethrow;
    }
  }
}