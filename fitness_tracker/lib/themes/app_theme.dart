import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Application theme definition
class AppTheme {
  /// Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleTextStyle: AppTextStyles.heading.copyWith(
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        foregroundColor: AppColors.primary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      labelStyle: AppTextStyles.body.copyWith(color: Colors.grey[700]),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: AppTextStyles.caption,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey[600],
      labelStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: AppTextStyles.button,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 3, color: AppColors.primary),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      disabledColor: Colors.grey[300],
      selectedColor: AppColors.primary.withOpacity(0.2),
      secondarySelectedColor: AppColors.primary.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      labelStyle: AppTextStyles.caption.copyWith(color: Colors.black),
      secondaryLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 24,
      color: Colors.black12,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Colors.white,
      hourMinuteTextColor: AppColors.primary,
      dayPeriodTextColor: AppColors.primary,
      dialHandColor: AppColors.primary,
      dialBackgroundColor: Colors.grey[200],
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      titleTextStyle: AppTextStyles.heading,
      contentTextStyle: AppTextStyles.body,
    ),
  );

  /// Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.accentDark,
      surface: Colors.grey[900]!,
      background: Colors.black,
      error: AppColors.errorDark,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      titleTextStyle: AppTextStyles.heading.copyWith(
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        foregroundColor: AppColors.primaryDark,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: AppColors.primaryDark),
        foregroundColor: AppColors.primaryDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey[850],
      labelStyle: AppTextStyles.body.copyWith(color: Colors.grey[300]),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: Colors.grey[400],
      selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: AppTextStyles.caption,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.primaryDark,
      unselectedLabelColor: Colors.grey[400],
      labelStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: AppTextStyles.button,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 3, color: AppColors.primaryDark),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[800],
      disabledColor: Colors.grey[700],
      selectedColor: AppColors.primaryDark.withOpacity(0.2),
      secondarySelectedColor: AppColors.primaryDark.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      labelStyle: AppTextStyles.caption.copyWith(color: Colors.white),
      secondaryLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.primaryDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 24,
      color: Colors.white12,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Colors.grey[850],
      hourMinuteTextColor: AppColors.primaryDark,
      dayPeriodTextColor: AppColors.primaryDark,
      dialHandColor: AppColors.primaryDark,
      dialBackgroundColor: Colors.grey[800],
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.grey[850],
      titleTextStyle: AppTextStyles.heading.copyWith(color: Colors.white),
      contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
    ),
  );
}