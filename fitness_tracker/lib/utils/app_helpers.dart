import 'dart:math';
import 'package:intl/intl.dart';

/// Utility class with helper methods for the app
class AppHelpers {
  // Prevent instantiation
  AppHelpers._();
  
  // Format a DateTime based on the specified format
  static String formatDate(DateTime date, String format) {
    return DateFormat(format).format(date);
  }
  
  // Calculate age from birthdate
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final monthDiff = today.month - birthDate.month;
    
    if (monthDiff < 0 || (monthDiff == 0 && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  // Convert pounds to kilograms
  static double lbsToKg(double lbs) {
    return lbs * 0.45359237;
  }
  
  // Convert kilograms to pounds
  static double kgToLbs(double kg) {
    return kg * 2.20462262;
  }
  
  // Convert feet and inches to centimeters
  static int ftInToCm(int feet, int inches) {
    return ((feet * 12) + inches) * 2.54.round();
  }
  
  // Convert centimeters to feet and inches
  static Map<String, int> cmToFtIn(int cm) {
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    
    return {
      'feet': feet,
      'inches': inches,
    };
  }
  
  // Parse a height string like "5'10"" to centimeters
  static int imperialHeightToCm(String heightStr) {
    try {
      heightStr = heightStr.replaceAll('"', '');
      final parts = heightStr.split("'");
      
      if (parts.length != 2) {
        return 175; // Default
      }
      
      final feet = int.tryParse(parts[0].trim()) ?? 5;
      final inches = int.tryParse(parts[1].trim()) ?? 10;
      
      return ftInToCm(feet, inches);
    } catch (e) {
      return 175; // Default to 5'9" in cm
    }
  }
  
  // Format height based on unit system
  static String formatHeight(int cm, bool useMetric) {
    if (useMetric) {
      return '$cm cm';
    } else {
      final imperial = cmToFtIn(cm);
      return "${imperial['feet']}'${imperial['inches']}\"";
    }
  }
  
  // Format weight based on unit system
  static String formatWeight(double kg, bool useMetric) {
    if (useMetric) {
      return '${kg.toStringAsFixed(1)} kg';
    } else {
      final lbs = kgToLbs(kg);
      return '${lbs.toStringAsFixed(1)} lbs';
    }
  }
  
  // Calculate BMI (Body Mass Index)
  static double calculateBMI(double weightKg, int heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
  
  // Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  static int calculateBasalMetabolicRate(
    int age, 
    String gender, 
    double weightKg, 
    int heightCm,
  ) {
    if (gender == 'Male') {
      return (10 * weightKg + 6.25 * heightCm - 5 * age + 5).round();
    } else {
      return (10 * weightKg + 6.25 * heightCm - 5 * age - 161).round();
    }
  }
  
  // Calculate Total Daily Energy Expenditure (TDEE)
  static int calculateTotalDailyEnergyExpenditure(
    int bmr, 
    String activityLevel,
  ) {
    double multiplier;
    
    switch (activityLevel) {
      case 'Sedentary':
        multiplier = 1.2;
        break;
      case 'Lightly Active':
        multiplier = 1.375;
        break;
      case 'Moderately Active':
        multiplier = 1.55;
        break;
      case 'Very Active':
        multiplier = 1.725;
        break;
      case 'Extremely Active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.55; // Default to moderately active
    }
    
    return (bmr * multiplier).round();
  }
  
  // Calculate calories burned for an activity
  static int calculateCaloriesBurned(
    String activity, 
    double weightKg, 
    int durationMinutes,
  ) {
    // MET (Metabolic Equivalent of Task) values
    final Map<String, double> metValues = {
      'walking': 3.5,
      'running': 8.0,
      'cycling': 7.0,
      'swimming': 6.0,
      'yoga': 3.0,
      'strength_training': 5.0,
      'dancing': 4.5,
      'hiking': 6.0,
      'rowing': 7.0,
      'basketball': 6.5,
      'soccer': 7.0,
      'tennis': 7.0,
      'jumping_rope': 10.0,
      'elliptical': 5.0,
      'stair_climbing': 4.0,
      'pilates': 3.5,
      'calisthenics': 4.0,
      'stretching': 2.5,
    };
    
    // Use default if activity not found
    final met = metValues[activity.toLowerCase()] ?? 4.0;
    
    // Formula: Calories = MET × weight (kg) × duration (hours)
    final durationHours = durationMinutes / 60;
    return (met * weightKg * durationHours).round();
  }
  
  // Convert steps to calories (rough estimate)
  static int stepsToCalories(int steps, double weightKg) {
    // Rough estimate: 0.04 calories per step per kg of body weight
    return (steps * 0.04 * (weightKg / 70)).round();
  }
  
  // Convert steps to distance in kilometers (rough estimate)
  static double stepsToDistance(int steps, int heightCm) {
    // Calculate stride length (approximately 0.414 × height in cm)
    final strideLength = 0.414 * heightCm / 100; // in meters
    
    // Calculate distance
    return steps * strideLength / 1000; // in kilometers
  }
  
  // Convert distance to steps (rough estimate)
  static int distanceToSteps(double distanceKm, int heightCm) {
    // Calculate stride length (approximately 0.414 × height in cm)
    final strideLength = 0.414 * heightCm / 100; // in meters
    
    // Calculate steps
    return (distanceKm * 1000 / strideLength).round();
  }
  
  // Get a random motivational quote
  static String getRandomMotivationalQuote() {
    final quotes = [
      "The only bad workout is the one that didn't happen.",
      "It's going to be a journey. It's not a sprint to get in shape.",
      "The difference between try and triumph is just a little umph!",
      "Strength does not come from physical capacity. It comes from an indomitable will.",
      "The body achieves what the mind believes.",
      "Your body can stand almost anything. It's your mind that you have to convince.",
      "The only way to define your limits is by going beyond them.",
      "You don't have to be great to start, but you have to start to be great.",
      "No matter how slow you go, you're still lapping everyone on the couch.",
      "The best way to predict your future is to create it.",
      "The hard days are the best because that's when champions are made.",
      "Believe in yourself and all that you are. Know that there is something inside you that is greater than any obstacle.",
      "Your health is an investment, not an expense.",
      "If you want something you've never had, you must be willing to do something you've never done.",
      "The only person you should try to be better than is the person you were yesterday.",
    ];
    
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }
  
  // Get day of the week from a DateTime
  static String getDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  // Format seconds to mm:ss format
  static String formatSecondsToMinutesSeconds(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
  
  // Format seconds to hh:mm:ss format
  static String formatSecondsToHoursMinutesSeconds(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }
  
  // Generate a random color
  static int getRandomColor() {
    final random = Random();
    return (0xFF000000 + random.nextInt(0xFFFFFF));
  }
  
  // Calculate water needed based on weight
  static double calculateWaterNeeded(double weightKg) {
    // Recommendation: 30-35 ml per kg of body weight
    return weightKg * 0.033; // in liters
  }
  
  // Format water amount
  static String formatWaterAmount(double liters) {
    if (liters < 1) {
      final ml = (liters * 1000).round();
      return '$ml ml';
    } else {
      return '${liters.toStringAsFixed(1)} L';
    }
  }
}