import 'package:flutter/material.dart';

// App theme colors
class AppColors {
  static const primary = Colors.blue;
  static const secondary = Colors.lightBlue;
  static const accent = Colors.orangeAccent;
  static const background = Color(0xFFF5F5F5);
  static const card = Colors.white;
  static const text = Color(0xFF333333);
  static const textLight = Color(0xFF767676);
  static const error = Colors.redAccent;
  static const success = Colors.greenAccent;
  static const warning = Colors.orangeAccent;
  static const info = Colors.lightBlueAccent;
  
  // Activity type colors
  static const Map<String, Color> activityColors = {
    'Running': Colors.green,
    'Walking': Colors.lightGreen,
    'Cycling': Colors.orange,
    'Swimming': Colors.blue,
    'Strength': Colors.red,
    'Yoga': Colors.purple,
    'HIIT': Colors.pink,
    'Other': Colors.grey,
  };
  
  // Meal type colors
  static const Map<String, Color> mealColors = {
    'Breakfast': Colors.orange,
    'Lunch': Colors.green,
    'Dinner': Colors.blue,
    'Snack': Colors.purple,
  };
  
  // Macro colors
  static const protein = Colors.green;
  static const carbs = Colors.orange;
  static const fat = Colors.red;
}

// App text styles
class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  
  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  
  static const heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  
  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );
  
  static const caption = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );
  
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

// Activity types and icons
class ActivityTypes {
  static const List<Map<String, dynamic>> types = [
    {'name': 'Running', 'icon': Icons.directions_run},
    {'name': 'Walking', 'icon': Icons.directions_walk},
    {'name': 'Cycling', 'icon': Icons.directions_bike},
    {'name': 'Swimming', 'icon': Icons.pool},
    {'name': 'Strength', 'icon': Icons.fitness_center},
    {'name': 'Yoga', 'icon': Icons.self_improvement},
    {'name': 'HIIT', 'icon': Icons.timer},
    {'name': 'Other', 'icon': Icons.sports},
  ];
  
  static IconData getIconForType(String type) {
    final activityType = types.firstWhere(
      (element) => element['name'] == type,
      orElse: () => types.last,
    );
    return activityType['icon'];
  }
}

// Meal types and icons
class MealTypes {
  static const List<Map<String, dynamic>> types = [
    {'name': 'Breakfast', 'icon': Icons.free_breakfast},
    {'name': 'Lunch', 'icon': Icons.lunch_dining},
    {'name': 'Dinner', 'icon': Icons.dinner_dining},
    {'name': 'Snack', 'icon': Icons.local_cafe},
  ];
  
  static IconData getIconForType(String type) {
    final mealType = types.firstWhere(
      (element) => element['name'] == type,
      orElse: () => types.last,
    );
    return mealType['icon'];
  }
}

// App routes
class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const activity = '/activity';
  static const addActivity = '/add-activity';
  static const activityDetails = '/activity-details';
  static const nutrition = '/nutrition';
  static const addFoodEntry = '/add-food-entry';
  static const foodEntryDetails = '/food-entry-details';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
}

// App constants
class AppConstants {
  // Default activity durations in minutes
  static const List<int> defaultDurations = [15, 30, 45, 60, 90, 120];
  
  // Default calorie goals
  static const int defaultCalorieGoal = 2200;
  
  // Default nutrient percentages
  static const Map<String, double> defaultMacroPercentages = {
    'protein': 0.30,
    'carbs': 0.45,
    'fat': 0.25,
  };
  
  // Health data type names
  static const String stepsDataType = 'steps';
  static const String caloriesDataType = 'calories';
  static const String distanceDataType = 'distance';
  static const String activeEnergyDataType = 'activeEnergy';
}

// Date helper functions
class DateUtils {
  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final day = date.weekday;
    return DateTime(date.year, date.month, date.day - (day - 1));
  }
  
  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final day = date.weekday;
    return DateTime(date.year, date.month, date.day + (7 - day), 23, 59, 59);
  }
  
  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }
  
  // Format date for display
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Format time for display
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Format duration in minutes to hours and minutes
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}