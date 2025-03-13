import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

// Feature screens
import 'activity_tracking_screen.dart';
import 'nutrition_screen.dart';
import 'sleep_tracking_screen.dart';
import 'habit_tracking_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();
  
  Map<String, dynamic> _statsData = {
    'steps': 0,
    'calories': 0,
    'distance': 0.0,
    'activities': 0,
    'sleep': 0.0,
    'water': 0,
    'streaks': 0,
  };
  
  List<FlSpot> _weeklyActivityData = [];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Get data for today's summary
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Get today's activities
      final todayActivities = await _firebaseService.getActivitiesForDateRange(
        user.uid,
        startOfDay,
        endOfDay,
      );
      
      // Get weekly activity data
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      
      final weeklyActivities = await _firebaseService.getActivitiesForDateRange(
        user.uid,
        startOfWeek,
        endOfWeek,
      );
      
      // Get sleep data for the past week
      final startOfPastWeek = now.subtract(const Duration(days: 7));
      final sleepEntries = await _firebaseService.getSleepEntriesForDateRange(
        user.uid,
        startOfPastWeek,
        now,
      );
      
      // Get user habits
      final habits = await _firebaseService.getUserHabits(user.uid);
      
      // Calculate today's stats
      int todaySteps = 0;
      int todayCalories = 0;
      double todayDistance = 0.0;
      
      for (final activity in todayActivities) {
        todaySteps += activity['steps'] ?? 0;
        todayCalories += activity['calories'] ?? 0;
        todayDistance += activity['distance'] ?? 0.0;
      }
      
      // Calculate average sleep for the past week
      double avgSleep = 0.0;
      if (sleepEntries.isNotEmpty) {
        final totalSleepMinutes = sleepEntries.fold<int>(
          0, (sum, entry) => sum + entry.duration);
        avgSleep = totalSleepMinutes / sleepEntries.length / 60; // Convert to hours
      }
      
      // Calculate streak
      int highestStreak = 0;
      for (final habit in habits) {
        if (habit.streak > highestStreak) {
          highestStreak = habit.streak;
        }
      }
      
      // Process weekly activity data for chart
      final Map<DateTime, int> dailyCalories = {};
      
      // Initialize all days of the week with 0 calories
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        dailyCalories[date] = 0;
      }
      
      // Sum up calories by day
      for (final activity in weeklyActivities) {
        final date = (activity['date'] as DateTime);
        final dayDate = DateTime(date.year, date.month, date.day);
        final calories = activity['calories'] ?? 0;
        
        dailyCalories[dayDate] = (dailyCalories[dayDate] ?? 0) + calories;
      }
      
      final sortedDates = dailyCalories.keys.toList()..sort();
      _weeklyActivityData = sortedDates.map((date) {
        // Get the day of week (0-6, where 0 is Monday)
        final dayOfWeek = date.weekday - 1;
        return FlSpot(dayOfWeek.toDouble(), dailyCalories[date]!.toDouble());
      }).toList();
      
      setState(() {
        _statsData = {
          'steps': todaySteps,
          'calories': todayCalories,
          'distance': todayDistance,
          'activities': todayActivities.length,
          'sleep': avgSleep,
          'water': 0, // This would come from a water tracking feature
          'streaks': highestStreak,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboard(),
      const ActivityTrackingScreen(),
      const NutritionScreen(),
      const SleepTrackingScreen(),
      const HabitTrackingScreen(),
      const SettingsScreen(),
    ];
    
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          
          // Refresh dashboard data when returning to dashboard
          if (index == 0) {
            _loadDashboardData();
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
            icon: Icon(Icons.nightlight),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboard() {
    final user = Provider.of<UserProvider>(context).user;
    final today = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading dashboard data...')
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting section
                    Text(
                      'Hello, ${user?.displayName ?? 'there'}!',
                      style: AppTextStyles.heading1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(today),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Today's summary
                    const SectionHeader(title: "Today's Summary"),
                    const SizedBox(height: 8),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    
                    // Weekly activity chart
                    const SectionHeader(title: 'Weekly Activity'),
                    const SizedBox(height: 8),
                    _buildWeeklyActivityChart(),
                    const SizedBox(height: 24),
                    
                    // Quick access
                    const SectionHeader(title: 'Quick Access'),
                    const SizedBox(height: 8),
                    _buildQuickAccessGrid(),
                    const SizedBox(height: 24),
                    
                    // Progress cards
                    const SectionHeader(title: 'Your Progress'),
                    const SizedBox(height: 8),
                    _buildProgressCards(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Steps',
                value: '${_statsData['steps']}',
                subtitle: '${(_statsData['steps'] / AppConstants.defaultStepsGoal * 100).toInt()}% of goal',
                icon: Icons.directions_walk,
                color: AppColors.primary,
                onTap: () => _navigateToScreen(1), // Activity screen
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: 'Calories',
                value: '${_statsData['calories']}',
                subtitle: 'kcal burned today',
                icon: Icons.local_fire_department,
                color: Colors.orange,
                onTap: () => _navigateToScreen(1), // Activity screen
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Sleep',
                value: '${_statsData['sleep'].toStringAsFixed(1)}h',
                subtitle: 'avg. last 7 days',
                icon: Icons.nightlight,
                color: Colors.indigo,
                onTap: () => _navigateToScreen(3), // Sleep screen
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: 'Habits',
                value: '${_statsData['streaks']}',
                subtitle: 'days longest streak',
                icon: Icons.repeat,
                color: AppColors.tertiary,
                onTap: () => _navigateToScreen(4), // Habits screen
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildWeeklyActivityChart() {
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.whatshot,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Calories Burned',
                    style: AppTextStyles.heading4,
                  ),
                  const Spacer(),
                  ChartLegendItem(
                    label: 'Current Week',
                    color: Colors.orange.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _weeklyActivityData.isEmpty
                    ? const Center(
                        child: Text('No activity data available'),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_weeklyActivityData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.2)
                              .ceilToDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.blueGrey.shade800,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.round()} kcal',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < daysOfWeek.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        daysOfWeek[index],
                                        style: AppTextStyles.caption,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value % 100 == 0) {
                                    return Text(
                                      '${value.toInt()}',
                                      style: AppTextStyles.caption,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                reservedSize: 40,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          barGroups: _weeklyActivityData.map((spot) {
                            return BarChartGroupData(
                              x: spot.x.toInt(),
                              barRods: [
                                BarChartRodData(
                                  toY: spot.y,
                                  color: Colors.orange.shade300,
                                  width: 22,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickAccessGrid() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        FeatureCard(
          title: 'Track Activity',
          icon: Icons.directions_run,
          description: 'Log your workouts and activities',
          onTap: () => _navigateToScreen(1),
          color: AppColors.running,
        ),
        FeatureCard(
          title: 'Log Meals',
          icon: Icons.restaurant,
          description: 'Track your meals and nutrition',
          onTap: () => _navigateToScreen(2),
          color: AppColors.carbs,
        ),
        FeatureCard(
          title: 'Track Sleep',
          icon: Icons.nightlight,
          description: 'Log your sleep and quality',
          onTap: () => _navigateToScreen(3),
          color: Colors.indigo,
        ),
        FeatureCard(
          title: 'My Habits',
          icon: Icons.repeat,
          description: 'Build good habits, break bad ones',
          onTap: () => _navigateToScreen(4),
          color: AppColors.tertiary,
        ),
      ],
    );
  }
  
  Widget _buildProgressCards() {
    return Column(
      children: [
        ProgressCard(
          title: 'Steps',
          progress: _statsData['steps'] / AppConstants.defaultStepsGoal,
          metric: '${_statsData['steps']}',
          goal: '${AppConstants.defaultStepsGoal}',
          color: AppColors.primary,
          icon: Icons.directions_walk,
        ),
        const SizedBox(height: 16),
        ProgressCard(
          title: 'Sleep',
          progress: _statsData['sleep'] / AppConstants.defaultSleepGoal,
          metric: '${_statsData['sleep'].toStringAsFixed(1)}h',
          goal: '${AppConstants.defaultSleepGoal}h',
          color: Colors.indigo,
          icon: Icons.nightlight,
        ),
        const SizedBox(height: 16),
        ProgressCard(
          title: 'Activity',
          progress: _statsData['activities'] / 3, // Assuming a goal of 3 activities per day
          metric: '${_statsData['activities']}',
          goal: '3',
          color: Colors.orange,
          icon: Icons.fitness_center,
        ),
      ],
    );
  }
  
  void _navigateToScreen(int index) {
    setState(() => _currentIndex = index);
  }
}