/// Represents a user in the fitness tracking app
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final int? age;
  final double? weight; // in kg
  final double? height; // in cm
  final String? gender; // male, female, other
  final DateTime? birthDate;
  final Map<String, dynamic>? goals;
  final Map<String, dynamic>? settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.birthDate,
    this.goals,
    this.settings,
    this.createdAt,
    this.updatedAt,
  });

  /// Create a UserModel from a map (typically from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      photoUrl: map['photoUrl'],
      age: map['age'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      gender: map['gender'],
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
      goals: map['goals'],
      settings: map['settings'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert this UserModel to a map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'birthDate': birthDate,
      'goals': goals,
      'settings': settings,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  /// Create a copy of this UserModel with some values replaced
  UserModel copyWith({
    String? name,
    String? photoUrl,
    int? age,
    double? weight,
    double? height,
    String? gender,
    DateTime? birthDate,
    Map<String, dynamic>? goals,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      goals: goals ?? this.goals,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Get user's BMI (Body Mass Index)
  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      // BMI = weight(kg) / (height(m))²
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  /// Get BMI category based on the BMI value
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';

    if (bmiValue < 18.5) {
      return 'Underweight';
    } else if (bmiValue < 25) {
      return 'Normal';
    } else if (bmiValue < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  /// Get daily calorie goal from goals or return a default value
  int get dailyCalorieGoal {
    if (goals != null && goals!.containsKey('dailyCalories')) {
      return goals!['dailyCalories'] as int;
    }
    // Default based on average adult needs
    return 2000;
  }

  /// Get daily steps goal from goals or return a default value
  int get dailyStepsGoal {
    if (goals != null && goals!.containsKey('dailySteps')) {
      return goals!['dailySteps'] as int;
    }
    // Default steps goal
    return 10000;
  }

  /// Get daily water intake goal from goals or return a default value
  int get dailyWaterGoal {
    if (goals != null && goals!.containsKey('dailyWater')) {
      return goals!['dailyWater'] as int;
    }
    // Default water intake in ml
    return 2000;
  }

  /// Get weekly workout goal from goals or return a default value
  int get weeklyWorkoutGoal {
    if (goals != null && goals!.containsKey('weeklyWorkouts')) {
      return goals!['weeklyWorkouts'] as int;
    }
    // Default workouts per week
    return 3;
  }
}

/// Extension for operations on lists of UserModel objects
extension UserModelListExtension on List<UserModel> {
  /// Sort users by name
  List<UserModel> sortByName() {
    return [...this]..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
  }

  /// Filter users by a specific gender
  List<UserModel> filterByGender(String gender) {
    return where((user) => user.gender == gender).toList();
  }

  /// Filter users by age range
  List<UserModel> filterByAgeRange(int minAge, int maxAge) {
    return where((user) => user.age != null && user.age! >= minAge && user.age! <= maxAge).toList();
  }
}