import 'package:flutter/material.dart';

/// App color palette for consistent theming across the app
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF4CAF50);  // Green
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFFC8E6C9);
  static const Color accent = Color(0xFF536DFE);  // Blue accent
  
  // Neutrals
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFEEEEEE);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  
  // Activity type colors
  static const Color running = Color(0xFF4CAF50);
  static const Color cycling = Color(0xFF2196F3);
  static const Color swimming = Color(0xFF00BCD4);
  static const Color walking = Color(0xFF8BC34A);
  static const Color gym = Color(0xFFFF9800);
  static const Color sports = Color(0xFFE91E63);
  
  // Nutrition colors
  static const Color carbs = Color(0xFFFFC107);
  static const Color protein = Color(0xFF8BC34A);
  static const Color fat = Color(0xFFFF5722);
  
  // Sleep tracking colors
  static const Color deepSleep = Color(0xFF3F51B5);
  static const Color lightSleep = Color(0xFF7986CB);
  static const Color rem = Color(0xFF5C6BC0);
  static const Color awake = Color(0xFFBDBDBD);
}