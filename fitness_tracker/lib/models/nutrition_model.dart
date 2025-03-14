import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_constants.dart';

class NutritionModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final int calories;
  final double proteins; // in grams
  final double carbs; // in grams
  final double fats; // in grams
  final double? fiber; // in grams
  final double? sugar; // in grams
  final double? servingSize; // in grams
  final int? servingCount;
  final String? servingUnit;
  final Map<String, dynamic>? additionalNutrients;
  final String? notes;
  final String? mealType; // breakfast, lunch, dinner, snack
  final DateTime datetime;
  final DateTime createdAt;
  final DateTime updatedAt;

  NutritionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    this.fiber,
    this.sugar,
    this.servingSize,
    this.servingCount,
    this.servingUnit,
    this.additionalNutrients,
    this.notes,
    this.mealType,
    required this.datetime,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a new nutrition entry with a unique ID
  factory NutritionModel.create({
    required String userId,
    required String name,
    required String category,
    required int calories,
    required double proteins,
    required double carbs,
    required double fats,
    double? fiber,
    double? sugar,
    double? servingSize,
    int? servingCount,
    String? servingUnit,
    Map<String, dynamic>? additionalNutrients,
    String? notes,
    String? mealType,
    DateTime? datetime,
  }) {
    final now = DateTime.now();
    return NutritionModel(
      id: FirebaseFirestore.instance.collection('nutrition').doc().id,
      userId: userId,
      name: name,
      category: category,
      calories: calories,
      proteins: proteins,
      carbs: carbs,
      fats: fats,
      fiber: fiber,
      sugar: sugar,
      servingSize: servingSize,
      servingCount: servingCount,
      servingUnit: servingUnit,
      additionalNutrients: additionalNutrients,
      notes: notes,
      mealType: mealType,
      datetime: datetime ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Convert a NutritionModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'sugar': sugar,
      'servingSize': servingSize,
      'servingCount': servingCount,
      'servingUnit': servingUnit,
      'additionalNutrients': additionalNutrients,
      'notes': notes,
      'mealType': mealType,
      'datetime': Timestamp.fromDate(datetime),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a NutritionModel from Firestore
  factory NutritionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NutritionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      calories: data['calories'] ?? 0,
      proteins: (data['proteins'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fats: (data['fats'] ?? 0).toDouble(),
      fiber: data['fiber'] != null ? (data['fiber']).toDouble() : null,
      sugar: data['sugar'] != null ? (data['sugar']).toDouble() : null,
      servingSize: data['servingSize'] != null ? (data['servingSize']).toDouble() : null,
      servingCount: data['servingCount'],
      servingUnit: data['servingUnit'],
      additionalNutrients: data['additionalNutrients'],
      notes: data['notes'],
      mealType: data['mealType'],
      datetime: data['datetime'] != null
          ? (data['datetime'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create a copy of NutritionModel with updated fields
  NutritionModel copyWith({
    String? name,
    String? category,
    int? calories,
    double? proteins,
    double? carbs,
    double? fats,
    double? fiber,
    double? sugar,
    double? servingSize,
    int? servingCount,
    String? servingUnit,
    Map<String, dynamic>? additionalNutrients,
    String? notes,
    String? mealType,
    DateTime? datetime,
  }) {
    return NutritionModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      servingSize: servingSize ?? this.servingSize,
      servingCount: servingCount ?? this.servingCount,
      servingUnit: servingUnit ?? this.servingUnit,
      additionalNutrients: additionalNutrients ?? this.additionalNutrients,
      notes: notes ?? this.notes,
      mealType: mealType ?? this.mealType,
      datetime: datetime ?? this.datetime,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Create from a common food entry
  factory NutritionModel.fromCommonFood({
    required String userId,
    required String foodKey,
    int servingCount = 1,
    String? notes,
    String? mealType,
    DateTime? datetime,
  }) {
    final now = DateTime.now();
    
    // Check if the food exists in the common foods database
    if (!AppConstants.commonFoodNutrition.containsKey(foodKey)) {
      throw ArgumentError('Food not found in database: $foodKey');
    }
    
    final foodData = AppConstants.commonFoodNutrition[foodKey]!;
    
    return NutritionModel(
      id: FirebaseFirestore.instance.collection('nutrition').doc().id,
      userId: userId,
      name: foodKey,
      category: 'common food',
      calories: (foodData['calories'] as num).toInt() * servingCount,
      proteins: (foodData['protein'] as num).toDouble() * servingCount,
      carbs: (foodData['carbs'] as num).toDouble() * servingCount,
      fats: (foodData['fat'] as num).toDouble() * servingCount,
      servingCount: servingCount,
      notes: notes,
      mealType: mealType,
      datetime: datetime ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Calculate total macronutrients in grams
  double get totalMacros => proteins + carbs + fats;

  // Calculate macronutrient percentages
  double get proteinPercentage => totalMacros > 0 ? (proteins / totalMacros) * 100 : 0;
  double get carbPercentage => totalMacros > 0 ? (carbs / totalMacros) * 100 : 0;
  double get fatPercentage => totalMacros > 0 ? (fats / totalMacros) * 100 : 0;

  // Calculate calories from each macronutrient
  int get proteinCalories => (proteins * 4).round();
  int get carbCalories => (carbs * 4).round();
  int get fatCalories => (fats * 9).round();

  // Get a formatted date
  String getFormattedDate() {
    return DateFormat('MMM d, yyyy').format(datetime);
  }

  // Get a formatted time
  String getFormattedTime() {
    return DateFormat('h:mm a').format(datetime);
  }

  // Get a formatted serving description
  String? getFormattedServing() {
    if (servingCount == null) return null;
    
    if (servingSize != null && servingUnit != null) {
      return '$servingCount × ${servingSize}$servingUnit';
    } else if (servingUnit != null) {
      return '$servingCount $servingUnit';
    } else {
      return '$servingCount serving(s)';
    }
  }

  // Validate the nutrition entry
  bool isValid() {
    return name.isNotEmpty && 
           calories >= 0 &&
           proteins >= 0 &&
           carbs >= 0 &&
           fats >= 0;
  }
}