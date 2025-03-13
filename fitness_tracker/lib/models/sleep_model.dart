import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SleepEntry {
  final String? id;
  final String userId;
  final DateTime date;
  final TimeOfDay bedTime;
  final TimeOfDay wakeTime;
  final int duration; // in minutes
  final int quality; // scale of 1-5
  final List<String> factors;
  final String notes;
  
  SleepEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.duration,
    required this.quality,
    this.factors = const [],
    this.notes = '',
  });
  
  // Create a SleepEntry from Firestore data
  factory SleepEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert Timestamp to DateTime
    final DateTime date = (data['date'] as Timestamp).toDate();
    
    // Convert bed and wake times
    final Map<String, dynamic> bedTimeMap = data['bedTime'];
    final Map<String, dynamic> wakeTimeMap = data['wakeTime'];
    
    final TimeOfDay bedTime = TimeOfDay(
      hour: bedTimeMap['hour'] ?? 22,
      minute: bedTimeMap['minute'] ?? 0,
    );
    
    final TimeOfDay wakeTime = TimeOfDay(
      hour: wakeTimeMap['hour'] ?? 6,
      minute: wakeTimeMap['minute'] ?? 0,
    );
    
    // Get factors and notes
    final List<String> factors = List<String>.from(data['factors'] ?? []);
    final String notes = data['notes'] ?? '';
    
    return SleepEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: date,
      bedTime: bedTime,
      wakeTime: wakeTime,
      duration: data['duration'] ?? 0,
      quality: data['quality'] ?? 3,
      factors: factors,
      notes: notes,
    );
  }
  
  // Convert SleepEntry to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'bedTime': {
        'hour': bedTime.hour,
        'minute': bedTime.minute,
      },
      'wakeTime': {
        'hour': wakeTime.hour,
        'minute': wakeTime.minute,
      },
      'duration': duration,
      'quality': quality,
      'factors': factors,
      'notes': notes,
    };
  }
  
  // Create a copy of the SleepEntry with optional changes
  SleepEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    TimeOfDay? bedTime,
    TimeOfDay? wakeTime,
    int? duration,
    int? quality,
    List<String>? factors,
    String? notes,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      factors: factors ?? this.factors,
      notes: notes ?? this.notes,
    );
  }
  
  // Get a formatted string of the sleep duration (e.g. "7h 30m")
  String getFormattedDuration() {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    return '${hours}h ${minutes}m';
  }
  
  // Get a formatted string of the bed time (e.g. "10:30 PM")
  String getFormattedBedTime() {
    final hour = bedTime.hour;
    final minute = bedTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourDisplay = hour % 12 == 0 ? 12 : hour % 12;
    return '$hourDisplay:${minute.toString().padLeft(2, '0')} $period';
  }
  
  // Get a formatted string of the wake time (e.g. "6:45 AM")
  String getFormattedWakeTime() {
    final hour = wakeTime.hour;
    final minute = wakeTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourDisplay = hour % 12 == 0 ? 12 : hour % 12;
    return '$hourDisplay:${minute.toString().padLeft(2, '0')} $period';
  }
  
  // Get a string representation of the sleep quality
  String getQualityText() {
    switch (quality) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }
  
  // Get a color representing the sleep quality
  Color getQualityColor() {
    switch (quality) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class SleepSummary {
  final double averageDuration; // in hours
  final double averageQuality; // scale of 1-5
  final Map<String, int> factorsFrequency;
  final int totalEntries;
  
  SleepSummary({
    required this.averageDuration,
    required this.averageQuality,
    required this.factorsFrequency,
    required this.totalEntries,
  });
  
  // Generate a summary from a list of sleep entries
  factory SleepSummary.fromEntries(List<SleepEntry> entries) {
    if (entries.isEmpty) {
      return SleepSummary(
        averageDuration: 0,
        averageQuality: 0,
        factorsFrequency: {},
        totalEntries: 0,
      );
    }
    
    // Calculate average duration in hours
    final totalDuration = entries.fold<int>(
      0, (sum, entry) => sum + entry.duration);
    final averageDuration = totalDuration / entries.length / 60; // Convert to hours
    
    // Calculate average quality
    final totalQuality = entries.fold<int>(
      0, (sum, entry) => sum + entry.quality);
    final averageQuality = totalQuality / entries.length;
    
    // Count factor frequency
    final Map<String, int> factorsFrequency = {};
    for (final entry in entries) {
      for (final factor in entry.factors) {
        factorsFrequency[factor] = (factorsFrequency[factor] ?? 0) + 1;
      }
    }
    
    return SleepSummary(
      averageDuration: averageDuration,
      averageQuality: averageQuality,
      factorsFrequency: factorsFrequency,
      totalEntries: entries.length,
    );
  }
  
  // Get the most common factor affecting sleep
  String? getMostCommonFactor() {
    if (factorsFrequency.isEmpty) {
      return null;
    }
    
    String? mostCommonFactor;
    int highestCount = 0;
    
    factorsFrequency.forEach((factor, count) {
      if (count > highestCount) {
        highestCount = count;
        mostCommonFactor = factor;
      }
    });
    
    return mostCommonFactor;
  }
  
  // Get a sleep recommendation based on the summary
  String getSleepRecommendation() {
    if (averageDuration < 6) {
      return 'Your sleep duration is below recommendations. Try to get 7-9 hours of sleep each night.';
    } else if (averageDuration > 10) {
      return 'You might be oversleeping. Adults typically need 7-9 hours of sleep.';
    }
    
    if (averageQuality < 3) {
      return 'Your sleep quality could be improved. Consider addressing external factors.';
    }
    
    final mostCommonFactor = getMostCommonFactor();
    if (mostCommonFactor != null) {
      switch (mostCommonFactor) {
        case 'Caffeine':
          return 'Caffeine appears to affect your sleep. Try to avoid caffeine at least 6 hours before bedtime.';
        case 'Late Meal':
          return 'Late meals may be affecting your sleep. Try to eat dinner at least 3 hours before bedtime.';
        case 'Screen Time':
          return 'Screen time before bed can affect sleep quality. Consider a screen-free hour before bedtime.';
        case 'Stress':
          return 'Stress seems to be affecting your sleep. Consider relaxation techniques before bed.';
        case 'Alcohol':
          return 'Alcohol can disrupt sleep cycles. Try to avoid alcohol close to bedtime.';
        case 'Late Work':
          return 'Working late may be affecting your sleep. Try to establish a consistent work cut-off time.';
        default:
          return 'Consider addressing ${mostCommonFactor} which appears to affect your sleep quality.';
      }
    }
    
    if (averageQuality >= 4 && averageDuration >= 7 && averageDuration <= 9) {
      return 'Great job! You\'re maintaining healthy sleep habits.';
    }
    
    return 'Aim for 7-9 hours of consistent, quality sleep each night.';
  }
}