import 'package:flutter/material.dart';

// App Information
const String appName = 'Fitness Tracker';
const String appVersion = '1.0.0';

// API Endpoints
const String apiBaseUrl = 'https://api.fitness-tracker.com';

// Theme Colors
const Color primaryColor = Color(0xFF4CAF50);
const Color accentColor = Color(0xFF2196F3);
const Color errorColor = Color(0xFFE53935);
const Color warningColor = Color(0xFFFF9800);
const Color successColor = Color(0xFF43A047);
const Color textPrimaryColor = Color(0xFF212121);
const Color textSecondaryColor = Color(0xFF757575);
const Color backgroundLightColor = Color(0xFFF5F5F5);
const Color backgroundDarkColor = Color(0xFF303030);

// App Dimensions
const double appBarHeight = 56.0;
const double defaultPadding = 16.0;
const double smallPadding = 8.0;
const double largePadding = 24.0;
const double borderRadius = 8.0;
const double buttonHeight = 48.0;
const double iconSize = 24.0;
const double avatarSize = 40.0;

// Animation Durations
const Duration shortAnimationDuration = Duration(milliseconds: 150);
const Duration mediumAnimationDuration = Duration(milliseconds: 300);
const Duration longAnimationDuration = Duration(milliseconds: 500);

// Storage Keys
const String tokenKey = 'auth_token';
const String userIdKey = 'user_id';
const String rememberMeKey = 'remember_me';
const String themeKey = 'app_theme';
const String languageKey = 'app_language';
const String unitSystemKey = 'unit_system';

// Feature Flags
const bool enablePushNotifications = true;
const bool enableLocationServices = true;
const bool enableDarkMode = true;

// Activity Types
const List<String> activityTypes = [
  'Running',
  'Walking',
  'Cycling',
  'Swimming',
  'Yoga',
  'Weights',
  'Other',
];

// Default Values
const int defaultGoalSteps = 10000;
const int defaultCalorieGoal = 2000;
const int defaultWaterGoal = 8;
const double defaultWeightChangeGoal = 0.5; // kg per week

// Validation Rules
const int minPasswordLength = 8;
const int maxNameLength = 50;
const int minAge = 13;
const int maxAge = 120;