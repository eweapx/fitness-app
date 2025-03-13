import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  
  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  
  UserProvider() {
    _init();
  }
  
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _user = user;
      
      if (user != null) {
        await _fetchUserProfile();
      } else {
        _userProfile = null;
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }
  
  Future<void> _fetchUserProfile() async {
    if (_user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
          
      if (doc.exists) {
        _userProfile = doc.data();
      } else {
        // Create default profile if it doesn't exist
        _userProfile = {
          'displayName': _user!.displayName ?? 'User',
          'email': _user!.email ?? '',
          'photoURL': _user!.photoURL ?? '',
          'createdAt': DateTime.now(),
          'height': 0,
          'weight': 0,
          'gender': '',
          'dateOfBirth': null,
          'fitnessLevel': 'beginner', // beginner, intermediate, advanced
        };
        
        // Save the default profile
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set(_userProfile!);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update(data);
          
      // Update local profile
      _userProfile = {
        ..._userProfile ?? {},
        ...data,
      };
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      _userProfile = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Get user's age from date of birth
  int? getUserAge() {
    if (_userProfile == null || _userProfile!['dateOfBirth'] == null) {
      return null;
    }
    
    final dateOfBirth = (_userProfile!['dateOfBirth'] as Timestamp).toDate();
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    
    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    
    return age;
  }
  
  // Get BMI (Body Mass Index)
  double? getUserBMI() {
    if (_userProfile == null) return null;
    
    final weight = _userProfile!['weight'] as num?;
    final height = _userProfile!['height'] as num?;
    
    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return null;
    }
    
    // BMI = weight(kg) / height(m)²
    final heightInMeters = height / 100; // Convert cm to meters
    return weight / (heightInMeters * heightInMeters);
  }
  
  // Get BMI category
  String? getUserBMICategory() {
    final bmi = getUserBMI();
    if (bmi == null) return null;
    
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'Normal';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
  
  // Get daily calorie needs
  int? getUserDailyCalorieNeeds() {
    if (_userProfile == null) return null;
    
    final weight = _userProfile!['weight'] as num?;
    final height = _userProfile!['height'] as num?;
    final gender = _userProfile!['gender'] as String?;
    final age = getUserAge();
    
    if (weight == null || height == null || gender == null || age == null ||
        weight <= 0 || height <= 0 || gender.isEmpty) {
      return null;
    }
    
    // Get activity level (default to moderate)
    final activityLevel = _userProfile!['activityLevel'] as String? ?? 'moderate';
    double activityMultiplier;
    
    switch (activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'very_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55; // Default to moderate
    }
    
    // Calculate BMR using Harris-Benedict equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
    
    // Apply activity multiplier
    return (bmr * activityMultiplier).round();
  }
}