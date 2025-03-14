import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different sleep quality levels
enum SleepQuality {
  poor,
  fair, 
  good,
  excellent
}

/// Extension to provide helper methods for SleepQuality enum
extension SleepQualityExtension on SleepQuality {
  String get displayName {
    switch (this) {
      case SleepQuality.poor:
        return 'Poor';
      case SleepQuality.fair:
        return 'Fair';
      case SleepQuality.good:
        return 'Good';
      case SleepQuality.excellent:
        return 'Excellent';
    }
  }
  
  int get value {
    switch (this) {
      case SleepQuality.poor:
        return 1;
      case SleepQuality.fair:
        return 2;
      case SleepQuality.good:
        return 3;
      case SleepQuality.excellent:
        return 4;
    }
  }
  
  static SleepQuality fromString(String value) {
    return SleepQuality.values.firstWhere(
      (quality) => quality.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => SleepQuality.fair,
    );
  }
  
  static SleepQuality fromValue(int value) {
    switch (value) {
      case 1:
        return SleepQuality.poor;
      case 2:
        return SleepQuality.fair;
      case 3:
        return SleepQuality.good;
      case 4:
        return SleepQuality.excellent;
      default:
        return SleepQuality.fair;
    }
  }
}

/// Model class for sleep entries
class SleepEntry {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int durationMinutes;
  final SleepQuality quality;
  final int? deepSleepMinutes;
  final int? lightSleepMinutes;
  final int? remSleepMinutes;
  final int? awakeMinutes;
  final List<String>? factors; // External factors affecting sleep
  final String? notes;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  SleepEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.durationMinutes,
    required this.quality,
    this.deepSleepMinutes,
    this.lightSleepMinutes,
    this.remSleepMinutes,
    this.awakeMinutes,
    this.factors,
    this.notes,
    this.isSynced = false,
    required this.createdAt,
    this.updatedAt,
  });
  
  /// Create a SleepEntry from Firestore document
  factory SleepEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<String>? factors;
    if (data['factors'] != null) {
      factors = List<String>.from(data['factors']);
    }
    
    return SleepEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      bedTime: (data['bedTime'] as Timestamp).toDate(),
      wakeTime: (data['wakeTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 0,
      quality: SleepQualityExtension.fromString(data['quality'] ?? 'fair'),
      deepSleepMinutes: data['deepSleepMinutes'],
      lightSleepMinutes: data['lightSleepMinutes'],
      remSleepMinutes: data['remSleepMinutes'],
      awakeMinutes: data['awakeMinutes'],
      factors: factors,
      notes: data['notes'],
      isSynced: data['isSynced'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }
  
  /// Convert SleepEntry to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'bedTime': Timestamp.fromDate(bedTime),
      'wakeTime': Timestamp.fromDate(wakeTime),
      'durationMinutes': durationMinutes,
      'quality': quality.toString().split('.').last,
      'deepSleepMinutes': deepSleepMinutes,
      'lightSleepMinutes': lightSleepMinutes,
      'remSleepMinutes': remSleepMinutes,
      'awakeMinutes': awakeMinutes,
      'factors': factors,
      'notes': notes,
      'isSynced': isSynced,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
  
  /// Create a copy with updated fields
  SleepEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? durationMinutes,
    SleepQuality? quality,
    int? deepSleepMinutes,
    int? lightSleepMinutes,
    int? remSleepMinutes,
    int? awakeMinutes,
    List<String>? factors,
    String? notes,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quality: quality ?? this.quality,
      deepSleepMinutes: deepSleepMinutes ?? this.deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes ?? this.lightSleepMinutes,
      remSleepMinutes: remSleepMinutes ?? this.remSleepMinutes,
      awakeMinutes: awakeMinutes ?? this.awakeMinutes,
      factors: factors ?? this.factors,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Calculate sleep efficiency percentage (time asleep vs. time in bed)
  double get sleepEfficiency {
    if (durationMinutes == 0) return 0;
    final asleepMinutes = durationMinutes - (awakeMinutes ?? 0);
    return (asleepMinutes / durationMinutes) * 100;
  }
  
  /// Check if sleep duration meets recommended guidelines
  bool get meetsRecommendedDuration {
    // Most adults need 7-9 hours (420-540 minutes)
    return durationMinutes >= 420 && durationMinutes <= 540;
  }
  
  /// Get sleep cycle count (rough estimate - average cycle is 90 minutes)
  int get estimatedSleepCycles {
    return (durationMinutes / 90).floor();
  }
}