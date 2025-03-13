import 'package:intl/intl.dart';

class FoodEntry {
  final String? id; // Firestore document ID (null for new entries)
  final String name;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final int calories;
  final double? protein; // in grams
  final double? carbs; // in grams
  final double? fat; // in grams
  final DateTime date;
  final String userId; // Reference to user who logged this food

  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch', 
    'Dinner', 
    'Snack'
  ];

  FoodEntry({
    this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.date,
    required this.userId,
  });

  // Check if food entry has valid data
  bool isValid() {
    return name.isNotEmpty && 
           mealTypes.contains(mealType) && 
           calories >= 0;
  }

  // Get formatted date string
  String getFormattedDate() {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  // Get macronutrient percentages
  Map<String, double> get macroPercentages {
    double totalGrams = 0;
    
    // Calculate total macronutrient grams
    if (protein != null) totalGrams += protein!;
    if (carbs != null) totalGrams += carbs!;
    if (fat != null) totalGrams += fat!;
    
    if (totalGrams == 0) {
      return {
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
    }
    
    return {
      'protein': protein != null ? protein! / totalGrams : 0,
      'carbs': carbs != null ? carbs! / totalGrams : 0,
      'fat': fat != null ? fat! / totalGrams : 0,
    };
  }

  // Convert Firestore data to FoodEntry
  factory FoodEntry.fromMap(String id, Map<String, dynamic> data) {
    return FoodEntry(
      id: id,
      name: data['name'] ?? '',
      mealType: data['meal_type'] ?? 'Snack',
      calories: data['calories'] ?? 0,
      protein: data['protein']?.toDouble(),
      carbs: data['carbs']?.toDouble(),
      fat: data['fat']?.toDouble(),
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      userId: data['user_id'] ?? '',
    );
  }

  // Convert FoodEntry to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'meal_type': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': date,
      'user_id': userId,
    };
  }

  // Copy with method for updating food entry properties
  FoodEntry copyWith({
    String? name,
    String? mealType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? date,
    String? userId,
  }) {
    return FoodEntry(
      id: this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      date: date ?? this.date,
      userId: userId ?? this.userId,
    );
  }
}

class NutritionSummary {
  final int totalCalories;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final Map<String, int> caloriesByMeal;
  
  NutritionSummary({
    required this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    required this.caloriesByMeal,
  });
  
  // Calculate summary from a list of food entries
  factory NutritionSummary.fromEntries(List<FoodEntry> entries) {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    Map<String, int> caloriesByMeal = {
      'Breakfast': 0,
      'Lunch': 0,
      'Dinner': 0,
      'Snack': 0,
    };
    
    for (var entry in entries) {
      totalCalories += entry.calories;
      if (entry.protein != null) totalProtein += entry.protein!;
      if (entry.carbs != null) totalCarbs += entry.carbs!;
      if (entry.fat != null) totalFat += entry.fat!;
      
      caloriesByMeal[entry.mealType] = 
          (caloriesByMeal[entry.mealType] ?? 0) + entry.calories;
    }
    
    return NutritionSummary(
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      caloriesByMeal: caloriesByMeal,
    );
  }
  
  // Get nutrient distribution percentages
  Map<String, double> get macroDistribution {
    double totalGrams = 0;
    
    // Calculate total macronutrient grams
    if (totalProtein != null) totalGrams += totalProtein!;
    if (totalCarbs != null) totalGrams += totalCarbs!;
    if (totalFat != null) totalGrams += totalFat!;
    
    if (totalGrams == 0) {
      return {
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
    }
    
    return {
      'protein': totalProtein != null ? totalProtein! / totalGrams : 0,
      'carbs': totalCarbs != null ? totalCarbs! / totalGrams : 0,
      'fat': totalFat != null ? totalFat! / totalGrams : 0,
    };
  }
  
  // Get meal distribution percentages
  Map<String, double> get mealDistribution {
    if (totalCalories == 0) {
      return {
        'Breakfast': 0,
        'Lunch': 0,
        'Dinner': 0,
        'Snack': 0,
      };
    }
    
    return {
      'Breakfast': caloriesByMeal['Breakfast']! / totalCalories,
      'Lunch': caloriesByMeal['Lunch']! / totalCalories,
      'Dinner': caloriesByMeal['Dinner']! / totalCalories,
      'Snack': caloriesByMeal['Snack']! / totalCalories,
    };
  }
}