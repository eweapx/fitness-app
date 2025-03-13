import 'package:intl/intl.dart';

class ActivityModel {
  final String? id; // Firestore document ID (null for new activities)
  final String name;
  final String type; // Running, Cycling, Swimming, etc.
  final int duration; // in minutes
  final int calories;
  final int? steps;
  final double? distance; // in kilometers
  final String? notes;
  final DateTime date;
  final String userId; // Reference to user who created this activity

  static const List<String> validTypes = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Strength',
    'Yoga',
    'HIIT',
    'Other'
  ];

  ActivityModel({
    this.id,
    required this.name,
    required this.type,
    required this.duration,
    required this.calories,
    this.steps,
    this.distance,
    this.notes,
    required this.date,
    required this.userId,
  });

  // Check if activity has valid data
  bool isValid() {
    return name.isNotEmpty && 
           validTypes.contains(type) && 
           duration > 0 &&
           calories >= 0;
  }

  // Get formatted date string
  String getFormattedDate() {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  // Calculate calories per minute
  double get caloriesPerMinute {
    return duration > 0 ? calories / duration : 0;
  }

  // Get pace (minutes per km) for distance activities
  String get pace {
    if (distance == null || distance! <= 0) return 'N/A';
    
    final paceMinutes = duration / distance!;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    
    return '$minutes:${seconds.toString().padLeft(2, '0')} min/km';
  }

  // Get activity intensity level
  String get intensityLevel {
    final calsPerMin = caloriesPerMinute;
    
    if (calsPerMin < 5) {
      return 'Light';
    } else if (calsPerMin < 10) {
      return 'Moderate';
    } else {
      return 'Intense';
    }
  }

  // Convert Firestore data to ActivityModel
  factory ActivityModel.fromMap(String id, Map<String, dynamic> data) {
    return ActivityModel(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'Other',
      duration: data['duration'] ?? 0,
      calories: data['calories'] ?? 0,
      steps: data['steps'],
      distance: data['distance']?.toDouble(),
      notes: data['notes'],
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      userId: data['user_id'] ?? '',
    );
  }

  // Convert ActivityModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'duration': duration,
      'calories': calories,
      'steps': steps,
      'distance': distance,
      'notes': notes,
      'date': date,
      'user_id': userId,
    };
  }

  // Copy with method for updating activity properties
  ActivityModel copyWith({
    String? name,
    String? type,
    int? duration,
    int? calories,
    int? steps,
    double? distance,
    String? notes,
    DateTime? date,
    String? userId,
  }) {
    return ActivityModel(
      id: this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      userId: userId ?? this.userId,
    );
  }
}