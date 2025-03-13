import 'package:flutter/material.dart';

/// Application colors
class AppColors {
  // Primary and secondary colors
  static const primary = Color(0xFF4A90E2);
  static const secondary = Color(0xFF50E3C2);
  static const accent = Color(0xFFFFA726);
  
  // Background colors
  static const background = Color(0xFFF5F7FA);
  static const cardBackground = Colors.white;
  
  // Status colors
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFF1C40F);
  static const error = Color(0xFFE74C3C);
  static const info = Color(0xFF3498DB);
  
  // Text colors
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);
  static const textLight = Color(0xFFBDC3C7);
}

/// Text styles used across the app
class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

/// Common dimensions and spacing
class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusExtraLarge = 16.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
}

/// Activity types
class ActivityTypes {
  static const String running = "running";
  static const String walking = "walking";
  static const String cycling = "cycling";
  static const String swimming = "swimming";
  static const String gymWorkout = "gym_workout";
  static const String hiit = "hiit";
  static const String yoga = "yoga";
  static const String other = "other";
  
  static List<String> get all => [
    running, 
    walking, 
    cycling, 
    swimming, 
    gymWorkout, 
    hiit, 
    yoga, 
    other
  ];
  
  static IconData getIconForType(String type) {
    switch (type) {
      case running: return Icons.directions_run;
      case walking: return Icons.directions_walk;
      case cycling: return Icons.directions_bike;
      case swimming: return Icons.pool;
      case gymWorkout: return Icons.fitness_center;
      case hiit: return Icons.timer;
      case yoga: return Icons.self_improvement;
      default: return Icons.sports;
    }
  }
  
  static String getDisplayName(String type) {
    switch (type) {
      case running: return "Running";
      case walking: return "Walking";
      case cycling: return "Cycling";
      case swimming: return "Swimming";
      case gymWorkout: return "Gym Workout";
      case hiit: return "HIIT";
      case yoga: return "Yoga";
      default: return "Other";
    }
  }
  
  static Color getColorForType(String type) {
    switch (type) {
      case running: return Colors.orangeAccent;
      case walking: return Colors.lightGreen;
      case cycling: return Colors.blueAccent;
      case swimming: return Colors.lightBlueAccent;
      case gymWorkout: return Colors.redAccent;
      case hiit: return Colors.deepPurpleAccent;
      case yoga: return Colors.tealAccent;
      default: return Colors.grey;
    }
  }
}

/// Nutrition categories
class FoodCategories {
  static const String fruits = "fruits";
  static const String vegetables = "vegetables";
  static const String grains = "grains";
  static const String protein = "protein";
  static const String dairy = "dairy";
  static const String snacks = "snacks";
  static const String beverages = "beverages";
  static const String other = "other";
  
  static List<String> get all => [
    fruits, 
    vegetables, 
    grains, 
    protein, 
    dairy, 
    snacks, 
    beverages, 
    other
  ];
  
  static IconData getIconForCategory(String category) {
    switch (category) {
      case fruits: return Icons.apple;
      case vegetables: return Icons.eco;
      case grains: return Icons.rice_bowl;
      case protein: return Icons.egg;
      case dairy: return Icons.icecream;
      case snacks: return Icons.cookie;
      case beverages: return Icons.local_drink;
      default: return Icons.restaurant;
    }
  }
  
  static String getDisplayName(String category) {
    switch (category) {
      case fruits: return "Fruits";
      case vegetables: return "Vegetables";
      case grains: return "Grains";
      case protein: return "Protein";
      case dairy: return "Dairy";
      case snacks: return "Snacks";
      case beverages: return "Beverages";
      default: return "Other";
    }
  }
  
  static Color getColorForCategory(String category) {
    switch (category) {
      case fruits: return Colors.redAccent;
      case vegetables: return Colors.greenAccent;
      case grains: return Colors.amberAccent;
      case protein: return Colors.deepOrangeAccent;
      case dairy: return Colors.lightBlueAccent;
      case snacks: return Colors.purpleAccent;
      case beverages: return Colors.blueAccent;
      default: return Colors.grey;
    }
  }
}

/// Date and time formatting constants
class DateTimeFormats {
  static const String dateOnly = 'yyyy-MM-dd';
  static const String timeOnly = 'HH:mm';
  static const String dateAndTime = 'yyyy-MM-dd HH:mm';
  static const String monthDay = 'MMM dd';
  static const String dayMonth = 'dd MMM';
  static const String monthDayYear = 'MMM dd, yyyy';
  static const String dayOfWeek = 'EEEE';
}

/// App-wide shared preferences keys
class AppPreferenceKeys {
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String isDarkMode = 'is_dark_mode';
  static const String dailyCalorieGoal = 'daily_calorie_goal';
  static const String dailyStepGoal = 'daily_step_goal';
  static const String dailyWaterGoal = 'daily_water_goal';
  static const String lastSyncTime = 'last_sync_time';
  static const String useBiometrics = 'use_biometrics';
}

/// Shared validation functions
class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  static bool isValidName(String name) {
    return name.isNotEmpty && name.trim().length >= 2;
  }
  
  static bool isPositiveNumber(num? value) {
    return value != null && value > 0;
  }
  
  static bool isNonNegativeNumber(num? value) {
    return value != null && value >= 0;
  }
}