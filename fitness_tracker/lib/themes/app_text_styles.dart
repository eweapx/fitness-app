import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application text styles
class AppTextStyles {
  // Heading styles
  static final TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
  );
  
  static final TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
  );
  
  static final TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
  );
  
  // Body text styles
  static final TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  static final TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  static final TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: 0.25,
  );
  
  // Caption styles
  static final TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );
  
  // Button styles
  static final TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    letterSpacing: 1.25,
  );
  
  // Subtitle styles
  static final TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.15,
  );
  
  static final TextStyle subtitleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
  
  // Overline style
  static final TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );
  
  // Helper styles for specific use cases
  static final TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    letterSpacing: 0.25,
  );
  
  static final TextStyle success = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.success,
    letterSpacing: 0.25,
  );
  
  static final TextStyle metric = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 0.25,
  );
  
  static final TextStyle metricLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.25,
  );
  
  static final TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
  );
  
  static final TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
}