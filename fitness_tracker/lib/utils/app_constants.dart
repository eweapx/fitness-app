/// Application-wide constants for consistent configuration
class AppConstants {
  // General app configuration
  static const String appName = 'Fitness Tracker';
  static const String appVersion = '1.0.0';
  
  // API endpoints and configuration
  static const String apiBaseUrl = 'https://api.fitnesstracker.com';
  static const int apiTimeoutSeconds = 30;
  
  // Default values and limits
  static const int defaultWaterGoalMl = 2500;
  static const int minWaterGoalMl = 500;
  static const int maxWaterGoalMl = 5000;
  
  static const int defaultStepGoal = 10000;
  static const int minStepGoal = 1000;
  static const int maxStepGoal = 50000;
  
  static const int defaultCalorieGoal = 2000;
  static const int minCalorieGoal = 1200;
  static const int maxCalorieGoal = 5000;
  
  static const int defaultSleepGoalHours = 8;
  static const int minSleepGoalHours = 4;
  static const int maxSleepGoalHours = 12;
  
  static const double defaultWeightKg = 70.0;
  static const double minWeightKg = 30.0;
  static const double maxWeightKg = 300.0;
  
  static const double defaultHeightCm = 170.0;
  static const double minHeightCm = 100.0;
  static const double maxHeightCm = 250.0;
  
  // Exercise MET values (Metabolic Equivalent of Task)
  static const Map<String, double> exerciseMetValues = {
    'walking (slow)': 2.5,
    'walking (moderate)': 3.5,
    'walking (brisk)': 5.0,
    'running (slow)': 8.0,
    'running (moderate)': 11.5,
    'running (fast)': 14.0,
    'cycling (slow)': 4.0,
    'cycling (moderate)': 8.0,
    'cycling (fast)': 12.0,
    'swimming (light)': 6.0,
    'swimming (moderate)': 8.0,
    'swimming (vigorous)': 10.0,
    'weight training (light)': 3.5,
    'weight training (moderate)': 5.0,
    'weight training (vigorous)': 6.0,
    'yoga': 2.5,
    'pilates': 3.0,
    'dancing': 4.5,
    'basketball': 6.5,
    'soccer': 7.0,
    'tennis': 6.0,
    'hiking': 5.5,
    'elliptical trainer': 5.0,
    'stair stepper': 8.0,
    'rowing machine': 7.0,
    'jump rope': 10.0,
    'gardening': 3.5,
  };
  
  // Nutrition data
  static const Map<String, Map<String, double>> commonFoodNutrition = {
    'apple': {'calories': 95, 'protein': 0.5, 'carbs': 25, 'fat': 0.3},
    'banana': {'calories': 105, 'protein': 1.3, 'carbs': 27, 'fat': 0.4},
    'chicken breast': {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6},
    'salmon': {'calories': 206, 'protein': 22, 'carbs': 0, 'fat': 13},
    'rice': {'calories': 206, 'protein': 4.3, 'carbs': 45, 'fat': 0.4},
    'bread': {'calories': 79, 'protein': 3.1, 'carbs': 14, 'fat': 1.1},
    'egg': {'calories': 78, 'protein': 6.3, 'carbs': 0.6, 'fat': 5.3},
    'milk': {'calories': 103, 'protein': 8, 'carbs': 12, 'fat': 2.4},
    'avocado': {'calories': 234, 'protein': 2.9, 'carbs': 12, 'fat': 21},
    'broccoli': {'calories': 31, 'protein': 2.5, 'carbs': 6, 'fat': 0.3},
  };
  
  // App settings defaults
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultDarkModeEnabled = false;
  static const bool defaultUseMetricSystem = true;
  static const String defaultReminderTime = '08:00';
  
  // Storage keys
  static const String userProfileKey = 'user_profile';
  static const String settingsKey = 'app_settings';
  static const String activitiesKey = 'activities';
  static const String nutritionKey = 'nutrition_logs';
  static const String sleepKey = 'sleep_logs';
  static const String weightKey = 'weight_logs';
  static const String waterKey = 'water_logs';
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Lists of option values
  static const List<String> activityTypes = [
    'walking', 
    'running', 
    'cycling', 
    'swimming', 
    'weight training', 
    'yoga', 
    'pilates', 
    'dancing', 
    'basketball', 
    'soccer', 
    'tennis', 
    'hiking', 
    'elliptical', 
    'rowing', 
    'other'
  ];
  
  static const List<String> genderOptions = [
    'male',
    'female',
    'other',
    'prefer not to say'
  ];
  
  static const List<String> activityLevels = [
    'sedentary',
    'light',
    'moderate',
    'active',
    'very active'
  ];
  
  static const List<String> fitnessGoals = [
    'weight loss',
    'muscle gain',
    'maintenance',
    'general fitness',
    'endurance',
    'strength',
    'flexibility'
  ];
  
  // Regex patterns for validation
  static const String emailPattern = 
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String passwordPattern = 
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$';
  static const String namePattern = 
    r'^[a-zA-Z ]{2,50}$';
}