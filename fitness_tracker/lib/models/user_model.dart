class UserModel {
  final String id;
  final String name;
  final String email;
  final double height; // in cm
  final double weight; // in kg
  final int age;
  final String gender;
  final DateTime createdAt;
  final Map<String, dynamic>? fitnessGoals;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
    required this.createdAt,
    this.fitnessGoals,
  });

  // Calculate BMI - Body Mass Index
  double get bmi {
    // BMI = weight(kg) / (height(m) * height(m))
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Get BMI category
  String get bmiCategory {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  // Get daily calorie needs (using Mifflin-St Jeor Equation)
  double get dailyCalorieNeeds {
    double bmr;
    if (gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
    
    // Assuming moderate activity level (1.55 multiplier)
    return bmr * 1.55;
  }

  // Convert Firestore data to UserModel
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      height: (data['height'] ?? 170).toDouble(),
      weight: (data['weight'] ?? 70).toDouble(),
      age: data['age'] ?? 30,
      gender: data['gender'] ?? 'Male',
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      fitnessGoals: data['fitness_goals'],
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'created_at': createdAt,
      'fitness_goals': fitnessGoals,
    };
  }

  // Copy with method for updating user properties
  UserModel copyWith({
    String? name,
    String? email,
    double? height,
    double? weight,
    int? age,
    String? gender,
    Map<String, dynamic>? fitnessGoals,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      createdAt: this.createdAt,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
    );
  }
}