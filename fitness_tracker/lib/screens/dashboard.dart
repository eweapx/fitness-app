import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../models/nutrition_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  UserModel? _user;
  List<ActivityModel> _activities = [];
  List<NutritionModel> _foodEntries = [];
  
  // Summary stats
  int _totalCaloriesConsumed = 0;
  int _totalCaloriesBurned = 0;
  int _totalSteps = 0;
  int _totalWorkoutMinutes = 0;
  double _totalDistance = 0;
  String _macroRatio = '0:0:0';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd get the current user ID
      const String demoUserId = 'demo_user';
      
      // Load user data
      final user = await _firebaseService.getUserProfile(demoUserId);
      
      // Load activities for selected date
      final activities = await _firebaseService.getActivitiesByDate(
        demoUserId, 
        _selectedDate,
      );
      
      // Load nutrition entries for selected date
      final foodEntries = await _firebaseService.getNutritionByDate(
        demoUserId, 
        _selectedDate,
      );
      
      // Calculate summary stats
      int caloriesBurned = 0;
      int steps = 0;
      int workoutMinutes = 0;
      double distance = 0;
      
      for (var activity in activities) {
        caloriesBurned += activity.caloriesBurned;
        steps += activity.steps ?? 0;
        workoutMinutes += activity.duration;
        distance += activity.distance ?? 0;
      }
      
      int caloriesConsumed = 0;
      String macroRatio = '0:0:0';
      
      if (foodEntries.isNotEmpty) {
        caloriesConsumed = foodEntries.getTotalCalories();
        macroRatio = foodEntries.getAverageMacroRatio();
      }
      
      // Update state with loaded data
      setState(() {
        _user = user;
        _activities = activities;
        _foodEntries = foodEntries;
        _totalCaloriesConsumed = caloriesConsumed;
        _totalCaloriesBurned = caloriesBurned;
        _totalSteps = steps;
        _totalWorkoutMinutes = workoutMinutes;
        _totalDistance = distance;
        _macroRatio = macroRatio;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                _onDateChanged(pickedDate);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading dashboard data...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildDashboardContent(),
            ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Center(
            child: DateSelector(
              selectedDate: _selectedDate,
              onDateSelected: _onDateChanged,
            ),
          ),
          const SizedBox(height: 16),
          
          // Key stats
          _buildStatsSummary(),
          const SizedBox(height: 16),
          
          // Calorie balance
          _buildCalorieBalance(),
          const SizedBox(height: 16),
          
          // Activity summary
          if (_activities.isNotEmpty) ...[
            _buildActivitySummary(),
            const SizedBox(height: 16),
          ],
          
          // Nutrition summary
          if (_foodEntries.isNotEmpty) ...[
            _buildNutritionSummary(),
            const SizedBox(height: 16),
          ],
          
          // Call to action cards
          _buildCallToActionCards(),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final calorieGoal = _user?.dailyCalorieGoal ?? 2000;
    final stepGoal = _user?.dailyStepsGoal ?? 10000;
    
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department,
            value: _totalCaloriesBurned.toString(),
            label: 'Calories Burned',
            color: Colors.orange,
          ),
        ),
        Expanded(
          child: StatCard(
            icon: Icons.directions_walk,
            value: _totalSteps.toString(),
            label: 'Steps',
            color: Colors.blue,
            onTap: () {
              // Navigate to steps detail
            },
          ),
        ),
        Expanded(
          child: StatCard(
            icon: Icons.timer,
            value: '$_totalWorkoutMinutes min',
            label: 'Active Time',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCalorieBalance() {
    final calorieGoal = _user?.dailyCalorieGoal ?? 2000;
    final calorieBalance = calorieGoal - _totalCaloriesConsumed + _totalCaloriesBurned;
    final isPositiveBalance = calorieBalance >= 0;
    
    return SectionCard(
      title: 'Calorie Balance',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal: $calorieGoal cal',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Food: $_totalCaloriesConsumed cal',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Exercise: +$_totalCaloriesBurned cal',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPositiveBalance ? 'Remaining' : 'Exceeded',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '${isPositiveBalance ? '' : '-'}$calorieBalance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPositiveBalance ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  'calories',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LabeledProgressBar(
          label: 'Daily Calories',
          value: '$_totalCaloriesConsumed / $calorieGoal',
          progress: _totalCaloriesConsumed / calorieGoal,
          color: _totalCaloriesConsumed > calorieGoal 
              ? AppColors.error 
              : AppColors.success,
          showPercentage: true,
        ),
      ],
    );
  }

  Widget _buildActivitySummary() {
    return SectionCard(
      title: 'Activity Summary',
      trailing: TextButton(
        onPressed: () {
          // Navigate to activity screen
        },
        child: Text('View All', style: TextStyle(color: AppColors.primary)),
      ),
      children: [
        if (_activities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No activities recorded today'),
            ),
          )
        else ...[
          // Display the first 3 activities
          ..._activities.take(3).map((activity) => _buildActivityItem(activity)),
          
          // Show more count if there are more activities
          if (_activities.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+ ${_activities.length - 3} more activities',
                  style: AppTextStyles.caption,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildActivityItem(ActivityModel activity) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: ActivityTypes.getColorForType(activity.type).withOpacity(0.2),
        child: Icon(
          ActivityTypes.getIconForType(activity.type),
          color: ActivityTypes.getColorForType(activity.type),
        ),
      ),
      title: Text(activity.name),
      subtitle: Text(
        '${activity.duration} min • ${activity.caloriesBurned} cal${activity.distance != null ? ' • ${activity.distance!.toStringAsFixed(2)} km' : ''}',
      ),
      trailing: Text(
        DateFormat.jm().format(activity.date),
        style: AppTextStyles.caption,
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return SectionCard(
      title: 'Nutrition Summary',
      trailing: TextButton(
        onPressed: () {
          // Navigate to nutrition screen
        },
        child: Text('View All', style: TextStyle(color: AppColors.primary)),
      ),
      children: [
        if (_foodEntries.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No food entries recorded today'),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientCircle(
                  'Protein',
                  _foodEntries.getTotalProtein(),
                  'g',
                  Colors.redAccent,
                ),
                _buildNutrientCircle(
                  'Carbs',
                  _foodEntries.getTotalCarbs(),
                  'g',
                  Colors.amber,
                ),
                _buildNutrientCircle(
                  'Fat',
                  _foodEntries.getTotalFat(),
                  'g',
                  Colors.blueAccent,
                ),
              ],
            ),
          ),
          
          // Display the first 3 food entries
          ..._foodEntries.take(3).map((entry) => _buildFoodEntryItem(entry)),
          
          // Show more count if there are more entries
          if (_foodEntries.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+ ${_foodEntries.length - 3} more food entries',
                  style: AppTextStyles.caption,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildNutrientCircle(String label, int value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildFoodEntryItem(NutritionModel entry) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: FoodCategories.getColorForCategory(entry.category).withOpacity(0.2),
        child: Icon(
          FoodCategories.getIconForCategory(entry.category),
          color: FoodCategories.getColorForCategory(entry.category),
        ),
      ),
      title: Text(entry.name),
      subtitle: Text(
        '${entry.calories} cal • ${entry.protein}g protein • ${entry.carbs}g carbs • ${entry.fat}g fat',
      ),
      trailing: Text(
        entry.mealType ?? 'Meal',
        style: AppTextStyles.caption,
      ),
    );
  }

  Widget _buildCallToActionCards() {
    return Column(
      children: [
        SectionCard(
          title: 'Fitness Goals',
          trailing: const Icon(Icons.flag, color: AppColors.accent),
          onTap: () {
            // Navigate to goals screen
          },
          children: [
            const Text('Set and track your fitness goals to stay motivated and make progress.'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SectionCard(
                title: 'Add Activity',
                trailing: const Icon(Icons.add, color: AppColors.primary),
                onTap: () {
                  // Navigate to add activity
                },
                children: [
                  const Text('Log your workouts and daily activities'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SectionCard(
                title: 'Log Food',
                trailing: const Icon(Icons.add, color: AppColors.primary),
                onTap: () {
                  // Navigate to add food
                },
                children: [
                  const Text('Record your meals and nutrition intake'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}