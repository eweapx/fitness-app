enum HabitType { good, bad }
enum HabitFrequency { daily, weekly }

class Habit {
  final String id;
  final String userId;
  final String name;
  final String type; // 'good' or 'bad'
  final String frequency; // 'daily' or 'weekly'
  final List<bool> selectedDays; // For weekly frequency, days of week [M,T,W,T,F,S,S]
  final DateTime createdAt;
  final int streak;
  final int longestStreak;
  final String? lastCompletedDate; // Format: 'yyyy-MM-dd'
  final int? targetNumber; // For countable habits like glasses of water
  final String? notes;
  final String? reminderTime; // Format: 'HH:mm'

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.frequency,
    required this.selectedDays,
    required this.createdAt,
    required this.streak,
    required this.longestStreak,
    this.lastCompletedDate,
    this.targetNumber,
    this.notes,
    this.reminderTime,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      frequency: json['frequency'] as String,
      selectedDays: json['selectedDays'] != null
          ? List<bool>.from(json['selectedDays'] as List)
          : List.filled(7, true),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as DateTime)
          : DateTime.now(),
      streak: json['streak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      targetNumber: json['targetNumber'] as int?,
      notes: json['notes'] as String?,
      reminderTime: json['reminderTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'frequency': frequency,
      'selectedDays': selectedDays,
      'createdAt': createdAt,
      'streak': streak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate,
      'targetNumber': targetNumber,
      'notes': notes,
      'reminderTime': reminderTime,
    };
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? frequency,
    List<bool>? selectedDays,
    DateTime? createdAt,
    int? streak,
    int? longestStreak,
    String? lastCompletedDate,
    int? targetNumber,
    String? notes,
    String? reminderTime,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      selectedDays: selectedDays ?? this.selectedDays,
      createdAt: createdAt ?? this.createdAt,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      targetNumber: targetNumber ?? this.targetNumber,
      notes: notes ?? this.notes,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}