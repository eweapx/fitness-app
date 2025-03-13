import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/habit.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import '../utils/helpers.dart';

class HabitTrackingScreen extends StatefulWidget {
  const HabitTrackingScreen({super.key});

  @override
  _HabitTrackingScreenState createState() => _HabitTrackingScreenState();
}

class _HabitTrackingScreenState extends State<HabitTrackingScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _selectedDate = DateTime.now();
  List<Habit> _habits = [];
  late TabController _tabController;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _habitNameController = TextEditingController();
  HabitType _selectedHabitType = HabitType.good;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  List<bool> _selectedDays = List.filled(7, true);
  final _reminderTimeController = TextEditingController();
  TimeOfDay? _reminderTime;
  bool _setReminder = false;
  final _targetNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
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
    _reminderTimeController.dispose();
    _targetNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Get habits
      final habits = await _firebaseService.getHabits(userId);
      
      setState(() {
        _habits = habits;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Parse form values
      final name = _habitNameController.text.trim();
      final type = _selectedHabitType.toString().split('.').last;
      final frequency = _selectedFrequency.toString().split('.').last;
      int? targetNumber;
      
      if (_targetNumberController.text.isNotEmpty) {
        targetNumber = int.parse(_targetNumberController.text);
      }
      
      // Create habit data
      final habitData = Habit(
        id: '', // Will be set by Firebase
        userId: userId,
        name: name,
        type: type,
        frequency: frequency,
        selectedDays: _selectedDays,
        createdAt: DateTime.now(),
        streak: 0,
        longestStreak: 0,
        lastCompletedDate: null,
        targetNumber: targetNumber,
        notes: _notesController.text,
        reminderTime: _reminderTime != null 
            ? '${_reminderTime!.hour}:${_reminderTime!.minute}'
            : null,
      );
      
      // Save to Firebase
      await _firebaseService.addHabit(habitData);
      
      // Reset form
      _resetHabitForm();
      
      // Reload habits
      await _loadHabits();
      
      // Navigate back to the habits tab
      _tabController.animateTo(0);
      
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
  
  void _resetHabitForm() {
    _habitNameController.clear();
    _selectedHabitType = HabitType.good;
    _selectedFrequency = HabitFrequency.daily;
    _selectedDays = List.filled(7, true);
    _reminderTimeController.clear();
    _reminderTime = null;
    _setReminder = false;
    _targetNumberController.clear();
    _notesController.clear();
  }
  
  Future<void> _deleteHabit(String habitId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text('Are you sure you want to delete this habit? This will remove all tracking history.'),
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
        await _firebaseService.deleteHabit(habitId);
        
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
    try {
      final today = DateTime.now();
      final todayFormatted = DateFormat('yyyy-MM-dd').format(today);
      
      // Check if habit should be performed today
      if (!_shouldPerformHabitToday(habit)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This habit is not scheduled for today.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // If already completed today, uncomplete it
      if (habit.lastCompletedDate == todayFormatted) {
        final habitData = {
          'lastCompletedDate': null,
          'streak': habit.streak > 0 ? habit.streak - 1 : 0,
        };
        
        await _firebaseService.updateHabit(habit.id, habitData);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Habit marked as not completed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Calculate streak
        int newStreak = habit.streak;
        DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
        String yesterdayFormatted = DateFormat('yyyy-MM-dd').format(yesterday);
        
        // If completed yesterday, increment streak. Otherwise reset.
        if (habit.lastCompletedDate == yesterdayFormatted || 
            habit.lastCompletedDate == null) {
          newStreak += 1;
        } else {
          // Streak broken
          newStreak = 1;
        }
        
        // Update habit data
        final habitData = {
          'lastCompletedDate': todayFormatted,
          'streak': newStreak,
          'longestStreak': newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
        };
        
        await _firebaseService.updateHabit(habit.id, habitData);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStreak > 1 
                    ? 'Habit completed! 🔥 Streak: $newStreak days' 
                    : 'Habit completed! Streak started!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // Reload habits
      await _loadHabits();
    } catch (e) {
      print('Error updating habit: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating habit: ${e.toString()}')),
        );
      }
    }
  }
  
  bool _shouldPerformHabitToday(Habit habit) {
    if (habit.frequency == 'daily') {
      return true;
    }
    
    if (habit.frequency == 'weekly' && habit.selectedDays != null) {
      final today = DateTime.now().weekday - 1; // 0 = Monday, 6 = Sunday
      return habit.selectedDays[today];
    }
    
    return true;
  }
  
  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _reminderTime = time;
        _reminderTimeController.text = _formatTimeOfDay(time);
      });
    }
  }
  
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  Color _getHabitColor(String type) {
    return type == 'good' ? AppColors.good : AppColors.bad;
  }
  
  String _getHabitEmoji(String type) {
    return type == 'good' ? '✅' : '❌';
  }
  
  String _getHabitFrequencyText(Habit habit) {
    if (habit.frequency == 'daily') {
      return 'Every day';
    } else if (habit.frequency == 'weekly' && habit.selectedDays != null) {
      final days = <String>[];
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      
      for (int i = 0; i < habit.selectedDays.length; i++) {
        if (habit.selectedDays[i]) {
          days.add(dayNames[i]);
        }
      }
      
      if (days.length == 7) {
        return 'Every day';
      } else if (days.length == 0) {
        return 'No days selected';
      } else if (days.length == 5 && 
                !habit.selectedDays[5] && 
                !habit.selectedDays[6]) {
        return 'Weekdays';
      } else if (days.length == 2 && 
                habit.selectedDays[5] && 
                habit.selectedDays[6]) {
        return 'Weekends';
      } else {
        return days.join(', ');
      }
    }
    
    return 'Custom';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Habits'),
            Tab(text: 'Add Habit'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading habits...')
          : TabBarView(
              controller: _tabController,
              children: [
                // Habits Tab
                _buildHabitsTab(),
                
                // Add Habit Tab
                _buildAddHabitTab(),
              ],
            ),
    );
  }
  
  Widget _buildHabitsTab() {
    // Filter habits by type
    final goodHabits = _habits.where((h) => h.type == 'good').toList();
    final badHabits = _habits.where((h) => h.type == 'bad').toList();
    
    return RefreshIndicator(
      onRefresh: _loadHabits,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMMd().format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Habits status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Good Habits',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.good,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            goodHabits.length.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.good,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Bad Habits',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.bad,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badHabits.length.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.bad,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _habits.length.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Good habits
            if (goodHabits.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.thumb_up, color: AppColors.good),
                  const SizedBox(width: 8),
                  Text(
                    'Good Habits (${goodHabits.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.good,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...goodHabits.map((habit) => _buildHabitItem(habit)),
              const SizedBox(height: 24),
            ],
            
            // Bad habits
            if (badHabits.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.thumb_down, color: AppColors.bad),
                  const SizedBox(width: 8),
                  Text(
                    'Bad Habits (${badHabits.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bad,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...badHabits.map((habit) => _buildHabitItem(habit)),
              const SizedBox(height: 24),
            ],
            
            // Empty state
            if (_habits.isEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.loop,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No habits added yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your habits to build a healthier lifestyle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Add Your First Habit',
                      icon: Icons.add,
                      onPressed: () => _tabController.animateTo(1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHabitItem(Habit habit) {
    final isCompletedToday = habit.lastCompletedDate == 
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final shouldPerformToday = _shouldPerformHabitToday(habit);
    
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _deleteHabit(habit.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getHabitColor(habit.type).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _toggleHabitCompletion(habit),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _getHabitColor(habit.type).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        _getHabitEmoji(habit.type),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getHabitColor(habit.type),
                            ),
                          ),
                          Text(
                            _getHabitFrequencyText(habit),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    shouldPerformToday
                        ? Checkbox(
                            value: isCompletedToday,
                            onChanged: (_) => _toggleHabitCompletion(habit),
                            activeColor: _getHabitColor(habit.type),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : const Icon(
                            Icons.event_busy,
                            color: Colors.grey,
                            size: 24,
                          ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildHabitStat(
                        'Current Streak',
                        '${habit.streak}',
                        'days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildHabitStat(
                        'Longest Streak',
                        '${habit.longestStreak}',
                        'days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
                if (habit.notes != null && habit.notes!.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    habit.notes!,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHabitStat(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddHabitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit name
            TextFormField(
              controller: _habitNameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g. Morning Exercise, Quit Smoking',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Habit type
            const Text(
              'Habit Type',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHabitTypeButton(
                    'Good Habit',
                    'Habits you want to build',
                    Icons.thumb_up,
                    AppColors.good,
                    HabitType.good,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHabitTypeButton(
                    'Bad Habit',
                    'Habits you want to break',
                    Icons.thumb_down,
                    AppColors.bad,
                    HabitType.bad,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Frequency
            const Text(
              'Frequency',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<HabitFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: [
                DropdownMenuItem(
                  value: HabitFrequency.daily,
                  child: const Text('Daily'),
                ),
                DropdownMenuItem(
                  value: HabitFrequency.weekly,
                  child: const Text('Weekly (Select Days)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFrequency = value);
                }
              },
            ),
            
            // Show day selector for weekly frequency
            if (_selectedFrequency == HabitFrequency.weekly) ...[
              const SizedBox(height: 16),
              _buildDaySelector(),
            ],
            const SizedBox(height: 24),
            
            // Reminder
            const Text(
              'Reminder (Optional)',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Set a reminder'),
              subtitle: const Text('Get notified at a specific time'),
              value: _setReminder,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() => _setReminder = value);
                if (!value) {
                  _reminderTime = null;
                  _reminderTimeController.clear();
                }
              },
            ),
            if (_setReminder) ...[
              GestureDetector(
                onTap: () => _selectReminderTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _reminderTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Reminder Time',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (_setReminder && (value == null || value.isEmpty)) {
                        return 'Please select a reminder time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Target number (for countable habits)
            const Text(
              'Target (Optional)',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            const Text(
              'Set a target number for countable habits like glasses of water, steps, etc.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Number',
                hintText: 'e.g. 8 (glasses of water)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  try {
                    final number = int.parse(value);
                    if (number <= 0) {
                      return 'Target must be greater than 0';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this habit',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save Habit',
                icon: Icons.check,
                onPressed: _addHabit,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHabitTypeButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    HabitType type,
  ) {
    final isSelected = _selectedHabitType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedHabitType = type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDaySelector() {
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const fullDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Days',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            return Tooltip(
              message: fullDayNames[index],
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDays[index] = !_selectedDays[index];
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedDays[index] 
                        ? AppColors.primary 
                        : Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Text(
                      dayNames[index],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedDays[index] 
                            ? Colors.white 
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDays = List.filled(7, true);
                });
              },
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDays = [true, true, true, true, true, false, false];
                });
              },
              child: const Text('Weekdays'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDays = [false, false, false, false, false, true, true];
                });
              },
              child: const Text('Weekends'),
            ),
          ],
        ),
      ],
    );
  }
}