import 'package:flutter/material.dart';

/// App theme colors
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF4A5CFF); // Vibrant blue
  static const Color secondary = Color(0xFF6B48FF); // Purple
  static const Color tertiary = Color(0xFF00D98B); // Green
  
  // UI colors
  static const Color background = Color(0xFFF9FAFC);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935); // Red
  static const Color warning = Color(0xFFFFA726); // Orange
  static const Color success = Color(0xFF58BD76); // Green
  
  // Text colors
  static const Color textPrimary = Color(0xFF2A2D34);
  static const Color textSecondary = Color(0xFF686C73);
  static const Color textTertiary = Color(0xFF9EA3AD);
  
  // Activity type colors
  static const Color running = Color(0xFF26A69A);
  static const Color cycling = Color(0xFF42A5F5);
  static const Color swimming = Color(0xFF5C6BC0);
  static const Color walking = Color(0xFF66BB6A);
  static const Color yoga = Color(0xFFAB47BC);
  static const Color gym = Color(0xFFEF5350);
  
  // Sleep stage colors
  static const Color deep = Color(0xFF283593);
  static const Color light = Color(0xFF5C6BC0);
  static const Color rem = Color(0xFF9FA8DA);
  static const Color awake = Color(0xFFE8EAF6);
  
  // Nutrition colors
  static const Color protein = Color(0xFF8D6E63);
  static const Color carbs = Color(0xFFFFB74D);
  static const Color fat = Color(0xFF90A4AE);
  static const Color fiber = Color(0xFF81C784);
  static const Color water = Color(0xFF4FC3F7);
}

/// App theme text styles
class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  // Captions
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Buttons
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.4,
  );
  
  // Links
  static const TextStyle link = TextStyle(
    fontSize: 14,
    color: AppColors.primary,
    height: 1.5,
    decoration: TextDecoration.underline,
  );
}

/// App constants
class AppConstants {
  // API endpoints
  static const String apiBaseUrl = 'https://api.fitnesstracker.com';
  static const String termsUrl = 'https://fitnesstracker.com/terms';
  static const String privacyUrl = 'https://fitnesstracker.com/privacy';
  static const String supportUrl = 'https://fitnesstracker.com/support';
  
  // File paths
  static const String assetImagesPath = 'assets/images/';
  static const String assetIconsPath = 'assets/icons/';
  
  // Shared preferences keys
  static const String prefAuthToken = 'auth_token';
  static const String prefUserProfile = 'user_profile';
  static const String prefSettings = 'app_settings';
  static const String prefOnboardingComplete = 'onboarding_complete';
  
  // Measurement units
  static const String unitKg = 'kg';
  static const String unitLbs = 'lbs';
  static const String unitCm = 'cm';
  static const String unitFt = 'ft';
  static const String unitMl = 'ml';
  static const String unitOz = 'oz';
  static const String unitKm = 'km';
  static const String unitMi = 'mi';
  static const String unitKcal = 'kcal';
  
  // Time formats
  static const String timeFormat24h = 'HH:mm';
  static const String timeFormat12h = 'h:mm a';
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';
  static const String dateFormatShort = 'MMM d, yyyy';
  static const String dateFormatCompact = 'MM/dd/yyyy';
  
  // Notification channels
  static const String notificationChannelWorkouts = 'workouts';
  static const String notificationChannelHabits = 'habits';
  static const String notificationChannelWater = 'water';
  static const String notificationChannelMeals = 'meals';
  
  // Feature constants
  static const int waterReminderInterval = 2; // hours
  static const int defaultCalorieGoal = 2000; // kcal
  static const int defaultWaterGoal = 2000; // ml
  static const int defaultStepsGoal = 10000; // steps
  static const int defaultSleepGoal = 8; // hours
}

/// Activity types for fitness tracking
enum ActivityType {
  running,
  walking,
  cycling,
  swimming,
  yoga,
  hiking,
  weightTraining,
  other,
}

/// Meal types for nutrition tracking
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

/// Units of measurement
enum MeasurementUnit {
  metric,
  imperial,
}

/// Theme mode
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Helper methods for the app
class AppHelpers {
  // Convert kilograms to pounds
  static double kgToLbs(double kg) {
    return kg * 2.20462;
  }
  
  // Convert pounds to kilograms
  static double lbsToKg(double lbs) {
    return lbs / 2.20462;
  }
  
  // Convert centimeters to feet and inches
  static Map<String, int> cmToFtIn(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    
    return {
      'feet': feet,
      'inches': inches,
    };
  }
  
  // Convert feet and inches to centimeters
  static double ftInToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return totalInches * 2.54;
  }
  
  // Convert kilometers to miles
  static double kmToMiles(double km) {
    return km * 0.621371;
  }
  
  // Convert miles to kilometers
  static double milesToKm(double miles) {
    return miles / 0.621371;
  }
  
  // Convert milliliters to fluid ounces
  static double mlToOz(double ml) {
    return ml * 0.033814;
  }
  
  // Convert fluid ounces to milliliters
  static double ozToMl(double oz) {
    return oz / 0.033814;
  }
  
  // Calculate BMI (Body Mass Index)
  static double calculateBMI(double weightKg, double heightCm) {
    // BMI = weight(kg) / height(m)²
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'Normal';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
  
  // Calculate daily calories needed (Harris-Benedict equation)
  static int calculateDailyCalories(
    double weightKg,
    double heightCm,
    int age,
    String gender,
    double activityLevel,
  ) {
    double bmr;
    
    if (gender.toLowerCase() == 'male') {
      bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * age);
    }
    
    // Activity level multipliers
    // 1.2 = Sedentary (little or no exercise)
    // 1.375 = Lightly active (light exercise/sports 1-3 days/week)
    // 1.55 = Moderately active (moderate exercise/sports 3-5 days/week)
    // 1.725 = Very active (hard exercise/sports 6-7 days/week)
    // 1.9 = Extra active (very hard exercise, physical job, or training twice a day)
    
    return (bmr * activityLevel).round();
  }
}