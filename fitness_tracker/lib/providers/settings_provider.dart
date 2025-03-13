import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMetricSystem = true;
  String _timeFormat = AppConstants.timeFormat24h;
  bool _notificationsEnabled = true;
  Map<String, bool> _notificationChannels = {
    AppConstants.notificationChannelWorkouts: true,
    AppConstants.notificationChannelHabits: true,
    AppConstants.notificationChannelWater: true,
    AppConstants.notificationChannelMeals: true,
  };
  
  // Goals
  int _stepsGoal = AppConstants.defaultStepsGoal;
  int _caloriesGoal = AppConstants.defaultCalorieGoal;
  int _waterGoal = AppConstants.defaultWaterGoal;
  int _sleepGoal = AppConstants.defaultSleepGoal;
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get useMetricSystem => _useMetricSystem;
  String get timeFormat => _timeFormat;
  bool get notificationsEnabled => _notificationsEnabled;
  Map<String, bool> get notificationChannels => _notificationChannels;
  int get stepsGoal => _stepsGoal;
  int get caloriesGoal => _caloriesGoal;
  int get waterGoal => _waterGoal;
  int get sleepGoal => _sleepGoal;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    // Load measurement system
    _useMetricSystem = prefs.getBool('use_metric_system') ?? true;
    
    // Load time format
    _timeFormat = prefs.getString('time_format') ?? AppConstants.timeFormat24h;
    
    // Load notification settings
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    
    // Load notification channels
    final workoutsEnabled = prefs.getBool('notification_workouts') ?? true;
    final habitsEnabled = prefs.getBool('notification_habits') ?? true;
    final waterEnabled = prefs.getBool('notification_water') ?? true;
    final mealsEnabled = prefs.getBool('notification_meals') ?? true;
    
    _notificationChannels = {
      AppConstants.notificationChannelWorkouts: workoutsEnabled,
      AppConstants.notificationChannelHabits: habitsEnabled,
      AppConstants.notificationChannelWater: waterEnabled,
      AppConstants.notificationChannelMeals: mealsEnabled,
    };
    
    // Load goals
    _stepsGoal = prefs.getInt('steps_goal') ?? AppConstants.defaultStepsGoal;
    _caloriesGoal = prefs.getInt('calories_goal') ?? AppConstants.defaultCalorieGoal;
    _waterGoal = prefs.getInt('water_goal') ?? AppConstants.defaultWaterGoal;
    _sleepGoal = prefs.getInt('sleep_goal') ?? AppConstants.defaultSleepGoal;
    
    notifyListeners();
  }
  
  // Theme mode setter
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    
    if (mode == ThemeMode.light) {
      themeModeString = 'light';
    } else if (mode == ThemeMode.dark) {
      themeModeString = 'dark';
    } else {
      themeModeString = 'system';
    }
    
    await prefs.setString('theme_mode', themeModeString);
  }
  
  // Measurement system setter
  Future<void> setUseMetricSystem(bool useMetric) async {
    if (_useMetricSystem == useMetric) return;
    
    _useMetricSystem = useMetric;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_metric_system', useMetric);
  }
  
  // Time format setter
  Future<void> setTimeFormat(String format) async {
    if (_timeFormat == format) return;
    
    _timeFormat = format;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('time_format', format);
  }
  
  // Notifications enabled setter
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    
    _notificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }
  
  // Notification channel setter
  Future<void> setNotificationChannelEnabled(String channel, bool enabled) async {
    if (_notificationChannels[channel] == enabled) return;
    
    _notificationChannels[channel] = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_${channel}', enabled);
  }
  
  // Steps goal setter
  Future<void> setStepsGoal(int goal) async {
    if (goal <= 0 || _stepsGoal == goal) return;
    
    _stepsGoal = goal;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_goal', goal);
  }
  
  // Calories goal setter
  Future<void> setCaloriesGoal(int goal) async {
    if (goal <= 0 || _caloriesGoal == goal) return;
    
    _caloriesGoal = goal;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calories_goal', goal);
  }
  
  // Water goal setter
  Future<void> setWaterGoal(int goal) async {
    if (goal <= 0 || _waterGoal == goal) return;
    
    _waterGoal = goal;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal', goal);
  }
  
  // Sleep goal setter
  Future<void> setSleepGoal(int goal) async {
    if (goal <= 0 || _sleepGoal == goal) return;
    
    _sleepGoal = goal;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sleep_goal', goal);
  }
  
  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _useMetricSystem = true;
    _timeFormat = AppConstants.timeFormat24h;
    _notificationsEnabled = true;
    _notificationChannels = {
      AppConstants.notificationChannelWorkouts: true,
      AppConstants.notificationChannelHabits: true,
      AppConstants.notificationChannelWater: true,
      AppConstants.notificationChannelMeals: true,
    };
    _stepsGoal = AppConstants.defaultStepsGoal;
    _caloriesGoal = AppConstants.defaultCalorieGoal;
    _waterGoal = AppConstants.defaultWaterGoal;
    _sleepGoal = AppConstants.defaultSleepGoal;
    
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}