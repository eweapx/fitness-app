import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Private Constructor
  AppTheme._();
  
  // Define Colors
  static const Color _primaryColor = Color(0xFF4A90E2);
  static const Color _secondaryColor = Color(0xFF50E3C2);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _successColor = Color(0xFF43A047);
  static const Color _warningColor = Color(0xFFFFA000);
  static const Color _infoColor = Color(0xFF2196F3);
  
  // Light Theme Colors
  static const Color _lightBackgroundColor = Color(0xFFF5F5F7);
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightOnPrimaryColor = Colors.white;
  static const Color _lightOnSecondaryColor = Colors.black;
  static const Color _lightOnBackgroundColor = Color(0xFF333333);
  static const Color _lightOnSurfaceColor = Color(0xFF333333);
  
  // Dark Theme Colors
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _darkSurfaceColor = Color(0xFF222222);
  static const Color _darkOnPrimaryColor = Colors.white;
  static const Color _darkOnSecondaryColor = Colors.black;
  static const Color _darkOnBackgroundColor = Colors.white;
  static const Color _darkOnSurfaceColor = Colors.white;
  
  // Shared Colors
  static const Color _dividerColor = Color(0xFFBDBDBD);
  static const Color _disabledColor = Color(0xFF9E9E9E);
  
  // Gradients
  static const List<Color> _primaryGradient = [
    Color(0xFF4A90E2),
    Color(0xFF5C6BC0),
  ];
  
  static const List<Color> _secondaryGradient = [
    Color(0xFF50E3C2),
    Color(0xFF4DD0E1),
  ];
  
  // TextStyles
  static TextStyle _getTextStyle(double fontSize, FontWeight fontWeight, Color color) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
  
  // Headline Styles
  static TextStyle _headline1(Color color) {
    return _getTextStyle(28.0, FontWeight.bold, color);
  }
  
  static TextStyle _headline2(Color color) {
    return _getTextStyle(24.0, FontWeight.bold, color);
  }
  
  static TextStyle _headline3(Color color) {
    return _getTextStyle(20.0, FontWeight.w600, color);
  }
  
  static TextStyle _headline4(Color color) {
    return _getTextStyle(18.0, FontWeight.w600, color);
  }
  
  static TextStyle _headline5(Color color) {
    return _getTextStyle(16.0, FontWeight.w600, color);
  }
  
  static TextStyle _headline6(Color color) {
    return _getTextStyle(14.0, FontWeight.w600, color);
  }
  
  // Body Styles
  static TextStyle _bodyText1(Color color) {
    return _getTextStyle(16.0, FontWeight.normal, color);
  }
  
  static TextStyle _bodyText2(Color color) {
    return _getTextStyle(14.0, FontWeight.normal, color);
  }
  
  // Button Style
  static TextStyle _button(Color color) {
    return _getTextStyle(14.0, FontWeight.w600, color);
  }
  
  // Caption Style
  static TextStyle _caption(Color color) {
    return _getTextStyle(12.0, FontWeight.normal, color);
  }
  
  // Overline Style
  static TextStyle _overline(Color color) {
    return _getTextStyle(10.0, FontWeight.normal, color);
  }
  
  // Subtitle Styles
  static TextStyle _subtitle1(Color color) {
    return _getTextStyle(16.0, FontWeight.w500, color);
  }
  
  static TextStyle _subtitle2(Color color) {
    return _getTextStyle(14.0, FontWeight.w500, color);
  }
  
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: _lightOnPrimaryColor,
      secondary: _secondaryColor,
      onSecondary: _lightOnSecondaryColor,
      background: _lightBackgroundColor,
      onBackground: _lightOnBackgroundColor,
      surface: _lightSurfaceColor,
      onSurface: _lightOnSurfaceColor,
      error: _errorColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: _lightOnPrimaryColor,
      centerTitle: true,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightSurfaceColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: _disabledColor,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    cardTheme: CardTheme(
      color: _lightSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _dividerColor,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _lightOnPrimaryColor,
        backgroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: _lightOnPrimaryColor,
    ),
    iconTheme: const IconThemeData(
      color: _lightOnBackgroundColor,
      size: 24,
    ),
    primaryIconTheme: const IconThemeData(
      color: _lightOnPrimaryColor,
      size: 24,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: _lightSurfaceColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: TextTheme(
      displayLarge: _headline1(_lightOnBackgroundColor),
      displayMedium: _headline2(_lightOnBackgroundColor),
      displaySmall: _headline3(_lightOnBackgroundColor),
      headlineMedium: _headline4(_lightOnBackgroundColor),
      headlineSmall: _headline5(_lightOnBackgroundColor),
      titleLarge: _headline6(_lightOnBackgroundColor),
      bodyLarge: _bodyText1(_lightOnBackgroundColor),
      bodyMedium: _bodyText2(_lightOnBackgroundColor),
      labelLarge: _button(_lightOnBackgroundColor),
      bodySmall: _caption(_lightOnBackgroundColor),
      labelSmall: _overline(_lightOnBackgroundColor),
      titleMedium: _subtitle1(_lightOnBackgroundColor),
      titleSmall: _subtitle2(_lightOnBackgroundColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _lightSurfaceColor,
      disabledColor: _disabledColor.withOpacity(0.1),
      selectedColor: _primaryColor,
      secondarySelectedColor: _secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: _bodyText2(_lightOnBackgroundColor),
      secondaryLabelStyle: _bodyText2(_lightOnBackgroundColor),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _dividerColor),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: _lightSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _lightOnBackgroundColor,
      contentTextStyle: _bodyText2(_lightSurfaceColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return _disabledColor;
        }
        if (states.contains(MaterialState.selected)) {
          return _primaryColor;
        }
        return _lightOnBackgroundColor;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return _disabledColor.withOpacity(0.3);
        }
        if (states.contains(MaterialState.selected)) {
          return _primaryColor.withOpacity(0.5);
        }
        return _lightOnBackgroundColor.withOpacity(0.3);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return _disabledColor;
        }
        if (states.contains(MaterialState.selected)) {
          return _primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(_lightOnPrimaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryColor,
      circularTrackColor: _dividerColor,
      linearTrackColor: _dividerColor,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _lightSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: _primaryColor,
      unselectedLabelColor: _disabledColor,
      labelStyle: _button(_primaryColor),
      unselectedLabelStyle: _button(_disabledColor),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(
          color: _primaryColor,
          width: 2,
        ),
      ),
    ),
  );
  
  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      onPrimary: _darkOnPrimaryColor,
      secondary: _secondaryColor,
      onSecondary: _darkOnSecondaryColor,
      background: _darkBackgroundColor,
      onBackground: _darkOnBackgroundColor,
      surface: _darkSurfaceColor,
      onSurface: _darkOnSurfaceColor,
      error: _errorColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkSurfaceColor,
      foregroundColor: _darkOnSurfaceColor,
      centerTitle: true,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurfaceColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: _disabledColor,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    cardTheme: CardTheme(
      color: _darkSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: _dividerColor.withOpacity(0.2),
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _darkOnPrimaryColor,
        backgroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: _darkOnPrimaryColor,
    ),
    iconTheme: const IconThemeData(
      color: _darkOnBackgroundColor,
      size: 24,
    ),
    primaryIconTheme: const IconThemeData(
      color: _darkOnPrimaryColor,
      size: 24,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: _darkSurfaceColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _dividerColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _dividerColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: TextTheme(
      displayLarge: _headline1(_darkOnBackgroundColor),
      displayMedium: _headline2(_darkOnBackgroundColor),
      displaySmall: _headline3(_darkOnBackgroundColor),
      headlineMedium: _headline4(_darkOnBackgroundColor),
      headlineSmall: _headline5(_darkOnBackgroundColor),
      titleLarge: _headline6(_darkOnBackgroundColor),
      bodyLarge: _bodyText1(_darkOnBackgroundColor),
      bodyMedium: _bodyText2(_darkOnBackgroundColor),
      labelLarge: _button(_darkOnBackgroundColor),
      bodySmall: _caption(_darkOnBackgroundColor),
      labelSmall: _overline(_darkOnBackgroundColor),
      titleMedium: _subtitle1(_darkOnBackgroundColor),
      titleSmall: _subtitle2(_darkOnBackgroundColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _darkSurfaceColor,
      disabledColor: _disabledColor.withOpacity(0.1),
      selectedColor: _primaryColor,
      secondarySelectedColor: _secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: _bodyText2(_darkOnBackgroundColor),
      secondaryLabelStyle: _bodyText2(_darkOnBackgroundColor),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _dividerColor.withOpacity(0.2)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: _darkSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _darkOnBackgroundColor.withOpacity(0.9),
      contentTextStyle: _bodyText2(_darkBackgroundColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return _disabledColor;
        }
        if (states.contains(MaterialState.selected)) {
          return _primaryColor;
        }
        return _darkOnBackgroundColor;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return _disabledColor.withOpacity(0.3);
        }
        if (states.contains(MaterialState.selected)) {
          return _primaryColor.withOpacity(0.5);
        }
        return _darkOnBackgroundColor.withOpacity(0.3);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return _disabledColor;
        }
        if (states.contains(MaterialState.selected)) {
          return _primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(_darkOnPrimaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryColor,
      circularTrackColor: _disabledColor,
      linearTrackColor: _disabledColor,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: _primaryColor,
      unselectedLabelColor: _disabledColor,
      labelStyle: _button(_primaryColor),
      unselectedLabelStyle: _button(_disabledColor),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(
          color: _primaryColor,
          width: 2,
        ),
      ),
    ),
  );
  
  // Helper functions
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      colors: _primaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  static LinearGradient getSecondaryGradient() {
    return const LinearGradient(
      colors: _secondaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  static Color getSuccessColor() {
    return _successColor;
  }
  
  static Color getErrorColor() {
    return _errorColor;
  }
  
  static Color getWarningColor() {
    return _warningColor;
  }
  
  static Color getInfoColor() {
    return _infoColor;
  }
}