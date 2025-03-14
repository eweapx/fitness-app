class AppConstants {
  static const String appName = 'Fitness Tracker';
  
  // Firebase collection names
  static const String usersCollection = 'users';
  static const String activitiesCollection = 'activities';
  static const String nutritionCollection = 'nutrition';
  static const String sleepCollection = 'sleep';
  static const String settingsCollection = 'settings';
  
  // Activity types
  static const List<String> activityTypes = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Weightlifting',
    'Yoga',
    'HIIT',
    'Pilates',
    'Hiking',
    'Other',
  ];
  
  // Nutrition meal types
  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];
  
  // Default daily goals
  static const int defaultStepsGoal = 10000;
  static const int defaultCaloriesGoal = 2000;
  static const int defaultWaterGoal = 8;  // in cups
  static const double defaultSleepGoal = 8.0;  // in hours
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Min/max values for health metrics
  static const double minHeight = 120.0;  // in cm
  static const double maxHeight = 250.0;  // in cm
  static const double minWeight = 30.0;   // in kg
  static const double maxWeight = 300.0;  // in kg
  static const int minAge = 13;
  static const int maxAge = 120;
}