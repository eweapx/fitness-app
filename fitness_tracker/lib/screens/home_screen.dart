import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/habit.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'activity_tracking_screen.dart';
import 'habit_tracking_screen.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'sleep_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();
  
  // Dashboard stats
  int _totalActivities = 0;
  int _totalHabits = 0;
  int _totalSleepHours = 0;
  int _totalSteps = 0;
  int _totalCalories = 0;
  double _todayNutritionCalories = 0;
  
  // Lists for charts
  List<Map<String, dynamic>> _weeklyActivities = [];
  List<Habit> _habits = [];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Load user profile if not already loaded
      if (userProvider.userProfile == null) {
        await userProvider.loadUserProfile();
      }
      
      // Get activity stats
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      
      // Get activities
      final activities = await _firebaseService.getActivitiesForDateRange(
        userId,
        weekAgo,
        now,
      );
      
      // Get habits
      final habits = await _firebaseService.getHabits(userId);
      
      // Get nutrition stats
      final todayMeals = await _firebaseService.getMealEntriesForDate(
        userId,
        today,
      );
      
      double todayCalories = 0;
      for (final meal in todayMeals) {
        final calories = meal['calories'] as int? ?? 0;
        todayCalories += calories;
      }
      
      // Get sleep stats
      final sleepEntries = await _firebaseService.getSleepEntriesForDateRange(
        userId,
        weekAgo,
        now,
      );
      
      int totalSleepMinutes = 0;
      for (final entry in sleepEntries) {
        final duration = entry['durationMinutes'] as int? ?? 0;
        totalSleepMinutes += duration;
      }
      
      // Calculate activity stats
      int totalSteps = 0;
      int totalCalories = 0;
      
      for (final activity in activities) {
        final steps = activity['steps'] as int? ?? 0;
        final calories = activity['calories'] as int? ?? 0;
        
        totalSteps += steps;
        totalCalories += calories;
      }
      
      setState(() {
        _totalActivities = activities.length;
        _totalHabits = habits.length;
        _totalSleepHours = (totalSleepMinutes / 60).round();
        _totalSteps = totalSteps;
        _totalCalories = totalCalories;
        _todayNutritionCalories = todayCalories;
        _weeklyActivities = activities;
        _habits = habits;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: ${e.toString()}')),
        );
      }
    }
  }
  
  // Sign out
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      // Clear user provider data
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).clearUser();
      }
    } catch (e) {
      print('Error signing out: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text('Health & Fitness Tracker'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Data',
                  onPressed: _loadDashboardData,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  onPressed: _signOut,
                ),
              ],
            )
          : null,
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Habits',
          ),
        ],
      ),
    );
  }
  
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardScreen();
      case 1:
        return const ActivityTrackingScreen();
      case 2:
        return const NutritionScreen();
      case 3:
        return const SleepTrackingScreen();
      case 4:
        return const HabitTrackingScreen();
      default:
        return _buildDashboardScreen();
    }
  }
  
  Widget _buildDashboardScreen() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading dashboard data...');
    }
    
    // Get settings
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isMetric = settingsProvider.useMetricSystem;
    final distanceUnit = isMetric ? AppConstants.unitKm : AppConstants.unitMi;
    
    // Get user data
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userProfile != null
        ? userProvider.userProfile!['name'] ?? 'User'
        : 'User';
    
    // Calculate calorie goal progress
    int calorieGoal = settingsProvider.caloriesGoal;
    final dailyNeeds = userProvider.getUserDailyCalorieNeeds();
    if (dailyNeeds != null) {
      calorieGoal = dailyNeeds;
    }
    
    final calorieProgress = _todayNutritionCalories / calorieGoal;
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User greeting
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tap to view your profile',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick stats
            const Text(
              'Today\'s Statistics',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Steps',
                    _totalSteps.toString(),
                    Icons.directions_walk,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Calories',
                    '$_totalCalories kcal',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Sleep',
                    '$_totalSleepHours hrs',
                    Icons.bedtime,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Activities',
                    _totalActivities.toString(),
                    Icons.fitness_center,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Nutrition progress
            const Text(
              'Nutrition Progress',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Calories Consumed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${_todayNutritionCalories.toInt()} / $calorieGoal kcal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade50,
                          ),
                          child: Center(
                            child: Text(
                              '${(calorieProgress * 100).round()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: calorieProgress > 1 ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: calorieProgress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        calorieProgress > 1 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Habit tracking
            const Text(
              'Habit Tracking',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            if (_habits.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.loop,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No habits created yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create habits to track your progress',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Create a Habit',
                        icon: Icons.add,
                        onPressed: () {
                          setState(() => _selectedIndex = 4);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _habits.length > 5 ? 5 : _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    final isGoodHabit = habit.type == 'good';
                    final color = isGoodHabit ? AppColors.good : AppColors.bad;
                    
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 16),
                      child: Card(
                        color: color.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: color.withOpacity(0.3)),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedIndex = 4);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color.withOpacity(0.2),
                                      ),
                                      child: Text(
                                        isGoodHabit ? '✅' : '❌',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isGoodHabit ? 'Good' : 'Bad',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  habit.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${habit.streak} day streak',
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() => _selectedIndex = 4);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View All Habits'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Log Activity',
                    Icons.directions_run,
                    Colors.blue,
                    () {
                      setState(() => _selectedIndex = 1);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'Log Meal',
                    Icons.restaurant_menu,
                    Colors.green,
                    () {
                      setState(() => _selectedIndex = 2);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Log Sleep',
                    Icons.bedtime,
                    Colors.indigo,
                    () {
                      setState(() => _selectedIndex = 3);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'Track Habit',
                    Icons.repeat,
                    Colors.purple,
                    () {
                      setState(() => _selectedIndex = 4);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}