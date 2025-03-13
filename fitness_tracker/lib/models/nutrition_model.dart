import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

/// Represents a food or nutrition entry in the fitness tracking app
class NutritionModel {
  final String? id;
  final String userId;
  final String name;
  final String category; // fruits, vegetables, grains, protein, etc.
  final int calories;
  final int protein; // in grams
  final int carbs; // in grams
  final int fat; // in grams
  final int? sugar; // in grams
  final int? fiber; // in grams
  final int? sodium; // in milligrams
  final double? servingSize; // in grams or milliliters
  final String? servingUnit; // g, ml, oz, etc.
  final int? servingCount;
  final String? mealType; // breakfast, lunch, dinner, snack
  final DateTime date;
  final String? notes;
  final Map<String, dynamic>? additionalNutrients;

  NutritionModel({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar,
    this.fiber,
    this.sodium,
    this.servingSize,
    this.servingUnit,
    this.servingCount,
    this.mealType,
    required this.date,
    this.notes,
    this.additionalNutrients,
  });

  /// Create a NutritionModel from a map (typically from Firestore)
  factory NutritionModel.fromMap(Map<String, dynamic> map, String id) {
    return NutritionModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? FoodCategories.other,
      calories: map['calories']?.toInt() ?? 0,
      protein: map['protein']?.toInt() ?? 0,
      carbs: map['carbs']?.toInt() ?? 0,
      fat: map['fat']?.toInt() ?? 0,
      sugar: map['sugar']?.toInt(),
      fiber: map['fiber']?.toInt(),
      sodium: map['sodium']?.toInt(),
      servingSize: map['servingSize']?.toDouble(),
      servingUnit: map['servingUnit'],
      servingCount: map['servingCount']?.toInt(),
      mealType: map['mealType'],
      date: map['date'] != null 
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      notes: map['notes'],
      additionalNutrients: map['additionalNutrients'],
    );
  }

  /// Convert this NutritionModel to a map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'sodium': sodium,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'servingCount': servingCount,
      'mealType': mealType,
      'date': date,
      'notes': notes,
      'additionalNutrients': additionalNutrients,
    };
  }

  /// Create a copy of this NutritionModel with some values replaced
  NutritionModel copyWith({
    String? userId,
    String? name,
    String? category,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? sugar,
    int? fiber,
    int? sodium,
    double? servingSize,
    String? servingUnit,
    int? servingCount,
    String? mealType,
    DateTime? date,
    String? notes,
    Map<String, dynamic>? additionalNutrients,
  }) {
    return NutritionModel(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      servingCount: servingCount ?? this.servingCount,
      mealType: mealType ?? this.mealType,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      additionalNutrients: additionalNutrients ?? this.additionalNutrients,
    );
  }

  /// Get a formatted date string
  String getFormattedDate([String format = DateTimeFormats.monthDayYear]) {
    return DateFormat(format).format(date);
  }

  /// Get the macronutrient ratio (protein:carbs:fat)
  String getMacroRatio() {
    final total = protein + carbs + fat;
    if (total <= 0) return '0:0:0';
    
    final proteinPercent = (protein / total * 100).round();
    final carbsPercent = (carbs / total * 100).round();
    final fatPercent = (fat / total * 100).round();
    
    return '$proteinPercent:$carbsPercent:$fatPercent';
  }

  /// Get the serving description
  String? getServingDescription() {
    if (servingSize == null || servingUnit == null) return null;
    
    final count = servingCount != null && servingCount! > 1 
        ? '${servingCount!} servings of ' 
        : '';
    
    return '$count$servingSize $servingUnit';
  }

  /// Calculate calories from macronutrients
  int calculateCaloriesFromMacros() {
    // 1g protein = 4 calories, 1g carbs = 4 calories, 1g fat = 9 calories
    return protein * 4 + carbs * 4 + fat * 9;
  }

  /// Check if the nutritional values match the macronutrient calorie count
  bool isCalorieMatchingMacros([int tolerance = 20]) {
    final calculatedCalories = calculateCaloriesFromMacros();
    return (calculatedCalories - calories).abs() <= tolerance;
  }

  /// Check if the nutrition entry is valid
  bool isValid() {
    return name.isNotEmpty && 
           calories >= 0 && 
           protein >= 0 && 
           carbs >= 0 && 
           fat >= 0;
  }
}

/// Extension for operations on lists of NutritionModel objects
extension NutritionModelListExtension on List<NutritionModel> {
  /// Sort nutrition entries by date (most recent first)
  List<NutritionModel> sortByDateDescending() {
    return [...this]..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Sort nutrition entries by date (oldest first)
  List<NutritionModel> sortByDateAscending() {
    return [...this]..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Filter nutrition entries by category
  List<NutritionModel> filterByCategory(String category) {
    return where((entry) => entry.category == category).toList();
  }

  /// Filter nutrition entries by meal type
  List<NutritionModel> filterByMealType(String mealType) {
    return where((entry) => entry.mealType == mealType).toList();
  }

  /// Filter nutrition entries by date range
  List<NutritionModel> filterByDateRange(DateTime startDate, DateTime endDate) {
    return where((entry) => 
      entry.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
      entry.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  /// Get total calories
  int getTotalCalories() {
    return fold(0, (sum, entry) => sum + entry.calories);
  }

  /// Get total protein in grams
  int getTotalProtein() {
    return fold(0, (sum, entry) => sum + entry.protein);
  }

  /// Get total carbs in grams
  int getTotalCarbs() {
    return fold(0, (sum, entry) => sum + entry.carbs);
  }

  /// Get total fat in grams
  int getTotalFat() {
    return fold(0, (sum, entry) => sum + entry.fat);
  }

  /// Get average macronutrient ratio
  String getAverageMacroRatio() {
    final totalProtein = getTotalProtein();
    final totalCarbs = getTotalCarbs();
    final totalFat = getTotalFat();
    
    final total = totalProtein + totalCarbs + totalFat;
    if (total <= 0) return '0:0:0';
    
    final proteinPercent = (totalProtein / total * 100).round();
    final carbsPercent = (totalCarbs / total * 100).round();
    final fatPercent = (totalFat / total * 100).round();
    
    return '$proteinPercent:$carbsPercent:$fatPercent';
  }

  /// Group nutrition entries by meal type and count calories
  Map<String, int> getCaloriesByMealType() {
    final result = <String, int>{};
    for (final entry in this) {
      if (entry.mealType != null) {
        result[entry.mealType!] = (result[entry.mealType!] ?? 0) + entry.calories;
      }
    }
    return result;
  }

  /// Get nutrition entries grouped by day
  Map<DateTime, List<NutritionModel>> groupByDay() {
    final result = <DateTime, List<NutritionModel>>{};
    for (final entry in this) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!result.containsKey(day)) {
        result[day] = [];
      }
      result[day]!.add(entry);
    }
    return result;
  }
}