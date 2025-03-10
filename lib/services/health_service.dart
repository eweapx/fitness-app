import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle health data interactions with device health APIs
class HealthService {
  final HealthFactory health = HealthFactory();
  
  // Types of health data to be requested
  static final List<HealthDataType> healthTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    // Include workout data for all platforms
    HealthDataType.DISTANCE_WALKING_RUNNING,
  ];

  /// Request necessary permissions to access health data
  Future<bool> requestPermissions(BuildContext context) async {
    // First check activity recognition permission (required for step data)
    if (!await Permission.activityRecognition.isGranted) {
      var status = await Permission.activityRecognition.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        _showPermissionDialog(context);
        return false;
      }
    }
    
    // Then request health data authorization
    try {
      return await health.requestAuthorization(healthTypes);
    } catch (e) {
      debugPrint('Error requesting health authorization: $e');
      return false;
    }
  }

  /// Show a dialog explaining why permissions are needed
  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This app needs activity recognition permissions to track your fitness data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Get steps within a time interval
  Future<int> getStepsInInterval(DateTime start, DateTime end) async {
    try {
      // Get step data points
      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        start, 
        end, 
        [HealthDataType.STEPS]
      );
      
      if (data.isEmpty) return 0;
      
      // Sum up step counts
      int steps = 0;
      for (var point in data) {
        steps += point.value.toInt();
      }
      
      return steps;
    } catch (e) {
      debugPrint('Failed to get steps: $e');
      return 0;
    }
  }

  /// Get heart rate within a time interval
  Future<double> getHeartRateInInterval(DateTime start, DateTime end) async {
    try {
      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        start, 
        end, 
        [HealthDataType.HEART_RATE]
      );
      
      if (data.isEmpty) return 0.0;
      
      double sum = 0.0;
      int count = 0;
      
      for (var point in data) {
        // Simply use the numeric value directly
        sum += point.value.toDouble();
        count++;
      }
      
      return count > 0 ? sum / count : 0.0;
    } catch (e) {
      debugPrint('Failed to get heart rate: $e');
      return 0.0;
    }
  }

  /// Get active energy burned within a time interval
  Future<double> getActiveEnergyInInterval(DateTime start, DateTime end) async {
    try {
      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        start, 
        end, 
        [HealthDataType.ACTIVE_ENERGY_BURNED]
      );
      
      if (data.isEmpty) return 0.0;
      
      double totalEnergy = 0.0;
      
      for (var point in data) {
        // Simply use the numeric value directly
        totalEnergy += point.value.toDouble();
      }
      
      return totalEnergy;
    } catch (e) {
      debugPrint('Failed to get active energy: $e');
      return 0.0;
    }
  }

  /// Get distance walked or run within a time interval
  Future<double> getDistanceInInterval(DateTime start, DateTime end) async {
    try {
      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        start, 
        end, 
        [HealthDataType.DISTANCE_WALKING_RUNNING]
      );
      
      if (data.isEmpty) return 0.0;
      
      double totalDistance = 0.0;
      
      for (var point in data) {
        // Simply use the numeric value directly
        totalDistance += point.value.toDouble();
      }
      
      return totalDistance;
    } catch (e) {
      debugPrint('Failed to get distance: $e');
      return 0.0;
    }
  }
  
  /// Calculate estimated calories burned based on available health data
  Future<int> calculateCaloriesBurnedToday() async {
    try {
      // Use today's timeframe
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Collect all the data
      int steps = await getStepsInInterval(today, now);
      double activeEnergy = await getActiveEnergyInInterval(today, now);
      
      // Return value from active energy if available, otherwise estimate from steps
      if (activeEnergy > 0) {
        return activeEnergy.round();
      } else {
        // Simple formula to estimate calories from steps (very approximate)
        return (steps * 0.04).round();
      }
    } catch (e) {
      debugPrint('Error calculating calories: $e');
      return 0;
    }
  }
  
  /// Get a summary of today's health data
  Future<Map<String, dynamic>> getTodayHealthSummary() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get all data in parallel
    final steps = await getStepsInInterval(today, now);
    final calories = await calculateCaloriesBurnedToday();
    final distance = await getDistanceInInterval(today, now);
    
    return {
      'steps': steps,
      'calories': calories,
      'distance': distance.toStringAsFixed(2),
      'lastUpdated': now.toString(),
    };
  }
}