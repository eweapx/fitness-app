import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class with helper methods for formatting and conversions
class AppHelpers {
  /// Format a number with commas for thousands
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }
  
  /// Format duration in minutes to a readable format (e.g., "8h 30m")
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }
  
  /// Convert milliliters to US fluid ounces
  static double mlToOz(double ml) {
    return ml / 29.5735;
  }
  
  /// Convert US fluid ounces to milliliters
  static double ozToMl(double oz) {
    return oz * 29.5735;
  }
  
  /// Format a DateTime to a string using the specified format
  static String formatDateTime(DateTime dateTime, String format) {
    return DateFormat(format).format(dateTime);
  }
  
  /// Format a TimeOfDay to a string (12h or 24h format)
  static String formatTimeOfDay(TimeOfDay timeOfDay, bool use24HourFormat) {
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    
    if (use24HourFormat) {
      return '${hour.toString().padLeft(2, '0')}:$minute';
    } else {
      final period = hour < 12 ? 'AM' : 'PM';
      final hourIn12HourFormat = hour % 12 == 0 ? 12 : hour % 12;
      return '$hourIn12HourFormat:$minute $period';
    }
  }
  
  /// Convert miles to kilometers
  static double milesToKm(double miles) {
    return miles * 1.60934;
  }
  
  /// Convert kilometers to miles
  static double kmToMiles(double km) {
    return km / 1.60934;
  }
  
  /// Convert pounds to kilograms
  static double lbsToKg(double lbs) {
    return lbs * 0.453592;
  }
  
  /// Convert kilograms to pounds
  static double kgToLbs(double kg) {
    return kg / 0.453592;
  }
  
  /// Convert feet to centimeters
  static double ftToCm(double ft) {
    return ft * 30.48;
  }
  
  /// Convert centimeters to feet
  static double cmToFt(double cm) {
    return cm / 30.48;
  }
  
  /// Convert Fahrenheit to Celsius
  static double fToC(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }
  
  /// Convert Celsius to Fahrenheit
  static double cToF(double celsius) {
    return (celsius * 9 / 5) + 32;
  }
  
  /// Convert imperial height (ft and inches) to cm
  /// Format: '5\'11"' -> 180.34 cm
  static double imperialHeightToCm(String heightStr) {
    // Remove any spaces and split by feet and inches
    final cleanStr = heightStr.replaceAll(' ', '');
    final feetMatch = RegExp(r"(\d+)'").firstMatch(cleanStr);
    final inchesMatch = RegExp(r'(\d+)"').firstMatch(cleanStr);
    
    var feetValue = 0;
    var inchesValue = 0;
    
    if (feetMatch != null) {
      feetValue = int.parse(feetMatch.group(1) ?? '0');
    }
    
    if (inchesMatch != null) {
      inchesValue = int.parse(inchesMatch.group(1) ?? '0');
    }
    
    // Convert to cm
    return (feetValue * 30.48) + (inchesValue * 2.54);
  }
  
  /// Calculate Body Mass Index (BMI)
  /// Formula: weight (kg) / (height (m))^2
  static double calculateBMI(double weightKg, double heightCm) {
    // Convert height from cm to meters
    final heightM = heightCm / 100;
    
    // Calculate BMI
    return weightKg / (heightM * heightM);
  }
  
  /// Get BMI category based on BMI value
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
  
  /// Calculate Basal Metabolic Rate (BMR) using the Mifflin-St Jeor Equation
  /// For men: BMR = 10W + 6.25H - 5A + 5
  /// For women: BMR = 10W + 6.25H - 5A - 161
  /// W = weight in kg, H = height in cm, A = age in years
  static double calculateBasalMetabolicRate({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    double bmr;
    
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    
    return bmr;
  }
  
  /// Calculate Total Daily Energy Expenditure (TDEE)
  /// TDEE = BMR * activity factor
  static double calculateTotalDailyEnergyExpenditure(double bmr, String activityLevel) {
    double activityFactor;
    
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        activityFactor = 1.2; // Little or no exercise
        break;
      case 'light':
        activityFactor = 1.375; // Light exercise 1-3 days/week
        break;
      case 'moderate':
        activityFactor = 1.55; // Moderate exercise 3-5 days/week
        break;
      case 'active':
        activityFactor = 1.725; // Heavy exercise 6-7 days/week
        break;
      case 'very active':
        activityFactor = 1.9; // Very heavy exercise, physical job
        break;
      default:
        activityFactor = 1.2; // Default to sedentary
    }
    
    return bmr * activityFactor;
  }
  
  /// Format a value to a specified number of decimal places
  static String formatDecimal(double value, int decimalPlaces) {
    return value.toStringAsFixed(decimalPlaces);
  }
  
  /// Calculate ideal weight range based on BMI of 18.5-24.9
  static Map<String, double> calculateIdealWeightRange(double heightCm) {
    final heightM = heightCm / 100;
    final minWeight = 18.5 * heightM * heightM;
    final maxWeight = 24.9 * heightM * heightM;
    
    return {
      'min': minWeight,
      'max': maxWeight,
    };
  }
  
  /// Calculate body fat percentage using the Navy method
  /// A different formula is used for men and women
  static double calculateBodyFatPercentage({
    required String gender,
    required double waistCm,
    required double heightCm,
    double? neckCm,
    double? hipsCm,
  }) {
    if (gender.toLowerCase() == 'male') {
      if (neckCm == null) return 0;
      // Men: 86.010 × log10(waist - neck) - 70.041 × log10(height) + 36.76
      return 86.010 * (log(waistCm - neckCm) / log(10)) - 
             70.041 * (log(heightCm) / log(10)) + 36.76;
    } else {
      if (neckCm == null || hipsCm == null) return 0;
      // Women: 163.205 × log10(waist + hips - neck) - 97.684 × log10(height) - 78.387
      return 163.205 * (log(waistCm + hipsCm - neckCm) / log(10)) - 
             97.684 * (log(heightCm) / log(10)) - 78.387;
    }
  }
  
  /// Calculate calorie needs for weight loss/gain
  static Map<String, int> calculateCalorieGoals(double tdee) {
    return {
      'maintain': tdee.round(),
      'mild_loss': (tdee - 250).round(),
      'loss': (tdee - 500).round(),
      'extreme_loss': (tdee - 1000).round(),
      'mild_gain': (tdee + 250).round(),
      'gain': (tdee + 500).round(),
      'fast_gain': (tdee + 1000).round(),
    };
  }
  
  /// Calculate macronutrient split based on goals
  static Map<String, Map<String, int>> calculateMacroSplit(double tdee, String goal) {
    int calories;
    
    switch (goal.toLowerCase()) {
      case 'fat loss':
        calories = (tdee - 500).round();
        // Higher protein, moderate fat, lower carb
        return {
          'balanced': {
            'protein': ((calories * 0.3) / 4).round(),
            'carbs': ((calories * 0.4) / 4).round(),
            'fat': ((calories * 0.3) / 9).round(),
          },
          'low_carb': {
            'protein': ((calories * 0.4) / 4).round(),
            'carbs': ((calories * 0.2) / 4).round(),
            'fat': ((calories * 0.4) / 9).round(),
          },
          'high_protein': {
            'protein': ((calories * 0.45) / 4).round(),
            'carbs': ((calories * 0.35) / 4).round(),
            'fat': ((calories * 0.2) / 9).round(),
          },
        };
      case 'muscle gain':
        calories = (tdee + 500).round();
        // Higher protein, higher carb, moderate fat
        return {
          'balanced': {
            'protein': ((calories * 0.25) / 4).round(),
            'carbs': ((calories * 0.5) / 4).round(),
            'fat': ((calories * 0.25) / 9).round(),
          },
          'high_carb': {
            'protein': ((calories * 0.3) / 4).round(),
            'carbs': ((calories * 0.55) / 4).round(),
            'fat': ((calories * 0.15) / 9).round(),
          },
          'high_protein': {
            'protein': ((calories * 0.35) / 4).round(),
            'carbs': ((calories * 0.45) / 4).round(),
            'fat': ((calories * 0.2) / 9).round(),
          },
        };
      default: // Maintenance
        calories = tdee.round();
        // Balanced macros
        return {
          'balanced': {
            'protein': ((calories * 0.25) / 4).round(),
            'carbs': ((calories * 0.45) / 4).round(),
            'fat': ((calories * 0.3) / 9).round(),
          },
          'low_carb': {
            'protein': ((calories * 0.3) / 4).round(),
            'carbs': ((calories * 0.3) / 4).round(),
            'fat': ((calories * 0.4) / 9).round(),
          },
          'high_protein': {
            'protein': ((calories * 0.35) / 4).round(),
            'carbs': ((calories * 0.4) / 4).round(),
            'fat': ((calories * 0.25) / 9).round(),
          },
        };
    }
  }
}