import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking steps using the device's pedometer sensor
class StepTrackingService {
  static const String _stepsKey = 'steps_data';
  static const String _lastResetDateKey = 'last_reset_date';
  
  Stream<StepCount>? _stepCountStream;
  StreamSubscription<StepCount>? _stepCountSubscription;
  int _todaySteps = 0;
  int _totalSteps = 0;
  bool _isInitialized = false;
  
  /// Check if the app has permission to track steps
  Future<bool> checkPermissions() async {
    if (await Permission.activityRecognition.isGranted) {
      _initializePedometer();
      return true;
    }
    return false;
  }
  
  /// Request permission to track steps
  Future<bool> requestPermissions() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _initializePedometer();
      return true;
    }
    return false;
  }
  
  /// Initialize the pedometer
  void _initializePedometer() {
    if (_isInitialized) return;
    
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream?.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: true,
    );
    
    _isInitialized = true;
  }
  
  /// Handle step count updates
  void _onStepCount(StepCount event) {
    _totalSteps = event.steps;
    _updateTodaySteps();
  }
  
  /// Handle step count errors
  void _onStepCountError(error) {
    print('Step count error: $error');
  }
  
  /// Update today's step count
  Future<void> _updateTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString(_lastResetDateKey) ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Check if we need to reset step count for a new day
    if (lastResetDate != today) {
      // Save yesterday's step count
      final stepsData = prefs.getStringList(_stepsKey) ?? [];
      if (lastResetDate.isNotEmpty) {
        stepsData.add('$lastResetDate:$_todaySteps');
        
        // Keep only the last 30 days of data
        if (stepsData.length > 30) {
          stepsData.removeAt(0);
        }
        
        await prefs.setStringList(_stepsKey, stepsData);
      }
      
      // Reset for today
      _todaySteps = 0;
      await prefs.setString(_lastResetDateKey, today);
    }
    
    // Update today's steps
    _todaySteps = _totalSteps;
  }
  
  /// Get step count for a specific date
  Future<int?> getStepCount(DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0];
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // If requesting today's step count, return the current count
    if (dateString == today) {
      return _todaySteps;
    }
    
    // Otherwise, retrieve from storage
    final prefs = await SharedPreferences.getInstance();
    final stepsData = prefs.getStringList(_stepsKey) ?? [];
    
    for (final data in stepsData) {
      final parts = data.split(':');
      if (parts.length == 2 && parts[0] == dateString) {
        return int.tryParse(parts[1]);
      }
    }
    
    return null;
  }
  
  /// Get step counts for a date range
  Future<Map<DateTime, int>> getStepCountRange(DateTime start, DateTime end) async {
    final Map<DateTime, int> result = {};
    final prefs = await SharedPreferences.getInstance();
    final stepsData = prefs.getStringList(_stepsKey) ?? [];
    
    // Process stored data
    for (final data in stepsData) {
      final parts = data.split(':');
      if (parts.length == 2) {
        try {
          final date = DateTime.parse(parts[0]);
          final steps = int.parse(parts[1]);
          
          if (date.isAfter(start.subtract(const Duration(days: 1))) && 
              date.isBefore(end.add(const Duration(days: 1)))) {
            result[date] = steps;
          }
        } catch (e) {
          print('Error parsing step data: $e');
        }
      }
    }
    
    // Add today's steps if within range
    final today = DateTime.now();
    if (today.isAfter(start.subtract(const Duration(days: 1))) && 
        today.isBefore(end.add(const Duration(days: 1)))) {
      result[today] = _todaySteps;
    }
    
    return result;
  }
  
  /// Get total step count for a date range
  Future<int> getTotalStepsForRange(DateTime start, DateTime end) async {
    final stepCounts = await getStepCountRange(start, end);
    return stepCounts.values.fold(0, (sum, steps) => sum + steps);
  }
  
  /// Dispose of the subscription
  void dispose() {
    _stepCountSubscription?.cancel();
  }
}