import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity_model.dart';
import '../models/nutrition_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  bool _isLoading = true;
  
  // Date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedDateRange = 'week';
  
  // Activity data
  List<ActivityModel> _activities = [];
  Map<DateTime, int> _caloriesByDay = {};
  Map<DateTime, int> _stepsByDay = {};
  Map<DateTime, int> _workoutDurationByDay = {};
  Map<String, int> _activityTypeCount = {};
  int _totalActivities = 0;
  int _totalCaloriesBurned = 0;
  int _totalActiveMinutes = 0;
  
  // Nutrition data
  List<NutritionModel> _foodEntries = [];
  Map<DateTime, int> _caloriesConsumedByDay = {};
  Map<DateTime, Map<String, int>> _macrosByDay = {};
  Map<String, int> _foodCategoryCount = {};
  int _totalCaloriesConsumed = 0;
  int _avgProteinPerDay = 0;
  int _avgCarbsPerDay = 0;
  int _avgFatPerDay = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateDateRange(String range) {
    final now = DateTime.now();
    
    setState(() {
      _selectedDateRange = range;
      
      switch (range) {
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month - 1, now.day);
          _endDate = now;
          break;
        case 'year':
          _startDate = DateTime(now.year - 1, now.month, now.day);
          _endDate = now;
          break;
      }
    });
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Load activities
      final activities = await _firebaseService.getUserActivities(demoUserId);
      _activities = activities.where((activity) {
        return activity.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
               activity.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();
      
      // Process activity data
      _processActivityData();
      
      // Load nutrition entries
      final foodEntries = await _firebaseService.getUserNutrition(demoUserId);
      _foodEntries = foodEntries.where((entry) {
        return entry.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
               entry.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();
      
      // Process nutrition data
      _processNutritionData();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading progress data: ${e.toString()}')),
      );
    }
  }

  void _processActivityData() {
    // Reset data
    _caloriesByDay = {};
    _stepsByDay = {};
    _workoutDurationByDay = {};
    _activityTypeCount = {};
    _totalActivities = _activities.length;
    _totalCaloriesBurned = 0;
    _totalActiveMinutes = 0;
    
    // Group activities by day
    final activityByDay = <DateTime, List<ActivityModel>>{};
    
    for (final activity in _activities) {
      final day = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );
      
      if (!activityByDay.containsKey(day)) {
        activityByDay[day] = [];
      }
      
      activityByDay[day]!.add(activity);
      
      // Count activity types
      _activityTypeCount[activity.type] = (_activityTypeCount[activity.type] ?? 0) + 1;
      
      // Track total metrics
      _totalCaloriesBurned += activity.caloriesBurned;
      _totalActiveMinutes += activity.duration;
    }
    
    // Create daily summaries
    for (final day in activityByDay.keys) {
      final dayActivities = activityByDay[day]!;
      
      // Calories burned per day
      _caloriesByDay[day] = dayActivities.fold(
        0, 
        (sum, activity) => sum + activity.caloriesBurned,
      );
      
      // Steps per day
      _stepsByDay[day] = dayActivities.fold(
        0, 
        (sum, activity) => sum + (activity.steps ?? 0),
      );
      
      // Workout duration per day
      _workoutDurationByDay[day] = dayActivities.fold(
        0, 
        (sum, activity) => sum + activity.duration,
      );
    }
    
    // Fill in missing days with zeros
    final daysDiff = _endDate.difference(_startDate).inDays;
    for (int i = 0; i <= daysDiff; i++) {
      final day = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day + i,
      );
      
      if (!_caloriesByDay.containsKey(day)) {
        _caloriesByDay[day] = 0;
      }
      
      if (!_stepsByDay.containsKey(day)) {
        _stepsByDay[day] = 0;
      }
      
      if (!_workoutDurationByDay.containsKey(day)) {
        _workoutDurationByDay[day] = 0;
      }
    }
  }

  void _processNutritionData() {
    // Reset data
    _caloriesConsumedByDay = {};
    _macrosByDay = {};
    _foodCategoryCount = {};
    _totalCaloriesConsumed = 0;
    _avgProteinPerDay = 0;
    _avgCarbsPerDay = 0;
    _avgFatPerDay = 0;
    
    // Group food entries by day
    final entriesByDay = <DateTime, List<NutritionModel>>{};
    
    for (final entry in _foodEntries) {
      final day = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      
      if (!entriesByDay.containsKey(day)) {
        entriesByDay[day] = [];
      }
      
      entriesByDay[day]!.add(entry);
      
      // Count food categories
      _foodCategoryCount[entry.category] = (_foodCategoryCount[entry.category] ?? 0) + 1;
      
      // Track total calories
      _totalCaloriesConsumed += entry.calories;
    }
    
    // Calculate daily totals
    for (final day in entriesByDay.keys) {
      final dayEntries = entriesByDay[day]!;
      
      // Calories consumed per day
      _caloriesConsumedByDay[day] = dayEntries.fold(
        0, 
        (sum, entry) => sum + entry.calories,
      );
      
      // Macros per day
      final protein = dayEntries.fold(
        0, 
        (sum, entry) => sum + entry.protein,
      );
      
      final carbs = dayEntries.fold(
        0, 
        (sum, entry) => sum + entry.carbs,
      );
      
      final fat = dayEntries.fold(
        0, 
        (sum, entry) => sum + entry.fat,
      );
      
      _macrosByDay[day] = {
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
    }
    
    // Fill in missing days with zeros
    final daysDiff = _endDate.difference(_startDate).inDays;
    for (int i = 0; i <= daysDiff; i++) {
      final day = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day + i,
      );
      
      if (!_caloriesConsumedByDay.containsKey(day)) {
        _caloriesConsumedByDay[day] = 0;
      }
      
      if (!_macrosByDay.containsKey(day)) {
        _macrosByDay[day] = {
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        };
      }
    }
    
    // Calculate average macros per day
    if (_macrosByDay.isNotEmpty) {
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;
      
      _macrosByDay.values.forEach((macros) {
        totalProtein += macros['protein'] ?? 0;
        totalCarbs += macros['carbs'] ?? 0;
        totalFat += macros['fat'] ?? 0;
      });
      
      final daysCount = _macrosByDay.length;
      _avgProteinPerDay = totalProtein ~/ daysCount;
      _avgCarbsPerDay = totalCarbs ~/ daysCount;
      _avgFatPerDay = totalFat ~/ daysCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Nutrition'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading progress data...')
          : Column(
              children: [
                // Date range selector
                _buildDateRangeSelector(),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivityTab(),
                      _buildNutritionTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRangeChip('week', 'Week'),
          const SizedBox(width: 8),
          _buildRangeChip('month', 'Month'),
          const SizedBox(width: 8),
          _buildRangeChip('year', 'Year'),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String value, String label) {
    final isSelected = _selectedDateRange == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateDateRange(value);
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Activity summary
        SectionCard(
          title: 'Activity Summary',
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.local_fire_department,
                    value: '$_totalCaloriesBurned',
                    label: 'Calories Burned',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    icon: Icons.timer,
                    value: '$_totalActiveMinutes',
                    label: 'Active Minutes',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    icon: Icons.fitness_center,
                    value: '$_totalActivities',
                    label: 'Workouts',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Calories chart
        SectionCard(
          title: 'Calories Burned',
          children: [
            SizedBox(
              height: 250,
              child: _buildCaloriesChart(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Activity breakdown
        SectionCard(
          title: 'Activity Breakdown',
          children: [
            SizedBox(
              height: 250,
              child: _buildActivityBreakdownChart(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Active minutes chart
        SectionCard(
          title: 'Active Minutes',
          children: [
            SizedBox(
              height: 250,
              child: _buildActiveMinutesChart(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Nutrition summary
        SectionCard(
          title: 'Nutrition Summary',
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.restaurant,
                    value: '$_totalCaloriesConsumed',
                    label: 'Calories Consumed',
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    icon: Icons.balance,
                    value: '${_totalCaloriesConsumed - _totalCaloriesBurned}',
                    label: 'Calorie Balance',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    icon: Icons.pie_chart,
                    value: '$_avgProteinPerDay g',
                    label: 'Avg. Protein',
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Calories consumed chart
        SectionCard(
          title: 'Calories Consumed',
          children: [
            SizedBox(
              height: 250,
              child: _buildCaloriesConsumedChart(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Macronutrient breakdown
        SectionCard(
          title: 'Average Macronutrient Breakdown',
          children: [
            SizedBox(
              height: 250,
              child: _buildMacrosChart(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Calorie balance chart
        SectionCard(
          title: 'Calorie Balance',
          children: [
            SizedBox(
              height: 250,
              child: _buildCalorieBalanceChart(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaloriesChart() {
    final sortedDays = _caloriesByDay.keys.toList()..sort();
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _caloriesByDay.values.isEmpty
              ? 500
              : (_caloriesByDay.values.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= sortedDays.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final date = sortedDays[value.toInt()];
                  String dateStr;
                  
                  if (_selectedDateRange == 'week') {
                    dateStr = DateFormat('E').format(date); // Day of week
                  } else if (_selectedDateRange == 'month') {
                    dateStr = DateFormat('dd').format(date); // Day of month
                  } else {
                    dateStr = DateFormat('MMM').format(date); // Month
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateStr,
                      style: AppTextStyles.caption,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(
            sortedDays.length,
            (index) {
              final day = sortedDays[index];
              final calories = _caloriesByDay[day] ?? 0;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: calories.toDouble(),
                    color: AppColors.primary,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActivityBreakdownChart() {
    if (_activityTypeCount.isEmpty) {
      return const Center(
        child: Text('No activity data available'),
      );
    }
    
    return PieChart(
      PieChartData(
        sections: _activityTypeCount.entries.map((entry) {
          final type = entry.key;
          final count = entry.value;
          final percent = count / _totalActivities * 100;
          
          return PieChartSectionData(
            color: ActivityTypes.getColorForType(type),
            value: count.toDouble(),
            title: '${percent.round()}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
      swapAnimationDuration: const Duration(milliseconds: 150),
    );
  }

  Widget _buildActiveMinutesChart() {
    final sortedDays = _workoutDurationByDay.keys.toList()..sort();
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _workoutDurationByDay.values.isEmpty
              ? 60
              : (_workoutDurationByDay.values.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= sortedDays.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final date = sortedDays[value.toInt()];
                  String dateStr;
                  
                  if (_selectedDateRange == 'week') {
                    dateStr = DateFormat('E').format(date); // Day of week
                  } else if (_selectedDateRange == 'month') {
                    dateStr = DateFormat('dd').format(date); // Day of month
                  } else {
                    dateStr = DateFormat('MMM').format(date); // Month
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateStr,
                      style: AppTextStyles.caption,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(
            sortedDays.length,
            (index) {
              final day = sortedDays[index];
              final duration = _workoutDurationByDay[day] ?? 0;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: duration.toDouble(),
                    color: Colors.green,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesConsumedChart() {
    final sortedDays = _caloriesConsumedByDay.keys.toList()..sort();
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _caloriesConsumedByDay.values.isEmpty
              ? 2000
              : (_caloriesConsumedByDay.values.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= sortedDays.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final date = sortedDays[value.toInt()];
                  String dateStr;
                  
                  if (_selectedDateRange == 'week') {
                    dateStr = DateFormat('E').format(date); // Day of week
                  } else if (_selectedDateRange == 'month') {
                    dateStr = DateFormat('dd').format(date); // Day of month
                  } else {
                    dateStr = DateFormat('MMM').format(date); // Month
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateStr,
                      style: AppTextStyles.caption,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(
            sortedDays.length,
            (index) {
              final day = sortedDays[index];
              final calories = _caloriesConsumedByDay[day] ?? 0;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: calories.toDouble(),
                    color: Colors.amber,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMacrosChart() {
    if (_avgProteinPerDay == 0 && _avgCarbsPerDay == 0 && _avgFatPerDay == 0) {
      return const Center(
        child: Text('No nutrition data available'),
      );
    }
    
    final total = _avgProteinPerDay + _avgCarbsPerDay + _avgFatPerDay;
    
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.redAccent,
            value: _avgProteinPerDay.toDouble(),
            title: '${((_avgProteinPerDay / total) * 100).round()}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.amber,
            value: _avgCarbsPerDay.toDouble(),
            title: '${((_avgCarbsPerDay / total) * 100).round()}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.blueAccent,
            value: _avgFatPerDay.toDouble(),
            title: '${((_avgFatPerDay / total) * 100).round()}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
      swapAnimationDuration: const Duration(milliseconds: 150),
    );
  }

  Widget _buildCalorieBalanceChart() {
    final sortedDays = _caloriesConsumedByDay.keys.toList()..sort();
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          lineTouchData: const LineTouchData(enabled: true),
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= sortedDays.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final date = sortedDays[value.toInt()];
                  String dateStr;
                  
                  if (_selectedDateRange == 'week') {
                    dateStr = DateFormat('E').format(date); // Day of week
                  } else if (_selectedDateRange == 'month') {
                    dateStr = DateFormat('dd').format(date); // Day of month
                  } else {
                    dateStr = DateFormat('MMM').format(date); // Month
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateStr,
                      style: AppTextStyles.caption,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Calories In
            LineChartBarData(
              spots: List.generate(
                sortedDays.length,
                (index) {
                  final day = sortedDays[index];
                  final caloriesIn = _caloriesConsumedByDay[day] ?? 0;
                  
                  return FlSpot(index.toDouble(), caloriesIn.toDouble());
                },
              ),
              isCurved: true,
              barWidth: 3,
              color: Colors.amber,
              dotData: const FlDotData(show: false),
            ),
            // Calories Out
            LineChartBarData(
              spots: List.generate(
                sortedDays.length,
                (index) {
                  final day = sortedDays[index];
                  final caloriesOut = _caloriesByDay[day] ?? 0;
                  
                  return FlSpot(index.toDouble(), caloriesOut.toDouble());
                },
              ),
              isCurved: true,
              barWidth: 3,
              color: AppColors.primary,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}