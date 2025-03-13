import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';
import '../utils/constants.dart';

/// Service for tracking steps and other health metrics
class StepTrackingService {
  final HealthFactory _health = HealthFactory();
  
  /// Request permissions for health data
  Future<bool> requestPermissions() async {
    // Request permission for fitness tracking
    final permissionStatus = await Permission.activityRecognition.request();
    if (permissionStatus.isGranted) {
      // Request Health permissions
      final types = [
        HealthDataType.STEPS, 
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE
      ];
      
      try {
        final granted = await _health.requestAuthorization(types);
        return granted;
      } catch (e) {
        print('Error requesting health authorization: $e');
        return false;
      }
    }
    return false;
  }
  
  /// Check if health permissions are granted
  Future<bool> checkPermissions() async {
    final permissionStatus = await Permission.activityRecognition.status;
    if (permissionStatus.isGranted) {
      // Check Health permissions
      final types = [HealthDataType.STEPS];
      try {
        final granted = await _health.hasPermissions(types);
        return granted ?? false;
      } catch (e) {
        print('Error checking health permissions: $e');
        return false;
      }
    }
    return false;
  }
  
  /// Fetch step count for a specific date
  Future<int?> getStepCount(DateTime date) async {
    try {
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        final granted = await requestPermissions();
        if (!granted) {
          return null;
        }
      }
      
      final midnight = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      final endTime = date.day == now.day && date.month == now.month && date.year == now.year
          ? now
          : DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final steps = await _health.getTotalStepsInInterval(midnight, endTime);
      return steps;
    } catch (e) {
      print('Error fetching step count: $e');
      return null;
    }
  }
  
  /// Fetch step counts for a date range
  Future<Map<DateTime, int>> getStepCountsForRange(DateTime startDate, DateTime endDate) async {
    final result = <DateTime, int>{};
    
    try {
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        final granted = await requestPermissions();
        if (!granted) {
          return result;
        }
      }
      
      // Get steps for each day in the range
      for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = startDate.add(Duration(days: i));
        final day = DateTime(date.year, date.month, date.day);
        
        final steps = await getStepCount(day);
        if (steps != null) {
          result[day] = steps;
        }
      }
    } catch (e) {
      print('Error fetching step counts for range: $e');
    }
    
    return result;
  }
  
  /// Get active calories burned for a date
  Future<double?> getActiveCalories(DateTime date) async {
    try {
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        final granted = await requestPermissions();
        if (!granted) {
          return null;
        }
      }
      
      final midnight = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      final endTime = date.day == now.day && date.month == now.month && date.year == now.year
          ? now
          : DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final results = await _health.getHealthDataFromTypes(
        midnight, 
        endTime, 
        [HealthDataType.ACTIVE_ENERGY_BURNED]
      );
      
      if (results.isEmpty) return 0;
      
      // Sum up all active energy records
      double totalCalories = 0;
      for (var result in results) {
        totalCalories += double.tryParse(result.value.toString()) ?? 0;
      }
      
      return totalCalories;
    } catch (e) {
      print('Error fetching active calories: $e');
      return null;
    }
  }
  
  /// Get heart rate data for a date
  Future<List<HeartRateReading>> getHeartRateData(DateTime date) async {
    final results = <HeartRateReading>[];
    
    try {
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        final granted = await requestPermissions();
        if (!granted) {
          return results;
        }
      }
      
      final midnight = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      final endTime = date.day == now.day && date.month == now.month && date.year == now.year
          ? now
          : DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final readings = await _health.getHealthDataFromTypes(
        midnight, 
        endTime, 
        [HealthDataType.HEART_RATE]
      );
      
      for (var reading in readings) {
        final value = double.tryParse(reading.value.toString());
        if (value != null) {
          results.add(HeartRateReading(
            timestamp: reading.dateFrom,
            bpm: value.toInt(),
          ));
        }
      }
      
      // Sort by timestamp
      results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      print('Error fetching heart rate data: $e');
    }
    
    return results;
  }
  
  /// Generate an activity from step data
  Future<ActivityModel?> generateStepActivity(String userId, DateTime date) async {
    final steps = await getStepCount(date);
    if (steps == null || steps <= 0) return null;
    
    final calories = await getActiveCalories(date) ?? (steps * 0.04).round(); // Estimate calories if not available
    
    // Estimate distance based on step count (average stride length)
    final distance = steps * 0.0007; // Approximately 0.7m per step
    
    return ActivityModel(
      userId: userId,
      name: 'Daily Steps',
      type: ActivityTypes.walking,
      duration: (steps ~/ 100) * 1, // Estimate: ~100 steps per minute
      caloriesBurned: calories.round(),
      steps: steps,
      distance: distance,
      date: date,
    );
  }
  
  /// Save current step count to preferences for tracking
  Future<void> saveCurrentStepCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final steps = await getStepCount(today);
      if (steps != null) {
        await prefs.setInt('current_step_count', steps);
        await prefs.setString('step_count_timestamp', now.toIso8601String());
      }
    } catch (e) {
      print('Error saving current step count: $e');
    }
  }
  
  /// Get additional steps since last save
  Future<int> getAdditionalStepsSinceLastSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastStepCount = prefs.getInt('current_step_count') ?? 0;
      final lastTimestampStr = prefs.getString('step_count_timestamp');
      
      if (lastTimestampStr == null) return 0;
      
      final lastTimestamp = DateTime.parse(lastTimestampStr);
      final now = DateTime.now();
      
      // If last save was on a different day, return 0
      if (lastTimestamp.day != now.day || 
          lastTimestamp.month != now.month || 
          lastTimestamp.year != now.year) {
        return 0;
      }
      
      final today = DateTime(now.year, now.month, now.day);
      final currentSteps = await getStepCount(today) ?? 0;
      
      return currentSteps - lastStepCount;
    } catch (e) {
      print('Error getting additional steps: $e');
      return 0;
    }
  }
}

/// Heart rate reading with timestamp and BPM value
class HeartRateReading {
  final DateTime timestamp;
  final int bpm;
  
  HeartRateReading({
    required this.timestamp,
    required this.bpm,
  });
}