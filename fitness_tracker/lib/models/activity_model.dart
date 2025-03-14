import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_constants.dart';

class ActivityModel {
  final String id;
  final String userId;
  final String name;
  final String type;
  final int durationMinutes;
  final int caloriesBurned;
  final int? steps;
  final double? distance; // in kilometers
  final Map<String, dynamic>? additionalData;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.steps,
    this.distance,
    this.additionalData,
    this.notes,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a new activity with a unique ID
  factory ActivityModel.create({
    required String userId,
    required String name,
    required String type,
    required int durationMinutes,
    required int caloriesBurned,
    int? steps,
    double? distance,
    Map<String, dynamic>? additionalData,
    String? notes,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return ActivityModel(
      id: FirebaseFirestore.instance.collection('activities').doc().id,
      userId: userId,
      name: name,
      type: type,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      steps: steps,
      distance: distance,
      additionalData: additionalData,
      notes: notes,
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Convert an ActivityModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'steps': steps,
      'distance': distance,
      'additionalData': additionalData,
      'notes': notes,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create an ActivityModel from Firestore
  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      caloriesBurned: data['caloriesBurned'] ?? 0,
      steps: data['steps'],
      distance: data['distance'],
      additionalData: data['additionalData'],
      notes: data['notes'],
      date: data['date'] != null 
          ? (data['date'] as Timestamp).toDate() 
          : DateTime.now(),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  // Create a copy of ActivityModel with updated fields
  ActivityModel copyWith({
    String? name,
    String? type,
    int? durationMinutes,
    int? caloriesBurned,
    int? steps,
    double? distance,
    Map<String, dynamic>? additionalData,
    String? notes,
    DateTime? date,
  }) {
    return ActivityModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      additionalData: additionalData ?? this.additionalData,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Calculate calories burned based on MET value, duration, and weight
  static int calculateCaloriesBurned(
      String activityType, int durationMinutes, double weightKg) {
    // Get the MET value for the activity
    double metValue = 3.0; // Default moderate activity if not found

    final normalizedActivityType = activityType.toLowerCase().trim();
    
    // Try to find an exact match first
    if (AppConstants.exerciseMetValues.containsKey(normalizedActivityType)) {
      metValue = AppConstants.exerciseMetValues[normalizedActivityType]!;
    } else {
      // If no exact match, look for partial matches
      for (var key in AppConstants.exerciseMetValues.keys) {
        if (key.contains(normalizedActivityType) || 
            normalizedActivityType.contains(key)) {
          metValue = AppConstants.exerciseMetValues[key]!;
          break;
        }
      }
    }

    // Calories = MET * weight (kg) * duration (hours)
    return (metValue * weightKg * (durationMinutes / 60)).round();
  }

  // Get a formatted string for duration
  String getFormattedDuration() {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get a formatted date
  String getFormattedDate() {
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Get a formatted time
  String getFormattedTime() {
    return DateFormat('h:mm a').format(date);
  }

  // Calculate pace for distance activities (min/km)
  String? getFormattedPace() {
    if (distance == null || distance! <= 0) return null;
    
    final paceMinutesPerKm = durationMinutes / distance!;
    final paceMinutes = paceMinutesPerKm.floor();
    final paceSeconds = ((paceMinutesPerKm - paceMinutes) * 60).round();
    
    return '$paceMinutes:${paceSeconds.toString().padLeft(2, '0')} /km';
  }

  // Get a formatted version of the additional data
  Map<String, String> getFormattedAdditionalData() {
    final result = <String, String>{};
    
    if (additionalData == null) return result;
    
    additionalData!.forEach((key, value) {
      if (value is num) {
        result[key] = value.toString();
      } else if (value is DateTime) {
        result[key] = DateFormat('MMM d, yyyy').format(value);
      } else if (value is bool) {
        result[key] = value ? 'Yes' : 'No';
      } else if (value != null) {
        result[key] = value.toString();
      }
    });
    
    return result;
  }

  // Validate the activity
  bool isValid() {
    return name.isNotEmpty && 
           type.isNotEmpty && 
           durationMinutes > 0 &&
           caloriesBurned >= 0;
  }
}