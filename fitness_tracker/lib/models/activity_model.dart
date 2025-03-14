import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different types of physical activities
enum ActivityType {
  walking,
  running,
  cycling,
  swimming,
  weights,
  yoga,
  hiit,
  pilates,
  other
}

/// Extension to provide helper methods for ActivityType enum
extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.swimming:
        return 'Swimming';
      case ActivityType.weights:
        return 'Weights';
      case ActivityType.yoga:
        return 'Yoga';
      case ActivityType.hiit:
        return 'HIIT';
      case ActivityType.pilates:
        return 'Pilates';
      case ActivityType.other:
        return 'Other';
    }
  }
  
  String get icon {
    switch (this) {
      case ActivityType.walking:
        return 'directions_walk';
      case ActivityType.running:
        return 'directions_run';
      case ActivityType.cycling:
        return 'directions_bike';
      case ActivityType.swimming:
        return 'pool';
      case ActivityType.weights:
        return 'fitness_center';
      case ActivityType.yoga:
        return 'self_improvement';
      case ActivityType.hiit:
        return 'timer';
      case ActivityType.pilates:
        return 'accessibility_new';
      case ActivityType.other:
        return 'sports';
    }
  }
  
  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.toString().split('.').last == value.toLowerCase(),
      orElse: () => ActivityType.other,
    );
  }
}

/// Model class for physical activities
class Activity {
  final String id;
  final String userId;
  final String name;
  final ActivityType type;
  final int durationMinutes;
  final int caloriesBurned;
  final double? distance; // in kilometers
  final int? steps;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final List<String>? photoUrls;
  final Map<String, dynamic>? additionalData;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  Activity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.startTime,
    this.distance,
    this.steps,
    this.endTime,
    this.notes,
    this.photoUrls,
    this.additionalData,
    this.isSynced = false,
    required this.createdAt,
    this.updatedAt,
  });
  
  /// Create an Activity from Firestore document
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: ActivityTypeExtension.fromString(data['type'] ?? 'other'),
      durationMinutes: data['durationMinutes'] ?? 0,
      caloriesBurned: data['caloriesBurned'] ?? 0,
      distance: data['distance']?.toDouble(),
      steps: data['steps'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      notes: data['notes'],
      photoUrls: data['photoUrls'] != null 
          ? List<String>.from(data['photoUrls']) 
          : null,
      additionalData: data['additionalData'],
      isSynced: data['isSynced'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }
  
  /// Convert Activity to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'distance': distance,
      'steps': steps,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'notes': notes,
      'photoUrls': photoUrls,
      'additionalData': additionalData,
      'isSynced': isSynced,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
  
  /// Create a copy of Activity with updated fields
  Activity copyWith({
    String? id,
    String? userId,
    String? name,
    ActivityType? type,
    int? durationMinutes,
    int? caloriesBurned,
    double? distance,
    int? steps,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    List<String>? photoUrls,
    Map<String, dynamic>? additionalData,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distance: distance ?? this.distance,
      steps: steps ?? this.steps,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      additionalData: additionalData ?? this.additionalData,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}