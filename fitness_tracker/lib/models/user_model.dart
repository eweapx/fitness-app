import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final double? weight; // kg
  final double? height; // cm
  final String? gender;
  final DateTime? dateOfBirth;
  final String? activityLevel;
  final List<String>? fitnessGoals;
  final Map<String, dynamic>? healthMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.weight,
    this.height,
    this.gender,
    this.dateOfBirth,
    this.activityLevel,
    this.fitnessGoals,
    this.healthMetrics,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a UserModel from a Firebase User and additional data
  factory UserModel.fromFirebaseUser(
      String uid, String email, Map<String, dynamic>? additionalData) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      displayName: additionalData?['displayName'],
      photoURL: additionalData?['photoURL'],
      weight: additionalData?['weight'],
      height: additionalData?['height'],
      gender: additionalData?['gender'],
      dateOfBirth: additionalData?['dateOfBirth'] != null
          ? (additionalData!['dateOfBirth'] as Timestamp).toDate()
          : null,
      activityLevel: additionalData?['activityLevel'],
      fitnessGoals: additionalData?['fitnessGoals'] != null
          ? List<String>.from(additionalData!['fitnessGoals'])
          : null,
      healthMetrics: additionalData?['healthMetrics'],
      createdAt: additionalData?['createdAt'] != null
          ? (additionalData!['createdAt'] as Timestamp).toDate()
          : now,
      updatedAt: now,
    );
  }

  // Convert a UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'weight': weight,
      'height': height,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'activityLevel': activityLevel,
      'fitnessGoals': fitnessGoals,
      'healthMetrics': healthMetrics,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a UserModel from Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      weight: data['weight'],
      height: data['height'],
      gender: data['gender'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      activityLevel: data['activityLevel'],
      fitnessGoals: data['fitnessGoals'] != null
          ? List<String>.from(data['fitnessGoals'])
          : null,
      healthMetrics: data['healthMetrics'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    double? weight,
    double? height,
    String? gender,
    DateTime? dateOfBirth,
    String? activityLevel,
    List<String>? fitnessGoals,
    Map<String, dynamic>? healthMetrics,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Calculate BMI
  double? calculateBMI() {
    if (weight != null && height != null && height! > 0) {
      // BMI = weight(kg) / (height(m))²
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  // Get BMI category
  String? getBMICategory() {
    final bmi = calculateBMI();
    if (bmi == null) return null;
    
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obesity';
    }
  }

  // Calculate age
  int? calculateAge() {
    if (dateOfBirth == null) return null;
    
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}