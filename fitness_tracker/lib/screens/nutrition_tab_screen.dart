import 'package:flutter/material.dart';
import '../screens/nutrition_screen.dart';
import '../screens/meal_planner_screen.dart';
import '../screens/water_tracking_screen.dart';
import '../models/nutrition_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class NutritionTabScreen extends StatefulWidget {
  const NutritionTabScreen({super.key});

  @override
  _NutritionTabScreenState createState() => _NutritionTabScreenState();
}

class _NutritionTabScreenState extends State<NutritionTabScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  int _caloriesConsumed = 0;
  int _calorieGoal = 2000;
  int _proteinTotal = 0;
  int _carbsTotal = 0;
  int _fatTotal = 0;
  
  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Get today's nutrition entries
      final foodEntries = await _firebaseService.getNutritionByDate(
        demoUserId, 
        DateTime.now(),
      );
      
      // Get user profile to fetch calorie goal
      final userProfile = await _firebaseService.getUserProfile(demoUserId);
      if (userProfile != null && userProfile.goals != null) {
        if (userProfile.goals!.containsKey('dailyCalories')) {
          _calorieGoal = userProfile.goals!['dailyCalories'];
        }
      }
      
      // Calculate nutrition totals
      _caloriesConsumed = foodEntries.getTotalCalories();
      _proteinTotal = foodEntries.getTotalProtein();
      _carbsTotal = foodEntries.getTotalCarbs();
      _fatTotal = foodEntries.getTotalFat();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading nutrition data: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading nutrition data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading nutrition data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calories summary
                  _buildCaloriesSummary(),
                  const SizedBox(height: 16),
                  
                  // Macronutrients
                  _buildMacronutrients(),
                  const SizedBox(height: 16),
                  
                  // Nutrition options
                  _buildNutritionOptions(),
                  const SizedBox(height: 16),
                  
                  // Quick add food
                  _buildQuickAddSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCaloriesSummary() {
    final caloriesRemaining = _calorieGoal - _caloriesConsumed;
    final percentConsumed = _caloriesConsumed / _calorieGoal;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calories Remaining',
                      style: AppTextStyles.heading3,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          caloriesRemaining.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: caloriesRemaining >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'cal',
                          style: AppTextStyles.body.copyWith(
                            color: caloriesRemaining >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CircularPercentIndicator(
                  percent: percentConsumed > 1.0 ? 1.0 : percentConsumed,
                  radius: 40,
                  lineWidth: 10,
                  centerText: '${(_caloriesConsumed * 100 / _calorieGoal).toInt()}%',
                  label: 'Goal',
                  color: percentConsumed > 1.0
                      ? AppColors.error
                      : percentConsumed > 0.9
                          ? AppColors.warning
                          : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCalorieInfoColumn('Goal', _calorieGoal),
                _buildCalorieInfoColumn('Food', _caloriesConsumed),
                _buildCalorieInfoColumn('Remaining', caloriesRemaining),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieInfoColumn(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption,
        ),
        Text(
          value.toString(),
          style: AppTextStyles.heading4,
        ),
        const Text(
          'cal',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildMacronutrients() {
    final total = _proteinTotal + _carbsTotal + _fatTotal;
    final proteinPercent = total > 0 ? (_proteinTotal / total * 100).round() : 0;
    final carbsPercent = total > 0 ? (_carbsTotal / total * 100).round() : 0;
    final fatPercent = total > 0 ? (_fatTotal / total * 100).round() : 0;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Macronutrients',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientCircle(
                  'Protein',
                  _proteinTotal,
                  proteinPercent,
                  Colors.redAccent,
                ),
                _buildNutrientCircle(
                  'Carbs',
                  _carbsTotal,
                  carbsPercent,
                  Colors.amber,
                ),
                _buildNutrientCircle(
                  'Fat',
                  _fatTotal,
                  fatPercent,
                  Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Macronutrient ratio bar
            Row(
              children: [
                Expanded(
                  flex: proteinPercent,
                  child: Container(
                    height: 20,
                    color: Colors.redAccent,
                  ),
                ),
                Expanded(
                  flex: carbsPercent,
                  child: Container(
                    height: 20,
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  flex: fatPercent,
                  child: Container(
                    height: 20,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Protein', Colors.redAccent),
                const SizedBox(width: 16),
                _buildLegendItem('Carbs', Colors.amber),
                const SizedBox(width: 16),
                _buildLegendItem('Fat', Colors.blueAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCircle(
    String label,
    int value,
    int percent,
    Color color,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 8,
            ),
            Column(
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'g',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
        Text(
          '$percent%',
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildNutritionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition Tools',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNutritionOptionCard(
                'Meal Planner',
                Icons.calendar_today,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MealPlannerScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNutritionOptionCard(
                'Food Log',
                Icons.restaurant_menu,
                Colors.amber,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NutritionScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNutritionOptionCard(
                'Water Tracker',
                Icons.water_drop,
                Colors.blueAccent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WaterTrackingScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNutritionOptionCard(
                'Recipes',
                Icons.menu_book,
                Colors.purpleAccent,
                () {
                  // Navigate to recipes screen (would be implemented in a real app)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recipes would open here')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionOptionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Add Food',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAddButton(
                  'Breakfast',
                  Icons.free_breakfast,
                  Colors.orangeAccent,
                ),
                _buildQuickAddButton(
                  'Lunch',
                  Icons.lunch_dining,
                  Colors.green,
                ),
                _buildQuickAddButton(
                  'Dinner',
                  Icons.dinner_dining,
                  Colors.deepPurpleAccent,
                ),
                _buildQuickAddButton(
                  'Snack',
                  Icons.cookie,
                  Colors.amberAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Go to Meal Planner',
              icon: Icons.calendar_today,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealPlannerScreen(),
                  ),
                );
              },
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton(
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Navigate to add food screen with meal type
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Add $label would open here')),
            );
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: color,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}