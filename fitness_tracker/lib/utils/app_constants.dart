/// Constants used throughout the app
class AppConstants {
  // App info
  static const String appName = 'Health & Fitness Tracker';
  static const String appVersion = '1.0.0';
  
  // Shared preferences keys
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefUserID = 'user_id';
  static const String prefUserName = 'user_name';
  static const String prefUserEmail = 'user_email';
  static const String prefUserPhoto = 'user_photo';
  static const String prefThemeMode = 'theme_mode';
  static const String prefUseMetric = 'use_metric';
  static const String prefWeightUnit = 'weight_unit';
  static const String prefHeightUnit = 'height_unit';
  static const String prefDistanceUnit = 'distance_unit';
  static const String prefVolumeUnit = 'volume_unit';
  static const String prefReminderEnabled = 'reminder_enabled';
  static const String prefReminderTime = 'reminder_time';
  static const String prefWaterGoal = 'water_goal';
  static const String prefCalorieGoal = 'calorie_goal';
  static const String prefStepGoal = 'step_goal';
  static const String prefSleepGoal = 'sleep_goal';
  
  // Default values
  static const int defaultWaterGoal = 2500; // mL
  static const int defaultCalorieGoal = 2000; // calories
  static const int defaultStepGoal = 10000; // steps
  static const int defaultSleepGoal = 480; // minutes (8 hours)
  
  // Units
  static const String unitKg = 'kg';
  static const String unitLbs = 'lbs';
  static const String unitCm = 'cm';
  static const String unitFt = 'ft';
  static const String unitKm = 'km';
  static const String unitMi = 'mi';
  static const String unitMl = 'mL';
  static const String unitOz = 'oz';
  
  // Conversion factors
  static const double kgToLbs = 2.20462;
  static const double lbsToKg = 0.453592;
  static const double cmToFt = 0.0328084;
  static const double ftToCm = 30.48;
  static const double kmToMi = 0.621371;
  static const double miToKm = 1.60934;
  static const double mlToOz = 0.033814;
  static const double ozToMl = 29.5735;
  
  // Firestore collections
  static const String collectionUsers = 'users';
  static const String collectionActivities = 'activities';
  static const String collectionMeals = 'meals';
  static const String collectionFoodItems = 'food_items';
  static const String collectionSleep = 'sleep';
  static const String collectionHabits = 'habits';
  static const String collectionSettings = 'settings';
  
  // Notification channels
  static const String notificationChannelGeneral = 'general';
  static const String notificationChannelReminders = 'reminders';
  static const String notificationChannelActivities = 'activities';
  static const String notificationChannelWater = 'water';
  static const String notificationChannelMeals = 'meals';
  
  // URLs
  static const String termsUrl = 'https://example.com/terms';
  static const String privacyUrl = 'https://example.com/privacy';
  static const String supportUrl = 'https://example.com/support';
  static const String faqUrl = 'https://example.com/faq';
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Avatar placeholders
  static const String defaultAvatarUrl = 'assets/images/default_avatar.png';
  
  // Asset paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String animationPath = 'assets/animations/';
}