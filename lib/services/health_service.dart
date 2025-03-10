import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// Service to handle health data integration
class HealthService {
  // Singleton implementation
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();
  
  // Key for preferences
  static const String _healthPermissionKey = 'health_permission_granted';
  static const String _lastSyncKey = 'health_last_sync';
  
  // Mock data until health data plugin is integrated
  // In a real app, this would use health_connect or another plugin
  bool _permissionGranted = false;
  
  /// Initialize the health service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _permissionGranted = prefs.getBool(_healthPermissionKey) ?? false;
    
    // Check if permissions are still valid (they might be revoked in settings)
    if (_permissionGranted) {
      final status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        _permissionGranted = false;
        await prefs.setBool(_healthPermissionKey, false);
      }
    }
    
    Logger.logEvent('HealthService initialized', {'permissionGranted': _permissionGranted});
  }
  
  /// Request necessary permissions for health data
  Future<bool> requestPermissions() async {
    try {
      // Request activity recognition permission (for step counting)
      final status = await Permission.activityRecognition.request();
      _permissionGranted = status.isGranted;
      
      // Store permission status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_healthPermissionKey, _permissionGranted);
      
      Logger.logEvent('Health permissions requested', {'granted': _permissionGranted});
      return _permissionGranted;
    } catch (e, stack) {
      Logger.logError('Error requesting health permissions', e, stack);
      return false;
    }
  }
  
  /// Check if health permissions are granted
  Future<bool> hasPermissions() async {
    if (_permissionGranted) return true;
    
    try {
      final status = await Permission.activityRecognition.status;
      _permissionGranted = status.isGranted;
      return _permissionGranted;
    } catch (e) {
      Logger.logError('Error checking health permissions', e);
      return false;
    }
  }
  
  /// Get step count in the specified interval
  Future<int> getStepsInInterval(DateTime start, DateTime end) async {
    // In a real app, this would query a health data API/plugin
    // For now, we'll provide simulated data for demo purposes
    if (!await hasPermissions()) {
      return 0; // Can't access data without permissions
    }
    
    // Simple simulation for demo
    final hoursInPeriod = end.difference(start).inHours;
    final averageStepsPerHour = 500; // Average 12K steps per day ÷ 24 hours
    
    // Add some variability
    final stepCount = (hoursInPeriod * averageStepsPerHour * 
        (0.7 + (DateTime.now().millisecond % 60) / 100)).round();
    
    return stepCount;
  }
  
  /// Get average heart rate in the specified interval
  Future<double> getHeartRateInInterval(DateTime start, DateTime end) async {
    // In a real app, this would query a health data API/plugin
    if (!await hasPermissions()) {
      return 0.0;
    }
    
    // Simulate heart rate data (typically 60-100 bpm at rest)
    return 70.0 + (DateTime.now().second % 30);
  }
  
  /// Get active energy (calories) burned in the specified interval
  Future<double> getActiveEnergyInInterval(DateTime start, DateTime end) async {
    // In a real app, this would query a health data API/plugin
    if (!await hasPermissions()) {
      return 0.0;
    }
    
    // Simple simulation based on time period - average person burns ~2000 kcal/day
    final hoursInPeriod = end.difference(start).inHours;
    final baseHourlyCalories = 2000 / 24; // Base metabolic calories per hour
    
    // Add some activity calories with variability
    final activityMultiplier = 1.2 + (DateTime.now().millisecond % 100) / 100;
    
    return hoursInPeriod * baseHourlyCalories * activityMultiplier;
  }
  
  /// Sync health data with the backend
  Future<bool> syncHealthData() async {
    try {
      if (!await hasPermissions()) {
        return false;
      }
      
      // Get last sync time
      final prefs = await SharedPreferences.getInstance();
      final lastSync = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_lastSyncKey) ?? 
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch
      );
      
      // Update last sync time
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
      Logger.logEvent('Health data synced', {'lastSync': lastSync.toString()});
      return true;
    } catch (e, stack) {
      Logger.logError('Error syncing health data', e, stack);
      return false;
    }
  }
  
  /// Log a manual activity to the user's health data
  Future<bool> logManualActivity(Map<String, dynamic> activityData) async {
    try {
      // In a real app, we would save this to Firestore and local health data
      Logger.logEvent('Manual activity logged', activityData);
      return true;
    } catch (e, stack) {
      Logger.logError('Error logging manual activity', e, stack);
      return false;
    }
  }
  
  /// Start automatic activity tracking
  Future<bool> startAutoTracking() async {
    try {
      if (!await hasPermissions()) {
        return false;
      }
      
      // In a real app, we would start the device's activity tracking
      Logger.logEvent('Auto tracking started');
      return true;
    } catch (e, stack) {
      Logger.logError('Error starting auto tracking', e, stack);
      return false;
    }
  }
  
  /// Stop automatic activity tracking
  Future<bool> stopAutoTracking() async {
    try {
      // In a real app, we would stop the device's activity tracking
      Logger.logEvent('Auto tracking stopped');
      return true;
    } catch (e, stack) {
      Logger.logError('Error stopping auto tracking', e, stack);
      return false;
    }
  }
}