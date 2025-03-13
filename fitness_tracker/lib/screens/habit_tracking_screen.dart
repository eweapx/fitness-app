import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../models/habit_model.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class HabitTrackingScreen extends StatefulWidget {
  const HabitTrackingScreen({super.key});

  @override
  _HabitTrackingScreenState createState() => _HabitTrackingScreenState();
}

class _HabitTrackingScreenState extends State<HabitTrackingScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  late TabController _tabController;
  
  // Lists of habits
  List<Habit> _goodHabits = [];
  List<Habit> _badHabits = [];
  
  // For adding new habits
  final _habitNameController = TextEditingController();
  HabitType _selectedHabitType = HabitType.good;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  int _selectedGoal = 1;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHabits();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _habitNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Get habits from Firebase
      final habits = await _firebaseService.getUserHabits(demoUserId);
      
      // Separate into good and bad habits
      final goodHabits = habits.where((h) => h.type == HabitType.good).toList();
      final badHabits = habits.where((h) => h.type == HabitType.bad).toList();
      
      // Sort by creation date (newest first)
      goodHabits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      badHabits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _goodHabits = goodHabits;
        _badHabits = badHabits;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading habits: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading habits: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _addHabit() async {
    if (_habitNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Create a new habit
      final habit = Habit(
        id: null,
        userId: demoUserId,
        name: _habitNameController.text.trim(),
        type: _selectedHabitType,
        frequency: _selectedFrequency,
        goal: _selectedGoal,
        streak: 0,
        longestStreak: 0,
        completedDates: [],
        reminderEnabled: true,
        reminderTime: const TimeOfDay(hour: 9, minute: 0), // Default reminder at 9 AM
        createdAt: DateTime.now(),
      );
      
      // Save to Firebase
      await _firebaseService.addHabit(habit);
      
      // Schedule a notification for this habit
      if (habit.reminderEnabled) {
        await _notificationService.scheduleHabitReminderNotification(
          habit.id ?? '',
          habit.name,
          habit.type == HabitType.good ? 'Time to maintain your good habit!' : 'Time to avoid your bad habit!',
          habit.reminderTime,
        );
      }
      
      // Reset form
      _habitNameController.clear();
      setState(() {
        _selectedHabitType = HabitType.good;
        _selectedFrequency = HabitFrequency.daily;
        _selectedGoal = 1;
      });
      
      // Reload habits
      await _loadHabits();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding habit: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding habit: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteHabit(Habit habit) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        // Delete from Firebase
        await _firebaseService.deleteHabit(habit.id!);
        
        // Cancel any scheduled notifications
        await _notificationService.cancelHabitReminderNotification(habit.id!);
        
        // Reload habits
        await _loadHabits();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Habit deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting habit: $e');
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting habit: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  Future<void> _toggleHabitCompletion(Habit habit) async {
    setState(() => _isLoading = true);
    
    try {
      final today = DateTime.now();
      final todayString = DateFormat('yyyy-MM-dd').format(today);
      
      // Check if already completed today
      final isCompletedToday = habit.completedDates.any((date) => 
        DateFormat('yyyy-MM-dd').format(date) == todayString
      );
      
      List<DateTime> updatedCompletedDates = [...habit.completedDates];
      int updatedStreak = habit.streak;
      int updatedLongestStreak = habit.longestStreak;
      
      if (isCompletedToday) {
        // Remove today's completion
        updatedCompletedDates.removeWhere((date) => 
          DateFormat('yyyy-MM-dd').format(date) == todayString
        );
        
        // Adjust streak
        updatedStreak = updatedStreak > 0 ? updatedStreak - 1 : 0;
      } else {
        // Add today's completion
        updatedCompletedDates.add(today);
        
        // Check if streak should be incremented
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayString = DateFormat('yyyy-MM-dd').format(yesterday);
        
        final isCompletedYesterday = habit.completedDates.any((date) => 
          DateFormat('yyyy-MM-dd').format(date) == yesterdayString
        );
        
        // For daily habits, increment streak if completed yesterday or this is the first completion
        if (habit.frequency == HabitFrequency.daily) {
          if (isCompletedYesterday || habit.streak == 0) {
            updatedStreak = habit.streak + 1;
          } else {
            // Streak broken, start over
            updatedStreak = 1;
          }
        } 
        // For weekly habits, need to check if completed in the last 7 days
        else if (habit.frequency == HabitFrequency.weekly) {
          final oneWeekAgo = today.subtract(const Duration(days: 7));
          
          final completionsLastWeek = habit.completedDates.where((date) => 
            date.isAfter(oneWeekAgo) && date.isBefore(today)
          ).length;
          
          // If there are completions in the last week and the goal is met, increment streak
          if (completionsLastWeek >= habit.goal) {
            updatedStreak = habit.streak + 1;
          } else {
            // Not enough completions last week, start over
            updatedStreak = 1;
          }
        }
        
        // Update longest streak if needed
        if (updatedStreak > updatedLongestStreak) {
          updatedLongestStreak = updatedStreak;
          
          // If this is a milestone (every 7 days), show a celebration
          if (updatedStreak % 7 == 0) {
            // Show a streak milestone notification
            await _notificationService.showStreakNotification(
              habit.name,
              updatedStreak,
            );
          }
        }
      }
      
      // Update the habit
      final updatedHabit = habit.copyWith(
        completedDates: updatedCompletedDates,
        streak: updatedStreak,
        longestStreak: updatedLongestStreak,
      );
      
      // Save to Firebase
      await _firebaseService.updateHabit(updatedHabit);
      
      // Reload habits
      await _loadHabits();
    } catch (e) {
      print('Error updating habit completion: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating habit: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _editHabitReminder(Habit habit) async {
    final initialTime = habit.reminderTime;
    bool reminderEnabled = habit.reminderEnabled;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Reminder'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Enable Reminder'),
                  value: reminderEnabled,
                  onChanged: (value) {
                    setState(() => reminderEnabled = value);
                  },
                ),
                if (reminderEnabled) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Reminder Time'),
                    subtitle: Text(
                      '${initialTime.hour}:${initialTime.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                      );
                      if (pickedTime != null) {
                        setState(() => initialTime = pickedTime);
                      }
                    },
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'enabled': reminderEnabled,
              'time': initialTime,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() => _isLoading = true);
      
      try {
        // Update the habit
        final updatedHabit = habit.copyWith(
          reminderEnabled: result['enabled'],
          reminderTime: result['time'],
        );
        
        // Save to Firebase
        await _firebaseService.updateHabit(updatedHabit);
        
        // Update notification
        if (updatedHabit.reminderEnabled) {
          await _notificationService.scheduleHabitReminderNotification(
            updatedHabit.id ?? '',
            updatedHabit.name,
            updatedHabit.type == HabitType.good ? 'Time to maintain your good habit!' : 'Time to avoid your bad habit!',
            updatedHabit.reminderTime,
          );
        } else {
          await _notificationService.cancelHabitReminderNotification(updatedHabit.id!);
        }
        
        // Reload habits
        await _loadHabits();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error updating habit reminder: $e');
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating reminder: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Good Habits'),
            Tab(text: 'Bad Habits'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading habits...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHabitList(_goodHabits, true),
                _buildHabitList(_badHabits, false),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        tooltip: 'Add Habit',
      ),
    );
  }
  
  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Habit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _habitNameController,
                    decoration: const InputDecoration(
                      labelText: 'Habit Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Drink water, Meditate, No smoking',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Habit Type'),
                  DropdownButton<HabitType>(
                    value: _selectedHabitType,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: HabitType.good,
                        child: Row(
                          children: [
                            Icon(Icons.thumb_up, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            const Text('Good Habit (build)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: HabitType.bad,
                        child: Row(
                          children: [
                            Icon(Icons.thumb_down, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            const Text('Bad Habit (break)'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedHabitType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Frequency'),
                  DropdownButton<HabitFrequency>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: HabitFrequency.daily,
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Daily'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: HabitFrequency.weekly,
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_view_week, color: Colors.purple),
                            SizedBox(width: 8),
                            Text('Weekly'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFrequency = value);
                      }
                    },
                  ),
                  if (_selectedFrequency == HabitFrequency.weekly) ...[
                    const SizedBox(height: 16),
                    const Text('Goal (times per week)'),
                    DropdownButton<int>(
                      value: _selectedGoal,
                      isExpanded: true,
                      items: List.generate(7, (index) => index + 1)
                          .map((goal) => DropdownMenuItem(
                            value: goal,
                            child: Text('$goal ${goal == 1 ? 'time' : 'times'} / week'),
                          ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGoal = value);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addHabit();
                },
                child: const Text('Add Habit'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildHabitList(List<Habit> habits, bool isGoodHabits) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGoodHabits ? Icons.thumb_up : Icons.thumb_down,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isGoodHabits ? 'good' : 'bad'} habits yet',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a ${isGoodHabits ? 'good' : 'bad'} habit',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return _buildHabitCard(habit, isGoodHabits);
      },
    );
  }
  
  Widget _buildHabitCard(Habit habit, bool isGoodHabit) {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);
    
    final isCompletedToday = habit.completedDates.any((date) => 
      DateFormat('yyyy-MM-dd').format(date) == todayString
    );
    
    // Calculate completion rate
    final last7Days = List.generate(7, (i) => 
      today.subtract(Duration(days: i))
    ).map((date) => 
      DateFormat('yyyy-MM-dd').format(date)
    ).toList();
    
    final completionsLast7Days = habit.completedDates.where((date) => 
      last7Days.contains(DateFormat('yyyy-MM-dd').format(date))
    ).length;
    
    final completionRate = completionsLast7Days / 7 * 100;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isGoodHabit ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isGoodHabit ? Icons.thumb_up : Icons.thumb_down,
                color: isGoodHabit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              habit.name,
              style: TextStyle(
                fontWeight: isCompletedToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              _getHabitSubtitle(habit),
              style: TextStyle(
                color: habit.streak > 0 ? Colors.blue : Colors.grey,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  color: habit.reminderEnabled ? AppColors.primary : Colors.grey,
                  tooltip: 'Set Reminder',
                  onPressed: () => _editHabitReminder(habit),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Delete Habit',
                  onPressed: () => _deleteHabit(habit),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStreakInfo(habit),
                const Spacer(),
                // Completion checkbox
                InkWell(
                  onTap: () => _toggleHabitCompletion(habit),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isCompletedToday
                          ? (isGoodHabit ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompletedToday ? Icons.check : Icons.circle_outlined,
                          size: 18,
                          color: isCompletedToday ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGoodHabit
                              ? (isCompletedToday ? 'Done Today' : 'Mark as Done')
                              : (isCompletedToday ? 'Avoided Today' : 'Mark as Avoided'),
                          style: TextStyle(
                            color: isCompletedToday ? Colors.white : Colors.grey,
                            fontWeight: isCompletedToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Weekly progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last 7 Days: $completionsLast7Days/7',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '${completionRate.toInt()}%',
                      style: TextStyle(
                        color: _getCompletionColor(completionRate),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completionRate / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_getCompletionColor(completionRate)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final date = today.subtract(Duration(days: 6 - i));
                    final dateString = DateFormat('yyyy-MM-dd').format(date);
                    final isCompleted = habit.completedDates.any((d) => 
                      DateFormat('yyyy-MM-dd').format(d) == dateString
                    );
                    
                    return Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? (isGoodHabit ? Colors.green : Colors.red)
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? (isGoodHabit ? Colors.green.shade700 : Colors.red.shade700)
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('E').format(date)[0], // First letter of weekday
                          style: TextStyle(
                            fontSize: 12,
                            color: i == 6 ? Colors.black87 : Colors.grey, // Today is brighter
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStreakInfo(Habit habit) {
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          color: habit.streak > 0 ? Colors.orange : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            text: 'Streak: ',
            style: const TextStyle(color: Colors.grey),
            children: [
              TextSpan(
                text: '${habit.streak} ${habit.streak == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: habit.streak > 0 ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.emoji_events,
          color: habit.longestStreak > 0 ? Colors.amber : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            text: 'Best: ',
            style: const TextStyle(color: Colors.grey),
            children: [
              TextSpan(
                text: '${habit.longestStreak} ${habit.longestStreak == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: habit.longestStreak > 0 ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getHabitSubtitle(Habit habit) {
    final frequencyText = habit.frequency == HabitFrequency.daily
        ? 'Daily'
        : '${habit.goal} ${habit.goal == 1 ? 'time' : 'times'} / week';
    
    if (habit.streak > 0) {
      return '$frequencyText • ${habit.streak} day streak 🔥';
    }
    
    return frequencyText;
  }
  
  Color _getCompletionColor(double rate) {
    if (rate >= 80) {
      return Colors.green;
    } else if (rate >= 60) {
      return Colors.lightGreen;
    } else if (rate >= 40) {
      return Colors.amber;
    } else if (rate >= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}