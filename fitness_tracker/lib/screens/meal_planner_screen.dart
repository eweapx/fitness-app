import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/meal_model.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  _MealPlannerScreenState createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  Map<String, List<MealPlan>> _mealPlans = {};
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  
  // Dietary Preferences
  String _selectedDiet = 'Regular';
  final List<String> _dietaryPreferences = [
    'Regular',
    'Vegetarian',
    'Vegan',
    'Keto',
    'Paleo',
    'Pescatarian',
    'Gluten-Free',
  ];

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Calculate date range for the week
      final now = _selectedDate;
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      // Get meal plans for the week
      final mealPlans = await _firebaseService.getMealPlansForDateRange(
        demoUserId,
        startOfWeek,
        endOfWeek,
      );
      
      // Group meals by date
      final Map<String, List<MealPlan>> groupedMeals = {};
      for (var i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        groupedMeals[dateString] = [];
      }
      
      // Add meals to the appropriate date
      for (final meal in mealPlans) {
        final dateString = DateFormat('yyyy-MM-dd').format(meal.date);
        if (groupedMeals.containsKey(dateString)) {
          groupedMeals[dateString]!.add(meal);
        }
      }
      
      setState(() {
        _mealPlans = groupedMeals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meal plans: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading meal plans: ${e.toString()}')),
      );
    }
  }
  
  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _loadMealPlans();
  }
  
  Future<void> _addMealPlan(String mealType) async {
    // Show dialog to add meal
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildAddMealDialog(mealType),
    );
    
    if (result != null) {
      setState(() => _isLoading = true);
      
      try {
        // In a real app, we'd use the current user's ID
        const String demoUserId = 'demo_user';
        
        // Create meal plan
        final mealPlan = MealPlan(
          id: null, // Firebase will generate an ID
          userId: demoUserId,
          name: result['name'],
          description: result['description'],
          type: mealType,
          calories: result['calories'],
          protein: result['protein'],
          carbs: result['carbs'],
          fat: result['fat'],
          date: _selectedDate,
          isDone: false,
        );
        
        // Save to Firebase
        await _firebaseService.addMealPlan(mealPlan);
        
        // Reload meal plans
        await _loadMealPlans();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal plan added successfully!')),
        );
      } catch (e) {
        print('Error adding meal plan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding meal plan: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _updateMealPlanStatus(MealPlan mealPlan, bool isDone) async {
    try {
      // Update local state
      final dateString = DateFormat('yyyy-MM-dd').format(mealPlan.date);
      final meals = _mealPlans[dateString] ?? [];
      
      final updatedMeals = meals.map((meal) {
        if (meal.id == mealPlan.id) {
          return MealPlan(
            id: meal.id,
            userId: meal.userId,
            name: meal.name,
            description: meal.description,
            type: meal.type,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            date: meal.date,
            isDone: isDone,
          );
        }
        return meal;
      }).toList();
      
      setState(() {
        _mealPlans[dateString] = updatedMeals;
      });
      
      // Save to Firebase
      final updatedMealPlan = MealPlan(
        id: mealPlan.id,
        userId: mealPlan.userId,
        name: mealPlan.name,
        description: mealPlan.description,
        type: mealPlan.type,
        calories: mealPlan.calories,
        protein: mealPlan.protein,
        carbs: mealPlan.carbs,
        fat: mealPlan.fat,
        date: mealPlan.date,
        isDone: isDone,
      );
      
      await _firebaseService.updateMealPlan(updatedMealPlan);
    } catch (e) {
      print('Error updating meal plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating meal plan: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _deleteMealPlan(MealPlan mealPlan) async {
    try {
      // Delete from Firebase
      await _firebaseService.deleteMealPlan(mealPlan.id!);
      
      // Update local state
      final dateString = DateFormat('yyyy-MM-dd').format(mealPlan.date);
      final meals = _mealPlans[dateString] ?? [];
      
      setState(() {
        _mealPlans[dateString] = meals.where((meal) => meal.id != mealPlan.id).toList();
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting meal plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting meal plan: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _generateMealPlan() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Get user profile to determine calorie goals
      final userProfile = await _firebaseService.getUserProfile(demoUserId);
      int dailyCalories = 2000; // Default
      
      if (userProfile != null && userProfile.goals != null) {
        if (userProfile.goals!.containsKey('dailyCalories')) {
          dailyCalories = userProfile.goals!['dailyCalories'];
        }
      }
      
      // Generate meal plans for each meal type
      for (final mealType in _mealTypes) {
        // Calculate portion of daily calories for each meal type
        int mealCalories;
        switch (mealType) {
          case 'Breakfast':
            mealCalories = (dailyCalories * 0.25).round(); // 25% of daily calories
            break;
          case 'Lunch':
            mealCalories = (dailyCalories * 0.35).round(); // 35% of daily calories
            break;
          case 'Dinner':
            mealCalories = (dailyCalories * 0.30).round(); // 30% of daily calories
            break;
          case 'Snack':
            mealCalories = (dailyCalories * 0.10).round(); // 10% of daily calories
            break;
          default:
            mealCalories = (dailyCalories * 0.25).round();
        }
        
        try {
          // In a real app, we would use a nutrition API to generate meal suggestions
          // Here we'll use a simple example based on dietary preference
          
          // Generate meal details based on diet preference
          Map<String, dynamic> mealDetails = _generateMealDetails(mealType, mealCalories);
          
          // Create meal plan
          final mealPlan = MealPlan(
            id: null, // Firebase will generate an ID
            userId: demoUserId,
            name: mealDetails['name'],
            description: mealDetails['description'],
            type: mealType,
            calories: mealDetails['calories'],
            protein: mealDetails['protein'],
            carbs: mealDetails['carbs'],
            fat: mealDetails['fat'],
            date: _selectedDate,
            isDone: false,
          );
          
          // Save to Firebase
          await _firebaseService.addMealPlan(mealPlan);
        } catch (e) {
          print('Error generating meal for $mealType: $e');
        }
      }
      
      // Reload meal plans
      await _loadMealPlans();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plans generated successfully!')),
      );
    } catch (e) {
      print('Error generating meal plans: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating meal plans: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Map<String, dynamic> _generateMealDetails(String mealType, int targetCalories) {
    // This is a simplified example - in a real app, we would use a nutrition API
    // or a more sophisticated algorithm based on the user's dietary preferences
    
    switch (_selectedDiet) {
      case 'Vegetarian':
        switch (mealType) {
          case 'Breakfast':
            return {
              'name': 'Vegetarian Breakfast Bowl',
              'description': 'Oatmeal with fruits, nuts, and yogurt',
              'calories': targetCalories,
              'protein': (targetCalories * 0.2 / 4).round(), // 20% protein
              'carbs': (targetCalories * 0.6 / 4).round(), // 60% carbs
              'fat': (targetCalories * 0.2 / 9).round(), // 20% fat
            };
          case 'Lunch':
            return {
              'name': 'Mediterranean Salad',
              'description': 'Fresh greens, feta cheese, olives, and avocado',
              'calories': targetCalories,
              'protein': (targetCalories * 0.25 / 4).round(), // 25% protein
              'carbs': (targetCalories * 0.45 / 4).round(), // 45% carbs
              'fat': (targetCalories * 0.3 / 9).round(), // 30% fat
            };
          case 'Dinner':
            return {
              'name': 'Vegetable Stir Fry',
              'description': 'Mixed vegetables with tofu and brown rice',
              'calories': targetCalories,
              'protein': (targetCalories * 0.3 / 4).round(), // 30% protein
              'carbs': (targetCalories * 0.4 / 4).round(), // 40% carbs
              'fat': (targetCalories * 0.3 / 9).round(), // 30% fat
            };
          case 'Snack':
            return {
              'name': 'Fruit & Nut Mix',
              'description': 'Mixed berries with almonds',
              'calories': targetCalories,
              'protein': (targetCalories * 0.15 / 4).round(), // 15% protein
              'carbs': (targetCalories * 0.55 / 4).round(), // 55% carbs
              'fat': (targetCalories * 0.3 / 9).round(), // 30% fat
            };
          default:
            return {
              'name': 'Vegetarian Snack',
              'description': 'Healthy vegetarian option',
              'calories': targetCalories,
              'protein': (targetCalories * 0.2 / 4).round(),
              'carbs': (targetCalories * 0.5 / 4).round(),
              'fat': (targetCalories * 0.3 / 9).round(),
            };
        }
      
      case 'Vegan':
        switch (mealType) {
          case 'Breakfast':
            return {
              'name': 'Vegan Breakfast Bowl',
              'description': 'Chia pudding with almond milk and fruits',
              'calories': targetCalories,
              'protein': (targetCalories * 0.15 / 4).round(), // 15% protein
              'carbs': (targetCalories * 0.65 / 4).round(), // 65% carbs
              'fat': (targetCalories * 0.2 / 9).round(), // 20% fat
            };
          case 'Lunch':
            return {
              'name': 'Quinoa Buddha Bowl',
              'description': 'Quinoa, roasted vegetables, and avocado',
              'calories': targetCalories,
              'protein': (targetCalories * 0.2 / 4).round(), // 20% protein
              'carbs': (targetCalories * 0.55 / 4).round(), // 55% carbs
              'fat': (targetCalories * 0.25 / 9).round(), // 25% fat
            };
          case 'Dinner':
            return {
              'name': 'Lentil Curry',
              'description': 'Spicy lentils with vegetables and brown rice',
              'calories': targetCalories,
              'protein': (targetCalories * 0.25 / 4).round(), // 25% protein
              'carbs': (targetCalories * 0.5 / 4).round(), // 50% carbs
              'fat': (targetCalories * 0.25 / 9).round(), // 25% fat
            };
          case 'Snack':
            return {
              'name': 'Energy Bites',
              'description': 'Date and nut energy balls',
              'calories': targetCalories,
              'protein': (targetCalories * 0.1 / 4).round(), // 10% protein
              'carbs': (targetCalories * 0.6 / 4).round(), // 60% carbs
              'fat': (targetCalories * 0.3 / 9).round(), // 30% fat
            };
          default:
            return {
              'name': 'Vegan Snack',
              'description': 'Plant-based energy boost',
              'calories': targetCalories,
              'protein': (targetCalories * 0.15 / 4).round(),
              'carbs': (targetCalories * 0.6 / 4).round(),
              'fat': (targetCalories * 0.25 / 9).round(),
            };
        }
      
      case 'Keto':
        switch (mealType) {
          case 'Breakfast':
            return {
              'name': 'Keto Breakfast',
              'description': 'Avocado and bacon with eggs',
              'calories': targetCalories,
              'protein': (targetCalories * 0.3 / 4).round(), // 30% protein
              'carbs': (targetCalories * 0.05 / 4).round(), // 5% carbs
              'fat': (targetCalories * 0.65 / 9).round(), // 65% fat
            };
          case 'Lunch':
            return {
              'name': 'Keto Salad',
              'description': 'Mixed greens with cheese, avocado, and olive oil',
              'calories': targetCalories,
              'protein': (targetCalories * 0.25 / 4).round(), // 25% protein
              'carbs': (targetCalories * 0.05 / 4).round(), // 5% carbs
              'fat': (targetCalories * 0.7 / 9).round(), // 70% fat
            };
          case 'Dinner':
            return {
              'name': 'Keto Salmon',
              'description': 'Grilled salmon with asparagus and butter',
              'calories': targetCalories,
              'protein': (targetCalories * 0.35 / 4).round(), // 35% protein
              'carbs': (targetCalories * 0.05 / 4).round(), // 5% carbs
              'fat': (targetCalories * 0.6 / 9).round(), // 60% fat
            };
          case 'Snack':
            return {
              'name': 'Keto Fat Bombs',
              'description': 'Coconut oil and dark chocolate treats',
              'calories': targetCalories,
              'protein': (targetCalories * 0.1 / 4).round(), // 10% protein
              'carbs': (targetCalories * 0.05 / 4).round(), // 5% carbs
              'fat': (targetCalories * 0.85 / 9).round(), // 85% fat
            };
          default:
            return {
              'name': 'Keto Snack',
              'description': 'High fat, low carb option',
              'calories': targetCalories,
              'protein': (targetCalories * 0.2 / 4).round(),
              'carbs': (targetCalories * 0.05 / 4).round(),
              'fat': (targetCalories * 0.75 / 9).round(),
            };
        }
      
      // Add more diet types here
      
      default: // Regular
        switch (mealType) {
          case 'Breakfast':
            return {
              'name': 'Balanced Breakfast',
              'description': 'Scrambled eggs with toast and fruit',
              'calories': targetCalories,
              'protein': (targetCalories * 0.25 / 4).round(), // 25% protein
              'carbs': (targetCalories * 0.5 / 4).round(), // 50% carbs
              'fat': (targetCalories * 0.25 / 9).round(), // 25% fat
            };
          case 'Lunch':
            return {
              'name': 'Chicken Salad',
              'description': 'Grilled chicken with mixed greens and vinaigrette',
              'calories': targetCalories,
              'protein': (targetCalories * 0.35 / 4).round(), // 35% protein
              'carbs': (targetCalories * 0.4 / 4).round(), // 40% carbs
              'fat': (targetCalories * 0.25 / 9).round(), // 25% fat
            };
          case 'Dinner':
            return {
              'name': 'Salmon with Rice',
              'description': 'Baked salmon with brown rice and vegetables',
              'calories': targetCalories,
              'protein': (targetCalories * 0.3 / 4).round(), // 30% protein
              'carbs': (targetCalories * 0.45 / 4).round(), // 45% carbs
              'fat': (targetCalories * 0.25 / 9).round(), // 25% fat
            };
          case 'Snack':
            return {
              'name': 'Greek Yogurt with Berries',
              'description': 'Greek yogurt with mixed berries and honey',
              'calories': targetCalories,
              'protein': (targetCalories * 0.3 / 4).round(), // 30% protein
              'carbs': (targetCalories * 0.45 / 4).round(), // 45% carbs
              'fat': (targetCalories * 0.25 / 9).round(), // 25% fat
            };
          default:
            return {
              'name': 'Healthy Snack',
              'description': 'Balanced macronutrient option',
              'calories': targetCalories,
              'protein': (targetCalories * 0.25 / 4).round(),
              'carbs': (targetCalories * 0.5 / 4).round(),
              'fat': (targetCalories * 0.25 / 9).round(),
            };
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final mealsForSelectedDate = _mealPlans[selectedDateString] ?? [];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew),
            onPressed: _generateMealPlan,
            tooltip: 'Generate Meal Plan',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading meal plans...')
          : Column(
              children: [
                _buildDietSelector(),
                _buildDateSelector(),
                Expanded(
                  child: _buildMealList(mealsForSelectedDate),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show menu to select meal type
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildMealTypeSelector(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildDietSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Dietary Preference:',
                style: AppTextStyles.body,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedDiet,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedDiet = value!);
                  },
                  items: _dietaryPreferences.map((diet) {
                    return DropdownMenuItem<String>(
                      value: diet,
                      child: Text(diet),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateSelector() {
    // Calculate date range for the week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // Format the month range for display
    final monthFormatter = DateFormat('MMMM');
    final startMonth = monthFormatter.format(startOfWeek);
    final endMonth = monthFormatter.format(startOfWeek.add(const Duration(days: 6)));
    
    // Month display text
    final monthDisplay = startMonth == endMonth
        ? startMonth
        : '$startMonth - $endMonth';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthDisplay,
                style: AppTextStyles.heading3,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                      });
                      _loadMealPlans();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 7));
                      });
                      _loadMealPlans();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = startOfWeek.add(Duration(days: index));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                                  DateFormat('yyyy-MM-dd').format(_selectedDate);
                
                return _buildDateItem(date, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateItem(DateTime date, bool isSelected) {
    final dayFormatter = DateFormat('E');
    final dateFormatter = DateFormat('d');
    
    final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                   DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        width: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? AppColors.primary : Colors.grey.shade300,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayFormatter.format(date),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              dateFormatter.format(date),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMealList(List<MealPlan> meals) {
    // Group meals by type
    final Map<String, List<MealPlan>> groupedMeals = {};
    for (final type in _mealTypes) {
      groupedMeals[type] = meals.where((meal) => meal.type == type).toList();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _mealTypes.length,
      itemBuilder: (context, index) {
        final mealType = _mealTypes[index];
        final mealsForType = groupedMeals[mealType] ?? [];
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mealType,
                      style: AppTextStyles.heading3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _addMealPlan(mealType),
                      tooltip: 'Add $mealType',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (mealsForType.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No meals planned',
                        style: AppTextStyles.body,
                      ),
                    ),
                  )
                else
                  ...mealsForType.map((meal) => _buildMealItem(meal)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMealItem(MealPlan meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: meal.isDone ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: meal.isDone,
              onChanged: (value) => _updateMealPlanStatus(meal, value!),
            ),
            // Meal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: meal.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (meal.description.isNotEmpty)
                    Text(
                      meal.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        decoration: meal.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildNutrientBadge('Calories', meal.calories.toString()),
                      _buildNutrientBadge('P', '${meal.protein}g'),
                      _buildNutrientBadge('C', '${meal.carbs}g'),
                      _buildNutrientBadge('F', '${meal.fat}g'),
                    ],
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteMealPlan(meal),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutrientBadge(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildMealTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add Meal Plan',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          ...List.generate(_mealTypes.length, (index) {
            final mealType = _mealTypes[index];
            return ListTile(
              leading: Icon(_getMealTypeIcon(mealType)),
              title: Text(mealType),
              onTap: () {
                Navigator.pop(context);
                _addMealPlan(mealType);
              },
            );
          }),
        ],
      ),
    );
  }
  
  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.free_breakfast;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
  
  Widget _buildAddMealDialog(String mealType) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    
    return AlertDialog(
      title: Text('Add $mealType'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
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
            // Validate inputs
            if (nameController.text.isEmpty || caloriesController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter meal name and calories'),
                ),
              );
              return;
            }
            
            final calories = int.tryParse(caloriesController.text) ?? 0;
            final protein = int.tryParse(proteinController.text) ?? 0;
            final carbs = int.tryParse(carbsController.text) ?? 0;
            final fat = int.tryParse(fatController.text) ?? 0;
            
            // Return meal data
            Navigator.pop(context, {
              'name': nameController.text,
              'description': descriptionController.text,
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat,
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}