import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitType {
  good,
  bad,
}

enum HabitFrequency {
  daily,
  weekly,
}

class Habit {
  final String? id;
  final String userId;
  final String name;
  final HabitType type;
  final HabitFrequency frequency;
  final int goal; // Times per week for weekly habits, 1 for daily habits
  final int streak;
  final int longestStreak;
  final List<DateTime> completedDates;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;
  final DateTime createdAt;
  
  Habit({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.frequency,
    required this.goal,
    required this.streak,
    required this.longestStreak,
    required this.completedDates,
    required this.reminderEnabled,
    required this.reminderTime,
    required this.createdAt,
  });
  
  // Create a Habit from Firestore data
  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse completed dates
    final List<dynamic> completedDatesList = data['completedDates'] ?? [];
    final List<DateTime> completedDates = completedDatesList
        .map((date) => (date as Timestamp).toDate())
        .toList();
    
    // Parse reminder time
    final Map<String, dynamic> reminderTimeMap = data['reminderTime'] ?? {'hour': 9, 'minute': 0};
    final TimeOfDay reminderTime = TimeOfDay(
      hour: reminderTimeMap['hour'] ?? 9,
      minute: reminderTimeMap['minute'] ?? 0,
    );
    
    return Habit(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] == 'bad' ? HabitType.bad : HabitType.good,
      frequency: data['frequency'] == 'weekly' ? HabitFrequency.weekly : HabitFrequency.daily,
      goal: data['goal'] ?? 1,
      streak: data['streak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      completedDates: completedDates,
      reminderEnabled: data['reminderEnabled'] ?? true,
      reminderTime: reminderTime,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
  
  // Convert Habit to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type == HabitType.bad ? 'bad' : 'good',
      'frequency': frequency == HabitFrequency.weekly ? 'weekly' : 'daily',
      'goal': goal,
      'streak': streak,
      'longestStreak': longestStreak,
      'completedDates': completedDates,
      'reminderEnabled': reminderEnabled,
      'reminderTime': {
        'hour': reminderTime.hour,
        'minute': reminderTime.minute,
      },
      'createdAt': createdAt,
    };
  }
  
  // Create a copy of the Habit with optional changes
  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    HabitType? type,
    HabitFrequency? frequency,
    int? goal,
    int? streak,
    int? longestStreak,
    List<DateTime>? completedDates,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      goal: goal ?? this.goal,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      completedDates: completedDates ?? this.completedDates,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Get the completion percentage for the current week
  double getWeeklyCompletionRate() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    // Count completions in current week
    final completionsThisWeek = completedDates.where((date) => 
      date.isAfter(startOfWeek) && date.isBefore(endOfWeek.add(const Duration(days: 1)))
    ).length;
    
    // For daily habits, divide by 7 (days in a week)
    if (frequency == HabitFrequency.daily) {
      return completionsThisWeek / 7;
    }
    
    // For weekly habits, divide by the goal
    return completionsThisWeek / goal;
  }
  
  // Check if the habit is complete for today
  bool isCompletedToday() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    return completedDates.any((date) => 
      '${date.year}-${date.month}-${date.day}' == todayString
    );
  }
  
  // Get a description of the habit's current streak
  String getStreakDescription() {
    if (streak <= 0) {
      return 'No current streak';
    } else if (streak == 1) {
      return '1 day streak';
    } else {
      return '$streak day streak';
    }
  }
  
  // Check if the habit is on track to meet its goal
  bool isOnTrack() {
    if (frequency == HabitFrequency.daily) {
      // For daily habits, check if completed yesterday and today
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final todayString = '${now.year}-${now.month}-${now.day}';
      final yesterdayString = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
      
      final completedToday = completedDates.any((date) => 
        '${date.year}-${date.month}-${date.day}' == todayString
      );
      
      final completedYesterday = completedDates.any((date) => 
        '${date.year}-${date.month}-${date.day}' == yesterdayString
      );
      
      return completedToday || completedYesterday;
    } else {
      // For weekly habits, check if on track to meet weekly goal
      final now = DateTime.now();
      final daysIntoWeek = now.weekday; // 1 = Monday, 7 = Sunday
      
      // Count completions this week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      final completionsThisWeek = completedDates.where((date) => 
        date.isAfter(startOfWeek.subtract(const Duration(days: 1)))
      ).length;
      
      // Calculate target completions by this day of the week
      final targetCompletions = (goal / 7 * daysIntoWeek).ceil();
      
      return completionsThisWeek >= targetCompletions;
    }
  }
  
  // Get a suggestion for the habit
  String getSuggestion() {
    if (type == HabitType.good) {
      if (streak < 3) {
        return 'Focus on building a streak by completing this habit daily';
      } else if (isOnTrack()) {
        return 'You\'re doing great! Keep up the momentum';
      } else {
        return 'Try to get back on track to maintain your streak';
      }
    } else {
      if (streak < 3) {
        return 'The first few days are the hardest. Stay strong!';
      } else if (isOnTrack()) {
        return 'You\'re doing well at avoiding this habit!';
      } else {
        return 'Remember why you want to break this habit';
      }
    }
  }
}

class HabitSummary {
  final int totalHabits;
  final int goodHabits;
  final int badHabits;
  final int habitsCompletedToday;
  final int highestStreak;
  final double averageCompletionRate;
  
  HabitSummary({
    required this.totalHabits,
    required this.goodHabits,
    required this.badHabits,
    required this.habitsCompletedToday,
    required this.highestStreak,
    required this.averageCompletionRate,
  });
  
  // Create a summary from a list of habits
  factory HabitSummary.fromHabits(List<Habit> habits) {
    if (habits.isEmpty) {
      return HabitSummary(
        totalHabits: 0,
        goodHabits: 0,
        badHabits: 0,
        habitsCompletedToday: 0,
        highestStreak: 0,
        averageCompletionRate: 0,
      );
    }
    
    // Count habit types
    final goodHabits = habits.where((h) => h.type == HabitType.good).length;
    final badHabits = habits.where((h) => h.type == HabitType.bad).length;
    
    // Count completions today
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    final habitsCompletedToday = habits.where((h) => 
      h.completedDates.any((date) => 
        '${date.year}-${date.month}-${date.day}' == todayString
      )
    ).length;
    
    // Find highest streak
    final highestStreak = habits.fold<int>(
      0, (max, habit) => habit.streak > max ? habit.streak : max);
    
    // Calculate average completion rate
    final totalCompletionRate = habits.fold<double>(
      0, (sum, habit) => sum + habit.getWeeklyCompletionRate());
    final averageCompletionRate = totalCompletionRate / habits.length * 100;
    
    return HabitSummary(
      totalHabits: habits.length,
      goodHabits: goodHabits,
      badHabits: badHabits,
      habitsCompletedToday: habitsCompletedToday,
      highestStreak: highestStreak,
      averageCompletionRate: averageCompletionRate,
    );
  }
  
  // Get a motivation message based on the summary
  String getMotivationMessage() {
    if (totalHabits == 0) {
      return 'Start by adding some habits to track!';
    }
    
    if (habitsCompletedToday == totalHabits) {
      return 'Amazing! You\'ve completed all your habits today 🎉';
    }
    
    if (habitsCompletedToday > 0) {
      return 'You\'ve completed $habitsCompletedToday/${totalHabits} habits today';
    }
    
    if (highestStreak > 7) {
      return 'Your highest streak is $highestStreak days! Keep it up!';
    }
    
    if (averageCompletionRate > 80) {
      return 'Excellent work! You\'re very consistent with your habits';
    }
    
    return 'Keep working on your habits - consistency is key!';
  }
}