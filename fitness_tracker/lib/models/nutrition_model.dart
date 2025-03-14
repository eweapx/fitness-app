import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different types of meals
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  other
}

/// Extension to provide helper methods for MealType enum
extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
      case MealType.other:
        return 'Other';
    }
  }
  
  String get icon {
    switch (this) {
      case MealType.breakfast:
        return 'free_breakfast';
      case MealType.lunch:
        return 'lunch_dining';
      case MealType.dinner:
        return 'dinner_dining';
      case MealType.snack:
        return 'bakery_dining';
      case MealType.other:
        return 'restaurant';
    }
  }
  
  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (type) => type.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => MealType.other,
    );
  }
}

/// Enum for food categories
enum FoodCategory {
  fruits,
  vegetables,
  grains,
  protein,
  dairy,
  sweets,
  beverages,
  other
}

/// Extension methods for FoodCategory
extension FoodCategoryExtension on FoodCategory {
  String get displayName {
    switch (this) {
      case FoodCategory.fruits:
        return 'Fruits';
      case FoodCategory.vegetables:
        return 'Vegetables';
      case FoodCategory.grains:
        return 'Grains';
      case FoodCategory.protein:
        return 'Protein';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.sweets:
        return 'Sweets';
      case FoodCategory.beverages:
        return 'Beverages';
      case FoodCategory.other:
        return 'Other';
    }
  }
  
  static FoodCategory fromString(String value) {
    return FoodCategory.values.firstWhere(
      (category) => category.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => FoodCategory.other,
    );
  }
}

/// Model class for food items
class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double? protein; // in grams
  final double? carbs; // in grams
  final double? fat; // in grams
  final double? fiber; // in grams
  final double? sugar; // in grams
  final FoodCategory category;
  final String? servingSize;
  final double? servingWeight; // in grams
  final Map<String, dynamic>? nutrients;
  final String? barcode;
  final String? imageUrl;
  final bool isCustom;
  
  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    required this.category,
    this.servingSize,
    this.servingWeight,
    this.nutrients,
    this.barcode,
    this.imageUrl,
    this.isCustom = false,
  });
  
  /// Create a FoodItem from Firestore document
  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      calories: data['calories'] ?? 0,
      protein: data['protein']?.toDouble(),
      carbs: data['carbs']?.toDouble(),
      fat: data['fat']?.toDouble(),
      fiber: data['fiber']?.toDouble(),
      sugar: data['sugar']?.toDouble(),
      category: FoodCategoryExtension.fromString(data['category'] ?? 'other'),
      servingSize: data['servingSize'],
      servingWeight: data['servingWeight']?.toDouble(),
      nutrients: data['nutrients'],
      barcode: data['barcode'],
      imageUrl: data['imageUrl'],
      isCustom: data['isCustom'] ?? false,
    );
  }
  
  /// Convert FoodItem to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'category': category.toString().split('.').last,
      'servingSize': servingSize,
      'servingWeight': servingWeight,
      'nutrients': nutrients,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'isCustom': isCustom,
    };
  }
  
  /// Create a copy with updated fields
  FoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    FoodCategory? category,
    String? servingSize,
    double? servingWeight,
    Map<String, dynamic>? nutrients,
    String? barcode,
    String? imageUrl,
    bool? isCustom,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      category: category ?? this.category,
      servingSize: servingSize ?? this.servingSize,
      servingWeight: servingWeight ?? this.servingWeight,
      nutrients: nutrients ?? this.nutrients,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// Model for logged meals
class MealEntry {
  final String id;
  final String userId;
  final DateTime dateTime;
  final MealType mealType;
  final List<MealFoodItem> foodItems;
  final int totalCalories;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final String? notes;
  final String? imageUrl;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  MealEntry({
    required this.id,
    required this.userId,
    required this.dateTime,
    required this.mealType,
    required this.foodItems,
    required this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    this.notes,
    this.imageUrl,
    this.isSynced = false,
    required this.createdAt,
    this.updatedAt,
  });
  
  /// Create a MealEntry from Firestore document
  factory MealEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final List<MealFoodItem> foodItems = [];
    if (data['foodItems'] != null) {
      for (var item in (data['foodItems'] as List)) {
        foodItems.add(MealFoodItem.fromMap(item));
      }
    }
    
    return MealEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      mealType: MealTypeExtension.fromString(data['mealType'] ?? 'other'),
      foodItems: foodItems,
      totalCalories: data['totalCalories'] ?? 0,
      totalProtein: data['totalProtein']?.toDouble(),
      totalCarbs: data['totalCarbs']?.toDouble(),
      totalFat: data['totalFat']?.toDouble(),
      notes: data['notes'],
      imageUrl: data['imageUrl'],
      isSynced: data['isSynced'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }
  
  /// Convert MealEntry to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'dateTime': Timestamp.fromDate(dateTime),
      'mealType': mealType.toString().split('.').last,
      'foodItems': foodItems.map((item) => item.toMap()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'notes': notes,
      'imageUrl': imageUrl,
      'isSynced': isSynced,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

/// Model for food items within a meal
class MealFoodItem {
  final String foodItemId;
  final String name;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double servingSize;
  final String? servingSizeUnit;
  final double quantity;
  final String? notes;
  
  MealFoodItem({
    required this.foodItemId,
    required this.name,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.servingSize,
    this.servingSizeUnit,
    required this.quantity,
    this.notes,
  });
  
  /// Create a MealFoodItem from a map
  factory MealFoodItem.fromMap(Map<String, dynamic> map) {
    return MealFoodItem(
      foodItemId: map['foodItemId'] ?? '',
      name: map['name'] ?? '',
      calories: map['calories'] ?? 0,
      protein: map['protein']?.toDouble(),
      carbs: map['carbs']?.toDouble(),
      fat: map['fat']?.toDouble(),
      servingSize: map['servingSize']?.toDouble() ?? 1.0,
      servingSizeUnit: map['servingSizeUnit'],
      quantity: map['quantity']?.toDouble() ?? 1.0,
      notes: map['notes'],
    );
  }
  
  /// Convert MealFoodItem to a map
  Map<String, dynamic> toMap() {
    return {
      'foodItemId': foodItemId,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
      'servingSizeUnit': servingSizeUnit,
      'quantity': quantity,
      'notes': notes,
    };
  }
  
  /// Get the total calories for this food item with quantity applied
  int get totalCalories => (calories * quantity).round();
  
  /// Get the total protein for this food item with quantity applied
  double? get totalProtein => protein != null ? protein! * quantity : null;
  
  /// Get the total carbs for this food item with quantity applied
  double? get totalCarbs => carbs != null ? carbs! * quantity : null;
  
  /// Get the total fat for this food item with quantity applied
  double? get totalFat => fat != null ? fat! * quantity : null;
}