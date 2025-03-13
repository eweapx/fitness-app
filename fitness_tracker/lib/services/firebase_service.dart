import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/nutrition_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }

  // User data methods
  Future<void> createUserData(UserModel user) async {
    return await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUserData(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.id, snapshot.data()!);
    }
    return null;
  }

  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await getUserData(currentUser!.uid);
  }

  Future<void> updateUserData(UserModel user) async {
    return await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  // Activity methods
  Future<String> addActivity(ActivityModel activity) async {
    final docRef = await _firestore.collection('activities').add(activity.toMap());
    return docRef.id;
  }

  Future<void> updateActivity(ActivityModel activity) async {
    if (activity.id == null) throw Exception('Activity ID cannot be null');
    return await _firestore.collection('activities').doc(activity.id).update(activity.toMap());
  }

  Future<void> deleteActivity(String activityId) async {
    return await _firestore.collection('activities').doc(activityId).delete();
  }

  Stream<List<ActivityModel>> getUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ActivityModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<ActivityModel>> getUserActivitiesForDateRange(String userId, DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('activities')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ActivityModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  // Nutrition methods
  Future<String> addFoodEntry(FoodEntry entry) async {
    final docRef = await _firestore.collection('food_entries').add(entry.toMap());
    return docRef.id;
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    if (entry.id == null) throw Exception('Food entry ID cannot be null');
    return await _firestore.collection('food_entries').doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteFoodEntry(String entryId) async {
    return await _firestore.collection('food_entries').doc(entryId).delete();
  }

  Stream<List<FoodEntry>> getUserFoodEntries(String userId) {
    return _firestore
        .collection('food_entries')
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FoodEntry.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<FoodEntry>> getUserFoodEntriesForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('food_entries')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    return snapshot.docs.map((doc) {
      return FoodEntry.fromMap(doc.id, doc.data());
    }).toList();
  }

  // Get nutrition summary for a date
  Future<NutritionSummary> getNutritionSummaryForDate(String userId, DateTime date) async {
    final entries = await getUserFoodEntriesForDate(userId, date);
    return NutritionSummary.fromEntries(entries);
  }
}