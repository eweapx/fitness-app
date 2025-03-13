import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  bool _isLoading = true;
  late TabController _tabController;
  
  // Sample data for the charts
  List<FlSpot> _weightData = [];
  List<FlSpot> _calorieData = [];
  List<FlSpot> _workoutData = [];
  List<FlSpot> _stepData = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProgressData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Get last 7 days of data for each chart
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      // Get weight data
      final weightEntries = await _firebaseService.getWeightEntries(
        demoUserId, 
        sevenDaysAgo,
        now,
      );
      
      // Get calorie data
      final calorieEntries = await _firebaseService.getCalorieEntries(
        demoUserId, 
        sevenDaysAgo,
        now,
      );
      
      // Get workout data
      final workoutEntries = await _firebaseService.getWorkoutEntries(
        demoUserId, 
        sevenDaysAgo,
        now,
      );
      
      // Get step data
      final stepEntries = await _firebaseService.getStepEntries(
        demoUserId, 
        sevenDaysAgo,
        now,
      );
      
      // Process data for charts
      _processWeightData(weightEntries);
      _processCalorieData(calorieEntries);
      _processWorkoutData(workoutEntries);
      _processStepData(stepEntries);
      
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
  
  // These methods would process real data in a complete implementation
  void _processWeightData(dynamic entries) {
    // For demo purposes, generate some sample weight data
    final now = DateTime.now();
    _weightData = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return FlSpot(
        index.toDouble(), 
        70.0 - 0.2 * index, // Sample weight data (decreasing)
      );
    });
  }
  
  void _processCalorieData(dynamic entries) {
    // For demo purposes, generate some sample calorie data
    final now = DateTime.now();
    _calorieData = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return FlSpot(
        index.toDouble(), 
        1800 + 100 * (index % 3), // Sample calorie data
      );
    });
  }
  
  void _processWorkoutData(dynamic entries) {
    // For demo purposes, generate some sample workout data
    final now = DateTime.now();
    _workoutData = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return FlSpot(
        index.toDouble(), 
        index % 2 == 0 ? 45.0 : 30.0, // Sample workout duration data
      );
    });
  }
  
  void _processStepData(dynamic entries) {
    // For demo purposes, generate some sample step data
    final now = DateTime.now();
    _stepData = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return FlSpot(
        index.toDouble(), 
        6000 + 500 * index, // Sample step data (increasing)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.monitor_weight),
              text: 'Weight',
            ),
            Tab(
              icon: Icon(Icons.local_fire_department),
              text: 'Calories',
            ),
            Tab(
              icon: Icon(Icons.fitness_center),
              text: 'Workouts',
            ),
            Tab(
              icon: Icon(Icons.directions_walk),
              text: 'Steps',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading progress data...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeightTab(),
                _buildCaloriesTab(),
                _buildWorkoutsTab(),
                _buildStepsTab(),
              ],
            ),
    );
  }
  
  Widget _buildWeightTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(
            'Weight Tracking',
            'Your weight over the last 7 days',
            _buildWeightChart(),
            Icons.monitor_weight,
            Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          _buildWeightSummary(),
        ],
      ),
    );
  }
  
  Widget _buildCaloriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(
            'Calorie Tracking',
            'Your calorie intake over the last 7 days',
            _buildCalorieChart(),
            Icons.local_fire_department,
            Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          _buildCalorieSummary(),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(
            'Workout Tracking',
            'Your workout duration over the last 7 days',
            _buildWorkoutChart(),
            Icons.fitness_center,
            Colors.purpleAccent,
          ),
          const SizedBox(height: 16),
          _buildWorkoutSummary(),
        ],
      ),
    );
  }
  
  Widget _buildStepsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(
            'Step Tracking',
            'Your steps over the last 7 days',
            _buildStepChart(),
            Icons.directions_walk,
            Colors.greenAccent,
          ),
          const SizedBox(height: 16),
          _buildStepSummary(),
        ],
      ),
    );
  }
  
  Widget _buildProgressCard(
    String title,
    String subtitle,
    Widget chart,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading3,
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Handle menu selection
                    if (value == 'refresh') {
                      _loadProgressData();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'refresh',
                      child: Text('Refresh Data'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'timespan',
                      child: Text('Change Timespan'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeightChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Show day of week
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Text(days[index], style: AppTextStyles.caption);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()} kg', style: AppTextStyles.caption);
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _weightData,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalorieChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Show day of week
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Text(days[index], style: AppTextStyles.caption);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: AppTextStyles.caption);
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _calorieData,
            isCurved: true,
            color: Colors.orangeAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orangeAccent.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Show day of week
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Text(days[index], style: AppTextStyles.caption);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()} min', style: AppTextStyles.caption);
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _workoutData,
            isCurved: true,
            color: Colors.purpleAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purpleAccent.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Show day of week
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Text(days[index], style: AppTextStyles.caption);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value >= 1000 
                      ? '${(value / 1000).toStringAsFixed(1)}k' 
                      : value.toInt().toString(), 
                  style: AppTextStyles.caption,
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _stepData,
            isCurved: true,
            color: Colors.greenAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.greenAccent.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeightSummary() {
    // Calculate average, min, and max weight
    final weights = _weightData.map((spot) => spot.y).toList();
    final avgWeight = weights.isNotEmpty 
        ? weights.reduce((a, b) => a + b) / weights.length 
        : 0.0;
    final minWeight = weights.isNotEmpty 
        ? weights.reduce((a, b) => a < b ? a : b) 
        : 0.0;
    final maxWeight = weights.isNotEmpty 
        ? weights.reduce((a, b) => a > b ? a : b) 
        : 0.0;
    final trend = weights.length > 1 
        ? weights.last - weights.first 
        : 0.0;
    
    return _buildSummaryCard(
      'Weight Summary',
      [
        _buildSummaryItem('Average', '${avgWeight.toStringAsFixed(1)} kg', Colors.blue),
        _buildSummaryItem('Minimum', '${minWeight.toStringAsFixed(1)} kg', Colors.green),
        _buildSummaryItem('Maximum', '${maxWeight.toStringAsFixed(1)} kg', Colors.orange),
        _buildSummaryItem(
          'Trend', 
          '${trend >= 0 ? "+" : ""}${trend.toStringAsFixed(1)} kg', 
          trend > 0 ? Colors.red : trend < 0 ? Colors.green : Colors.grey,
        ),
      ],
    );
  }
  
  Widget _buildCalorieSummary() {
    // Calculate average, min, and max calories
    final calories = _calorieData.map((spot) => spot.y).toList();
    final avgCalories = calories.isNotEmpty 
        ? calories.reduce((a, b) => a + b) / calories.length 
        : 0.0;
    final minCalories = calories.isNotEmpty 
        ? calories.reduce((a, b) => a < b ? a : b) 
        : 0.0;
    final maxCalories = calories.isNotEmpty 
        ? calories.reduce((a, b) => a > b ? a : b) 
        : 0.0;
    final totalCalories = calories.isNotEmpty 
        ? calories.reduce((a, b) => a + b)
        : 0.0;
    
    return _buildSummaryCard(
      'Calorie Summary',
      [
        _buildSummaryItem('Average', '${avgCalories.toInt()} cal', Colors.blue),
        _buildSummaryItem('Minimum', '${minCalories.toInt()} cal', Colors.green),
        _buildSummaryItem('Maximum', '${maxCalories.toInt()} cal', Colors.orange),
        _buildSummaryItem('Total', '${totalCalories.toInt()} cal', Colors.red),
      ],
    );
  }
  
  Widget _buildWorkoutSummary() {
    // Calculate average, min, and max workout duration
    final durations = _workoutData.map((spot) => spot.y).toList();
    final avgDuration = durations.isNotEmpty 
        ? durations.reduce((a, b) => a + b) / durations.length 
        : 0.0;
    final minDuration = durations.isNotEmpty 
        ? durations.reduce((a, b) => a < b ? a : b) 
        : 0.0;
    final maxDuration = durations.isNotEmpty 
        ? durations.reduce((a, b) => a > b ? a : b) 
        : 0.0;
    final totalDuration = durations.isNotEmpty 
        ? durations.reduce((a, b) => a + b)
        : 0.0;
    
    return _buildSummaryCard(
      'Workout Summary',
      [
        _buildSummaryItem('Average', '${avgDuration.toInt()} min', Colors.blue),
        _buildSummaryItem('Minimum', '${minDuration.toInt()} min', Colors.green),
        _buildSummaryItem('Maximum', '${maxDuration.toInt()} min', Colors.orange),
        _buildSummaryItem('Total', '${totalDuration.toInt()} min', Colors.red),
      ],
    );
  }
  
  Widget _buildStepSummary() {
    // Calculate average, min, and max steps
    final steps = _stepData.map((spot) => spot.y).toList();
    final avgSteps = steps.isNotEmpty 
        ? steps.reduce((a, b) => a + b) / steps.length 
        : 0.0;
    final minSteps = steps.isNotEmpty 
        ? steps.reduce((a, b) => a < b ? a : b) 
        : 0.0;
    final maxSteps = steps.isNotEmpty 
        ? steps.reduce((a, b) => a > b ? a : b) 
        : 0.0;
    final totalSteps = steps.isNotEmpty 
        ? steps.reduce((a, b) => a + b)
        : 0.0;
    
    return _buildSummaryCard(
      'Step Summary',
      [
        _buildSummaryItem('Average', '${avgSteps.toInt()}', Colors.blue),
        _buildSummaryItem('Minimum', '${minSteps.toInt()}', Colors.green),
        _buildSummaryItem('Maximum', '${maxSteps.toInt()}', Colors.orange),
        _buildSummaryItem('Total', '${totalSteps.toInt()}', Colors.red),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, List<Widget> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Column(
              children: items,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body,
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}