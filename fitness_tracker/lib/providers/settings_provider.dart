import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage application settings
class SettingsProvider extends ChangeNotifier {
  // Default values
  bool _useMetricUnits = true;
  bool _enableNotifications = true;
  bool _darkMode = false;
  String _timeFormat = '24h';
  String _dateFormat = 'yyyy-MM-dd';
  int _reminderTime = 20 * 60; // Default 8:00 PM in minutes from midnight
  List<String> _activeDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  // Keys for SharedPreferences
  static const String _useMetricUnitsKey = 'use_metric_units';
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _darkModeKey = 'dark_mode';
  static const String _timeFormatKey = 'time_format';
  static const String _dateFormatKey = 'date_format';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _activeDaysKey = 'active_days';

  // Getters
  bool get useMetricUnits => _useMetricUnits;
  bool get enableNotifications => _enableNotifications;
  bool get darkMode => _darkMode;
  String get timeFormat => _timeFormat;
  String get dateFormat => _dateFormat;
  int get reminderTime => _reminderTime;
  List<String> get activeDays => _activeDays;

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
      
      _useMetricUnits = prefs.getBool(_useMetricUnitsKey) ?? true;
      _enableNotifications = prefs.getBool(_enableNotificationsKey) ?? true;
      _darkMode = prefs.getBool(_darkModeKey) ?? false;
      _timeFormat = prefs.getString(_timeFormatKey) ?? '24h';
      _dateFormat = prefs.getString(_dateFormatKey) ?? 'yyyy-MM-dd';
      _reminderTime = prefs.getInt(_reminderTimeKey) ?? 20 * 60; // Default 8:00 PM
      _activeDays = prefs.getStringList(_activeDaysKey) ?? 
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
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
      
      _useMetricUnits = true;
      _enableNotifications = true;
      _darkMode = false;
      _timeFormat = '24h';
      _dateFormat = 'yyyy-MM-dd';
      _reminderTime = 20 * 60; // Default 8:00 PM
      _activeDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }
}