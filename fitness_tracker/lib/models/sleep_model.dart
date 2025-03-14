import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SleepModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int? deepSleepMinutes;
  final int? lightSleepMinutes;
  final int? remSleepMinutes;
  final int? awakeMinutes;
  final int? quality; // 1-100 scale
  final String? notes;
  final Map<String, dynamic>? additionalData;
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.deepSleepMinutes,
    this.lightSleepMinutes,
    this.remSleepMinutes,
    this.awakeMinutes,
    this.quality,
    this.notes,
    this.additionalData,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a new sleep entry with a unique ID
  factory SleepModel.create({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    int? deepSleepMinutes,
    int? lightSleepMinutes,
    int? remSleepMinutes,
    int? awakeMinutes,
    int? quality,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    final now = DateTime.now();
    
    // Calculate duration in minutes
    final durationMinutes = endTime.difference(startTime).inMinutes;
    
    return SleepModel(
      id: FirebaseFirestore.instance.collection('sleep').doc().id,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      deepSleepMinutes: deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes,
      remSleepMinutes: remSleepMinutes,
      awakeMinutes: awakeMinutes,
      quality: quality,
      notes: notes,
      additionalData: additionalData,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create a sleep entry with only duration
  factory SleepModel.createWithDuration({
    required String userId,
    required DateTime date,
    required int durationMinutes,
    int? quality,
    String? notes,
  }) {
    final now = DateTime.now();
    
    // Set the start time to 10:00 PM on the provided date
    final startTime = DateTime(date.year, date.month, date.day, 22, 0);
    
    // Calculate the end time based on the duration
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    
    return SleepModel(
      id: FirebaseFirestore.instance.collection('sleep').doc().id,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      quality: quality,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Convert a SleepModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'deepSleepMinutes': deepSleepMinutes,
      'lightSleepMinutes': lightSleepMinutes,
      'remSleepMinutes': remSleepMinutes,
      'awakeMinutes': awakeMinutes,
      'quality': quality,
      'notes': notes,
      'additionalData': additionalData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a SleepModel from Firestore
  factory SleepModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SleepModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 0,
      deepSleepMinutes: data['deepSleepMinutes'],
      lightSleepMinutes: data['lightSleepMinutes'],
      remSleepMinutes: data['remSleepMinutes'],
      awakeMinutes: data['awakeMinutes'],
      quality: data['quality'],
      notes: data['notes'],
      additionalData: data['additionalData'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create a copy of SleepModel with updated fields
  SleepModel copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? deepSleepMinutes,
    int? lightSleepMinutes,
    int? remSleepMinutes,
    int? awakeMinutes,
    int? quality,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    // If start or end time changes, recalculate duration
    final newStartTime = startTime ?? this.startTime;
    final newEndTime = endTime ?? this.endTime;
    final calculatedDuration = newEndTime.difference(newStartTime).inMinutes;
    
    // Use provided duration or calculated one
    final newDuration = durationMinutes ?? calculatedDuration;
    
    return SleepModel(
      id: id,
      userId: userId,
      startTime: newStartTime,
      endTime: newEndTime,
      durationMinutes: newDuration,
      deepSleepMinutes: deepSleepMinutes ?? this.deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes ?? this.lightSleepMinutes,
      remSleepMinutes: remSleepMinutes ?? this.remSleepMinutes,
      awakeMinutes: awakeMinutes ?? this.awakeMinutes,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Get a formatted date for the sleep start
  String getFormattedDate() {
    return DateFormat('MMM d, yyyy').format(startTime);
  }

  // Get a formatted time for sleep start and end
  String getFormattedTimeRange() {
    return '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
  }

  // Get sleep duration as hours and minutes
  String getFormattedDuration() {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get sleep efficiency percentage (time asleep vs time in bed)
  double? getSleepEfficiency() {
    // Sleep efficiency = (total sleep time / time in bed) * 100
    if (deepSleepMinutes == null || 
        lightSleepMinutes == null || 
        remSleepMinutes == null) {
      return null;
    }
    
    final totalSleepMinutes = 
        (deepSleepMinutes ?? 0) + 
        (lightSleepMinutes ?? 0) + 
        (remSleepMinutes ?? 0);
    
    return (totalSleepMinutes / durationMinutes) * 100;
  }

  // Get the quality description
  String? getQualityDescription() {
    if (quality == null) return null;
    
    if (quality! >= 80) {
      return 'Excellent';
    } else if (quality! >= 60) {
      return 'Good';
    } else if (quality! >= 40) {
      return 'Average';
    } else if (quality! >= 20) {
      return 'Poor';
    } else {
      return 'Very Poor';
    }
  }

  // Validate the sleep entry
  bool isValid() {
    return userId.isNotEmpty && 
           durationMinutes > 0 &&
           startTime.isBefore(endTime);
  }
}