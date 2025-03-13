import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nutrition_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  _MealPlannerScreenState createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  Map<String, List<NutritionModel>> _mealsByType = {};
  Map<String, int> _mealTypeCalories = {};
  int _totalCalories = 0;
  int _totalProtein = 0;
  int _totalCarbs = 0;
  int _totalFat = 0;
  
  // User goals
  int _calorieGoal = 2000;
  int _proteinGoal = 150;
  int _carbsGoal = 200;
  int _fatGoal = 65;
  
  // Meal types
  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

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
      
      // Get user profile to fetch nutrition goals
      final userProfile = await _firebaseService.getUserProfile(demoUserId);
      if (userProfile != null && userProfile.goals != null) {
        if (userProfile.goals!.containsKey('dailyCalories')) {
          _calorieGoal = userProfile.goals!['dailyCalories'];
        }
        if (userProfile.goals!.containsKey('dailyProtein')) {
          _proteinGoal = userProfile.goals!['dailyProtein'];
        }
        if (userProfile.goals!.containsKey('dailyCarbs')) {
          _carbsGoal = userProfile.goals!['dailyCarbs'];
        }
        if (userProfile.goals!.containsKey('dailyFat')) {
          _fatGoal = userProfile.goals!['dailyFat'];
        }
      }
      
      // Get nutrition entries for selected date
      final foodEntries = await _firebaseService.getNutritionByDate(
        demoUserId, 
        _selectedDate,
      );
      
      // Group by meal type
      _mealsByType = {};
      _mealTypeCalories = {};
      
      for (final entry in foodEntries) {
        final mealType = entry.mealType ?? 'Uncategorized';
        
        if (!_mealsByType.containsKey(mealType)) {
          _mealsByType[mealType] = [];
        }
        
        _mealsByType[mealType]!.add(entry);
        _mealTypeCalories[mealType] = (_mealTypeCalories[mealType] ?? 0) + entry.calories;
      }
      
      // Calculate totals
      _totalCalories = foodEntries.getTotalCalories();
      _totalProtein = foodEntries.getTotalProtein();
      _totalCarbs = foodEntries.getTotalCarbs();
      _totalFat = foodEntries.getTotalFat();
      
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

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _loadNutritionData();
  }

  Future<void> _addFoodEntry(String mealType) async {
    // Navigate to add food screen
    final result = await Navigator.pushNamed(
      context, 
      '/add_food',
      arguments: {
        'date': _selectedDate,
        'mealType': mealType,
      },
    );
    
    // Reload data if food was added
    if (result == true) {
      _loadNutritionData();
    }
  }

  Future<void> _editFoodEntry(NutritionModel foodEntry) async {
    // Navigate to edit food screen
    final result = await Navigator.pushNamed(
      context, 
      '/edit_food',
      arguments: {
        'foodEntry': foodEntry,
      },
    );
    
    // Reload data if food was updated
    if (result == true) {
      _loadNutritionData();
    }
  }

  Future<void> _deleteFoodEntry(NutritionModel foodEntry) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food Entry'),
        content: Text('Are you sure you want to delete "${foodEntry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _firebaseService.deleteFoodEntry(foodEntry.userId, foodEntry.id!);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food entry deleted')),
        );
        
        // Reload data
        _loadNutritionData();
      } catch (e) {
        print('Error deleting food entry: $e');
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting food entry: ${e.toString()}')),
        );
      }
    }
  }

  void _showMealSuggestions(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MealSuggestionSheet(
        mealType: mealType,
        onAddFood: (suggestion) {
          Navigator.pop(context);
          _addFoodFromSuggestion(suggestion, mealType);
        },
      ),
    );
  }
  
  Future<void> _addFoodFromSuggestion(
    MealSuggestion suggestion,
    String mealType,
  ) async {
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      final foodEntry = NutritionModel(
        userId: demoUserId,
        name: suggestion.name,
        category: suggestion.category,
        calories: suggestion.calories,
        protein: suggestion.protein,
        carbs: suggestion.carbs,
        fat: suggestion.fat,
        mealType: mealType,
        date: _selectedDate,
      );
      
      await _firebaseService.addFoodEntry(foodEntry);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food added to meal plan')),
      );
      
      // Reload data
      _loadNutritionData();
    } catch (e) {
      print('Error adding food from suggestion: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding food: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNutritionData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading meal plan...')
          : RefreshIndicator(
              onRefresh: _loadNutritionData,
              child: _buildMealPlanContent(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFoodEntry('Snacks'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMealPlanContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date selector
        Center(
          child: DateSelector(
            selectedDate: _selectedDate,
            onDateSelected: _onDateChanged,
          ),
        ),
        const SizedBox(height: 16),
        
        // Nutrition summary
        _buildNutritionSummary(),
        const SizedBox(height: 16),
        
        // Meal sections
        ..._mealTypes.map(_buildMealSection),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNutritionSummary() {
    final caloriesRemaining = _calorieGoal - _totalCalories;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition Summary',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calories Remaining',
                        style: AppTextStyles.bodySmall,
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
                          Text(
                            ' cal',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: caloriesRemaining >= 0 
                                  ? AppColors.success 
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Goal: $_calorieGoal cal | Consumed: $_totalCalories cal',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      CircularPercentIndicator(
                        percent: _totalCalories / _calorieGoal,
                        label: 'Daily Goal',
                        radius: 40,
                        lineWidth: 6,
                        color: _totalCalories > _calorieGoal 
                            ? AppColors.error 
                            : AppColors.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNutrientProgress(
                  'Protein',
                  _totalProtein,
                  _proteinGoal,
                  'g',
                  Colors.redAccent,
                ),
                _buildNutrientProgress(
                  'Carbs',
                  _totalCarbs,
                  _carbsGoal,
                  'g',
                  Colors.amber,
                ),
                _buildNutrientProgress(
                  'Fat',
                  _totalFat,
                  _fatGoal,
                  'g',
                  Colors.blueAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientProgress(
    String label,
    int value,
    int goal,
    String unit,
    Color color,
  ) {
    final percent = goal > 0 ? value / goal : 0.0;
    
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: percent > 1.0 ? 1.0 : percent,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
              ),
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
                Text(
                  unit,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$value/$goal $unit',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildMealSection(String mealType) {
    final mealEntries = _mealsByType[mealType] ?? [];
    final mealCalories = _mealTypeCalories[mealType] ?? 0;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      style: AppTextStyles.heading3,
                    ),
                    Text(
                      '$mealCalories calories',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      onPressed: () => _showMealSuggestions(mealType),
                      tooltip: 'Meal Suggestions',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addFoodEntry(mealType),
                      tooltip: 'Add Food',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (mealEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: EmptyStateWidget(
                icon: Icons.restaurant,
                message: 'No foods added to $mealType yet',
                actionLabel: 'Add Food',
                onAction: () => _addFoodEntry(mealType),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mealEntries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final foodEntry = mealEntries[index];
                return ListTile(
                  title: Text(foodEntry.name),
                  subtitle: Text(
                    '${foodEntry.calories} cal • ${foodEntry.protein}g protein • ${foodEntry.carbs}g carbs • ${foodEntry.fat}g fat',
                    style: AppTextStyles.caption,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: FoodCategories.getColorForCategory(foodEntry.category).withOpacity(0.2),
                    child: Icon(
                      FoodCategories.getIconForCategory(foodEntry.category),
                      color: FoodCategories.getColorForCategory(foodEntry.category),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editFoodEntry(foodEntry),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteFoodEntry(foodEntry),
                      ),
                    ],
                  ),
                  onTap: () => _editFoodEntry(foodEntry),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text('Add to $mealType'),
              onPressed: () => _addFoodEntry(mealType),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealSuggestionSheet extends StatefulWidget {
  final String mealType;
  final Function(MealSuggestion) onAddFood;
  
  const MealSuggestionSheet({
    super.key,
    required this.mealType,
    required this.onAddFood,
  });

  @override
  _MealSuggestionSheetState createState() => _MealSuggestionSheetState();
}

class _MealSuggestionSheetState extends State<MealSuggestionSheet> {
  String _selectedCategory = 'all';
  
  // Meal suggestion examples for each meal type
  final Map<String, List<MealSuggestion>> _suggestions = {
    'Breakfast': [
      MealSuggestion(
        name: 'Greek Yogurt with Berries',
        calories: 240,
        protein: 15,
        carbs: 28,
        fat: 8,
        category: FoodCategories.dairy,
      ),
      MealSuggestion(
        name: 'Oatmeal with Banana',
        calories: 310,
        protein: 8,
        carbs: 56,
        fat: 5,
        category: FoodCategories.grains,
      ),
      MealSuggestion(
        name: 'Scrambled Eggs with Toast',
        calories: 380,
        protein: 22,
        carbs: 30,
        fat: 18,
        category: FoodCategories.protein,
      ),
    ],
    'Lunch': [
      MealSuggestion(
        name: 'Grilled Chicken Salad',
        calories: 320,
        protein: 35,
        carbs: 15,
        fat: 12,
        category: FoodCategories.protein,
      ),
      MealSuggestion(
        name: 'Turkey and Avocado Sandwich',
        calories: 450,
        protein: 28,
        carbs: 42,
        fat: 18,
        category: FoodCategories.grains,
      ),
      MealSuggestion(
        name: 'Vegetable Soup with Bread',
        calories: 280,
        protein: 10,
        carbs: 45,
        fat: 6,
        category: FoodCategories.vegetables,
      ),
    ],
    'Dinner': [
      MealSuggestion(
        name: 'Salmon with Roasted Vegetables',
        calories: 420,
        protein: 35,
        carbs: 20,
        fat: 22,
        category: FoodCategories.protein,
      ),
      MealSuggestion(
        name: 'Spaghetti with Tomato Sauce',
        calories: 520,
        protein: 18,
        carbs: 85,
        fat: 12,
        category: FoodCategories.grains,
      ),
      MealSuggestion(
        name: 'Stir Fry with Tofu',
        calories: 380,
        protein: 22,
        carbs: 40,
        fat: 14,
        category: FoodCategories.vegetables,
      ),
    ],
    'Snacks': [
      MealSuggestion(
        name: 'Apple with Peanut Butter',
        calories: 210,
        protein: 7,
        carbs: 28,
        fat: 8,
        category: FoodCategories.fruits,
      ),
      MealSuggestion(
        name: 'Protein Shake',
        calories: 180,
        protein: 25,
        carbs: 10,
        fat: 3,
        category: FoodCategories.beverages,
      ),
      MealSuggestion(
        name: 'Trail Mix',
        calories: 280,
        protein: 8,
        carbs: 30,
        fat: 16,
        category: FoodCategories.snacks,
      ),
    ],
  };
  
  List<MealSuggestion> _filteredSuggestions = [];
  
  @override
  void initState() {
    super.initState();
    _filteredSuggestions = _suggestions[widget.mealType] ?? [];
  }
  
  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      
      if (category == 'all') {
        _filteredSuggestions = _suggestions[widget.mealType] ?? [];
      } else {
        _filteredSuggestions = (_suggestions[widget.mealType] ?? [])
            .where((suggestion) => suggestion.category == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.mealType} Suggestions',
                        style: AppTextStyles.heading2,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quick add common food items to your meal plan',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'All', Icons.category),
                    _buildCategoryChip(FoodCategories.protein, 'Protein', Icons.egg),
                    _buildCategoryChip(FoodCategories.grains, 'Grains', Icons.rice_bowl),
                    _buildCategoryChip(FoodCategories.vegetables, 'Vegetables', Icons.eco),
                    _buildCategoryChip(FoodCategories.fruits, 'Fruits', Icons.apple),
                    _buildCategoryChip(FoodCategories.dairy, 'Dairy', Icons.icecream),
                    _buildCategoryChip(FoodCategories.snacks, 'Snacks', Icons.cookie),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredSuggestions.isEmpty
                  ? const Center(
                      child: Text('No suggestions found for this category'),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _filteredSuggestions[index];
                        return ListTile(
                          title: Text(suggestion.name),
                          subtitle: Text(
                            '${suggestion.calories} cal • ${suggestion.protein}g protein • ${suggestion.carbs}g carbs • ${suggestion.fat}g fat',
                            style: AppTextStyles.caption,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: FoodCategories.getColorForCategory(suggestion.category).withOpacity(0.2),
                            child: Icon(
                              FoodCategories.getIconForCategory(suggestion.category),
                              color: FoodCategories.getColorForCategory(suggestion.category),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: AppColors.primary,
                            onPressed: () => widget.onAddFood(suggestion),
                          ),
                          onTap: () => widget.onAddFood(suggestion),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _filterByCategory(category);
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class MealSuggestion {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String category;
  
  MealSuggestion({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
  });
}