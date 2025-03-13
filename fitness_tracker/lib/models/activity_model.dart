import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

/// Represents a physical activity or workout in the fitness tracking app
class ActivityModel {
  final String? id;
  final String userId;
  final String name;
  final String type; // running, cycling, swimming, etc.
  final int duration; // in minutes
  final int caloriesBurned;
  final int? steps;
  final double? distance; // in kilometers
  final DateTime date;
  final String? notes;
  final Map<String, dynamic>? additionalData;

  ActivityModel({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.duration,
    required this.caloriesBurned,
    this.steps,
    this.distance,
    required this.date,
    this.notes,
    this.additionalData,
  });

  /// Create an ActivityModel from a map (typically from Firestore)
  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? ActivityTypes.other,
      duration: map['duration']?.toInt() ?? 0,
      caloriesBurned: map['caloriesBurned']?.toInt() ?? 0,
      steps: map['steps']?.toInt(),
      distance: map['distance']?.toDouble(),
      date: map['date'] != null 
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      notes: map['notes'],
      additionalData: map['additionalData'],
    );
  }

  /// Convert this ActivityModel to a map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'steps': steps,
      'distance': distance,
      'date': date,
      'notes': notes,
      'additionalData': additionalData,
    };
  }

  /// Create a copy of this ActivityModel with some values replaced
  ActivityModel copyWith({
    String? userId,
    String? name,
    String? type,
    int? duration,
    int? caloriesBurned,
    int? steps,
    double? distance,
    DateTime? date,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    return ActivityModel(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Get a formatted date string
  String getFormattedDate([String format = DateTimeFormats.monthDayYear]) {
    return DateFormat(format).format(date);
  }

  /// Get the pace (time per km) if distance is available
  String? getPace() {
    if (distance == null || distance! <= 0 || duration <= 0) {
      return null;
    }
    
    // Calculate minutes per kilometer
    final minutesPerKm = duration / distance!;
    final minutes = minutesPerKm.floor();
    final seconds = ((minutesPerKm - minutes) * 60).round();
    
    return '$minutes:${seconds.toString().padLeft(2, '0')} min/km';
  }

  /// Get calories burned per minute
  double getCaloriesPerMinute() {
    if (duration <= 0) return 0;
    return caloriesBurned / duration;
  }

  /// Calculate MET (Metabolic Equivalent of Task) value
  double getMET(double weightInKg) {
    if (weightInKg <= 0 || duration <= 0) return 0;
    
    // MET formula: calories / (weight in kg * hours of activity)
    final hours = duration / 60;
    return caloriesBurned / (weightInKg * hours);
  }

  /// Check if the activity is valid
  bool isValid() {
    return name.isNotEmpty && 
           duration > 0 && 
           caloriesBurned >= 0 && 
           (steps == null || steps! >= 0) &&
           (distance == null || distance! >= 0);
  }
}

/// Extension for operations on lists of ActivityModel objects
extension ActivityModelListExtension on List<ActivityModel> {
  /// Sort activities by date (most recent first)
  List<ActivityModel> sortByDateDescending() {
    return [...this]..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Sort activities by date (oldest first)
  List<ActivityModel> sortByDateAscending() {
    return [...this]..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Filter activities by type
  List<ActivityModel> filterByType(String type) {
    return where((activity) => activity.type == type).toList();
  }

  /// Filter activities by date range
  List<ActivityModel> filterByDateRange(DateTime startDate, DateTime endDate) {
    return where((activity) => 
      activity.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
      activity.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  /// Get total calories burned
  int getTotalCalories() {
    return fold(0, (sum, activity) => sum + activity.caloriesBurned);
  }

  /// Get total duration in minutes
  int getTotalDuration() {
    return fold(0, (sum, activity) => sum + activity.duration);
  }

  /// Get total steps (if available)
  int getTotalSteps() {
    return fold(0, (sum, activity) => sum + (activity.steps ?? 0));
  }

  /// Get total distance in kilometers (if available)
  double getTotalDistance() {
    return fold(0.0, (sum, activity) => sum + (activity.distance ?? 0));
  }

  /// Group activities by type and count them
  Map<String, int> countByType() {
    final result = <String, int>{};
    for (final activity in this) {
      result[activity.type] = (result[activity.type] ?? 0) + 1;
    }
    return result;
  }

  /// Get activities by day of week
  Map<int, List<ActivityModel>> groupByDayOfWeek() {
    final result = <int, List<ActivityModel>>{};
    for (final activity in this) {
      final dayOfWeek = activity.date.weekday;
      if (!result.containsKey(dayOfWeek)) {
        result[dayOfWeek] = [];
      }
      result[dayOfWeek]!.add(activity);
    }
    return result;
  }
}