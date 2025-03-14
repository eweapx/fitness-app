import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage application settings
class SettingsProvider extends ChangeNotifier {
  // Default values - General settings
  bool _useMetricUnits = true;
  bool _enableNotifications = true;
  bool _darkMode = false;
  String _timeFormat = '24h';
  String _dateFormat = 'yyyy-MM-dd';
  int _reminderTime = 20 * 60; // Default 8:00 PM in minutes from midnight
  List<String> _activeDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  // Default values - Goals
  int _stepGoal = 10000;
  int _waterGoal = 2000; // in ml
  int _calorieGoal = 2000;
  int _sleepGoal = 480; // 8 hours in minutes
  
  // Default values - Reminders
  bool _reminderEnabled = false;
  ThemeMode _themeMode = ThemeMode.light;
  
  // Keys for SharedPreferences
  static const String _useMetricUnitsKey = 'use_metric_units';
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _darkModeKey = 'dark_mode';
  static const String _timeFormatKey = 'time_format';
  static const String _dateFormatKey = 'date_format';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _activeDaysKey = 'active_days';
  static const String _stepGoalKey = 'step_goal';
  static const String _waterGoalKey = 'water_goal';
  static const String _calorieGoalKey = 'calorie_goal';
  static const String _sleepGoalKey = 'sleep_goal';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _themeModeKey = 'theme_mode';

  // Getters - General settings
  bool get useMetricUnits => _useMetricUnits;
  bool get enableNotifications => _enableNotifications;
  bool get darkMode => _darkMode;
  bool get isDarkMode => _darkMode || _themeMode == ThemeMode.dark;
  String get timeFormat => _timeFormat;
  String get dateFormat => _dateFormat;
  int get reminderTimeMinutes => _reminderTime;
  List<String> get activeDays => _activeDays;
  
  // Getters - Goals
  int get stepGoal => _stepGoal;
  int get waterGoal => _waterGoal;
  int get calorieGoal => _calorieGoal;
  int get sleepGoal => _sleepGoal;
  
  // Getters - Reminders
  bool get reminderEnabled => _reminderEnabled;
  
  // Get the theme mode based on dark mode setting
  ThemeMode get themeMode => _themeMode;

  // Return formatted reminder time
  String get formattedReminderTime {
    final hours = (_reminderTime ~/ 60).toString().padLeft(2, '0');
    final minutes = (_reminderTime % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  // Constructor - load settings from SharedPreferences
  SettingsProvider() {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load General settings
      _useMetricUnits = prefs.getBool(_useMetricUnitsKey) ?? true;
      _enableNotifications = prefs.getBool(_enableNotificationsKey) ?? true;
      _darkMode = prefs.getBool(_darkModeKey) ?? false;
      _timeFormat = prefs.getString(_timeFormatKey) ?? '24h';
      _dateFormat = prefs.getString(_dateFormatKey) ?? 'yyyy-MM-dd';
      _reminderTime = prefs.getInt(_reminderTimeKey) ?? 20 * 60; // Default 8:00 PM
      _activeDays = prefs.getStringList(_activeDaysKey) ?? 
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      // Load theme mode
      final themeModeIndex = prefs.getInt(_themeModeKey);
      if (themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex <= 2) {
        _themeMode = ThemeMode.values[themeModeIndex];
      } else {
        _themeMode = _darkMode ? ThemeMode.dark : ThemeMode.light;
      }
      
      // Load Goals
      _stepGoal = prefs.getInt(_stepGoalKey) ?? 10000;
      _waterGoal = prefs.getInt(_waterGoalKey) ?? 2000;
      _calorieGoal = prefs.getInt(_calorieGoalKey) ?? 2000;
      _sleepGoal = prefs.getInt(_sleepGoalKey) ?? 480;
      
      // Load Reminders
      _reminderEnabled = prefs.getBool(_reminderEnabledKey) ?? false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Set measurement units (metric or imperial)
  Future<void> setUseMetricUnits(bool value) async {
    if (_useMetricUnits == value) return;
    
    _useMetricUnits = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useMetricUnitsKey, value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving metric units setting: $e');
    }
  }

  // Toggle units between metric and imperial
  Future<void> toggleMetricUnits() async {
    await setUseMetricUnits(!_useMetricUnits);
  }

  // Set notifications enabled/disabled
  Future<void> setEnableNotifications(bool value) async {
    if (_enableNotifications == value) return;
    
    _enableNotifications = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enableNotificationsKey, value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving notifications setting: $e');
    }
  }

  // Toggle notifications enabled/disabled
  Future<void> toggleNotifications() async {
    await setEnableNotifications(!_enableNotifications);
  }

  // Set dark mode enabled/disabled
  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    
    _darkMode = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving dark mode setting: $e');
    }
  }

  // Toggle dark mode enabled/disabled
  Future<void> toggleDarkMode() async {
    await setDarkMode(!_darkMode);
  }

  // Set time format (12h or 24h)
  Future<void> setTimeFormat(String value) async {
    if (_timeFormat == value) return;
    
    _timeFormat = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timeFormatKey, value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving time format setting: $e');
    }
  }

  // Set date format
  Future<void> setDateFormat(String value) async {
    if (_dateFormat == value) return;
    
    _dateFormat = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateFormatKey, value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving date format setting: $e');
    }
  }

  // Set reminder time
  Future<void> setReminderTime(int hours, int minutes) async {
    final newTime = hours * 60 + minutes;
    if (_reminderTime == newTime) return;
    
    _reminderTime = newTime;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_reminderTimeKey, newTime);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving reminder time setting: $e');
    }
  }

  // Set active days for reminders
  Future<void> setActiveDays(List<String> days) async {
    if (_activeDays.length == days.length && 
        _activeDays.every((day) => days.contains(day))) return;
    
    _activeDays = List.from(days);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_activeDaysKey, days);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving active days setting: $e');
    }
  }

  // Toggle a specific day in active days
  Future<void> toggleActiveDay(String day) async {
    final newDays = List<String>.from(_activeDays);
    
    if (newDays.contains(day)) {
      newDays.remove(day);
    } else {
      newDays.add(day);
    }
    
    await setActiveDays(newDays);
  }

  // Set theme mode (light, dark, system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    // Update dark mode based on theme mode for backward compatibility
    if (mode == ThemeMode.dark) {
      _darkMode = true;
    } else if (mode == ThemeMode.light) {
      _darkMode = false;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
      await prefs.setBool(_darkModeKey, _darkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
  
  // Set step goal
  Future<void> setStepGoal(int steps) async {
    if (_stepGoal == steps) return;
    
    _stepGoal = steps;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_stepGoalKey, steps);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving step goal: $e');
    }
  }
  
  // Set water goal (in ml)
  Future<void> setWaterGoal(int ml) async {
    if (_waterGoal == ml) return;
    
    _waterGoal = ml;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_waterGoalKey, ml);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving water goal: $e');
    }
  }
  
  // Set calorie goal
  Future<void> setCalorieGoal(int calories) async {
    if (_calorieGoal == calories) return;
    
    _calorieGoal = calories;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_calorieGoalKey, calories);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving calorie goal: $e');
    }
  }
  
  // Set sleep goal (in minutes)
  Future<void> setSleepGoal(int minutes) async {
    if (_sleepGoal == minutes) return;
    
    _sleepGoal = minutes;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sleepGoalKey, minutes);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving sleep goal: $e');
    }
  }
  
  // Set reminder enabled/disabled and time
  Future<void> setReminder(bool enabled, [TimeOfDay? time]) async {
    bool changed = _reminderEnabled != enabled;
    
    _reminderEnabled = enabled;
    
    if (time != null) {
      final newTime = time.hour * 60 + time.minute;
      if (_reminderTime != newTime) {
        _reminderTime = newTime;
        changed = true;
      }
    }
    
    if (!changed) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, enabled);
      if (time != null) {
        await prefs.setInt(_reminderTimeKey, _reminderTime);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving reminder settings: $e');
    }
  }
  
  // Format TimeOfDay for display
  TimeOfDay get reminderTime {
    final hours = _reminderTime ~/ 60;
    final minutes = _reminderTime % 60;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_useMetricUnitsKey);
      await prefs.remove(_enableNotificationsKey);
      await prefs.remove(_darkModeKey);
      await prefs.remove(_timeFormatKey);
      await prefs.remove(_dateFormatKey);
      await prefs.remove(_reminderTimeKey);
      await prefs.remove(_activeDaysKey);
      await prefs.remove(_stepGoalKey);
      await prefs.remove(_waterGoalKey);
      await prefs.remove(_calorieGoalKey);
      await prefs.remove(_sleepGoalKey);
      await prefs.remove(_reminderEnabledKey);
      await prefs.remove(_themeModeKey);
      
      _useMetricUnits = true;
      _enableNotifications = true;
      _darkMode = false;
      _themeMode = ThemeMode.light;
      _timeFormat = '24h';
      _dateFormat = 'yyyy-MM-dd';
      _reminderTime = 20 * 60; // Default 8:00 PM
      _activeDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      _stepGoal = 10000;
      _waterGoal = 2000;
      _calorieGoal = 2000;
      _sleepGoal = 480;
      _reminderEnabled = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }
}