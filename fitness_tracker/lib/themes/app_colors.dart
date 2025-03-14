import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  // Primary colors
  static final Color primary = Color(0xFF1976D2);
  static final Color primaryDark = Color(0xFF2196F3);
  static final Color primaryLight = Color(0xFF64B5F6);
  
  // Accent colors
  static final Color accent = Color(0xFFFF4081);
  static final Color accentDark = Color(0xFFFF80AB);
  static final Color accentLight = Color(0xFFFF80AB);
  
  // Semantic colors
  static final Color success = Color(0xFF4CAF50);
  static final Color warning = Color(0xFFFFC107);
  static final Color error = Color(0xFFF44336);
  static final Color info = Color(0xFF2196F3);
  
  // Dark mode variants
  static final Color successDark = Color(0xFF66BB6A);
  static final Color warningDark = Color(0xFFFFD54F);
  static final Color errorDark = Color(0xFFE57373);
  static final Color infoDark = Color(0xFF64B5F6);
  
  // Activity-specific colors
  static final Color running = Color(0xFFF44336);
  static final Color cycling = Color(0xFF4CAF50);
  static final Color swimming = Color(0xFF2196F3);
  static final Color walking = Color(0xFFFF9800);
  static final Color yoga = Color(0xFF9C27B0);
  static final Color weights = Color(0xFF795548);
  
  // Sleep-specific colors
  static final Color deepSleep = Color(0xFF3F51B5);
  static final Color lightSleep = Color(0xFF7986CB);
  static final Color remSleep = Color(0xFF303F9F);
  static final Color awake = Color(0xFFFFB74D);
  
  // Nutrition-specific colors
  static final Color protein = Color(0xFF8D6E63);
  static final Color carbs = Color(0xFFAED581);
  static final Color fat = Color(0xFFFFD54F);
  static final Color fiber = Color(0xFF795548);
  
  // Hydration colors
  static final Color water = Color(0xFF29B6F6);
  
  // Background colors
  static final Color background = Color(0xFFF5F5F5);
  static final Color backgroundDark = Color(0xFF121212);
  static final Color card = Colors.white;
  static final Color cardDark = Color(0xFF1E1E1E);
  
  // Text colors
  static final Color textPrimary = Color(0xFF212121);
  static final Color textSecondary = Color(0xFF757575);
  static final Color textHint = Color(0xFFBDBDBD);
  static final Color textPrimaryDark = Colors.white;
  static final Color textSecondaryDark = Color(0xFFB0B0B0);
  static final Color textHintDark = Color(0xFF6D6D6D);
  
  // Gradient colors
  static final List<Color> primaryGradient = [
    Color(0xFF1976D2),
    Color(0xFF2196F3),
  ];
  
  static final List<Color> accentGradient = [
    Color(0xFFFF4081),
    Color(0xFFFF80AB),
  ];
  
  static final List<Color> successGradient = [
    Color(0xFF388E3C),
    Color(0xFF4CAF50),
  ];
  
  static final List<Color> warningGradient = [
    Color(0xFFFFA000),
    Color(0xFFFFC107),
  ];
  
  static final List<Color> errorGradient = [
    Color(0xFFD32F2F),
    Color(0xFFF44336),
  ];
  
  static final List<Color> sleepGradient = [
    Color(0xFF3F51B5),
    Color(0xFF7986CB),
  ];
}