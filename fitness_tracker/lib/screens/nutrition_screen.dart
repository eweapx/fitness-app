import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nutrition_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  bool _isLoading = true;
  List<NutritionModel> _foodEntries = [];
  List<NutritionModel> _dailyFoodEntries = [];
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all';
  
  // Daily nutrition totals
  int _totalCalories = 0;
  int _totalProtein = 0;
  int _totalCarbs = 0;
  int _totalFat = 0;
  
  // Nutrition goals
  final int _calorieGoal = 2000; // Default, would come from user profile
  final int _proteinGoal = 100;
  final int _carbsGoal = 250;
  final int _fatGoal = 65;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNutrition();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadNutrition() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd get the current user ID
      const String demoUserId = 'demo_user';
      
      // Load all food entries
      final allFoodEntries = await _firebaseService.getUserNutrition(demoUserId);
      
      // Load food entries for selected date
      final foodEntriesForDate = await _firebaseService.getNutritionByDate(
        demoUserId, 
        _selectedDate,
      );
      
      // Calculate totals for the day
      int calories = 0;
      int protein = 0;
      int carbs = 0;
      int fat = 0;
      
      for (var entry in foodEntriesForDate) {
        calories += entry.calories;
        protein += entry.protein;
        carbs += entry.carbs;
        fat += entry.fat;
      }
      
      setState(() {
        _foodEntries = allFoodEntries;
        _dailyFoodEntries = foodEntriesForDate;
        _totalCalories = calories;
        _totalProtein = protein;
        _totalCarbs = carbs;
        _totalFat = fat;
        _isLoading = false;
      });
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
    _loadNutrition();
  }

  void _filterFoodEntries(String filter) {
    setState(() => _selectedFilter = filter);
  }

  List<NutritionModel> get _filteredFoodEntries {
    if (_selectedFilter == 'all') {
      return _foodEntries;
    } else {
      return _foodEntries.where((entry) => entry.category == _selectedFilter).toList();
    }
  }

  void _addFoodEntry() {
    // Navigate to add food entry screen
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add food entry feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Diary'),
            Tab(text: 'Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading nutrition data...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildDiaryTab(),
                _buildInsightsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFoodEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadNutrition,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            Center(
              child: DateSelector(
                selectedDate: _selectedDate,
                onDateSelected: _onDateChanged,
              ),
            ),
            const SizedBox(height: 24),
            
            // Calories remaining card
            _buildCaloriesRemainingCard(),
            const SizedBox(height: 24),
            
            // Macronutrients progress
            _buildMacronutrientsSummary(),
            const SizedBox(height: 24),
            
            // Meals list
            _buildMealsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryTab() {
    // Build nutrition diary view with food entries grouped by date
    return RefreshIndicator(
      onRefresh: _loadNutrition,
      child: _foodEntries.isEmpty
          ? EmptyStateWidget(
              icon: Icons.restaurant,
              message: 'No food entries recorded yet.\nTap the + button to add your first food entry.',
              actionLabel: 'Add Food',
              onAction: _addFoodEntry,
            )
          : ListView(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildFilterChips(),
                ),
                
                // Nutrition entries grouped by day
                ..._buildFoodEntriesByDay(),
              ],
            ),
    );
  }

  Widget _buildInsightsTab() {
    // Build nutrition insights view with charts and statistics
    return RefreshIndicator(
      onRefresh: _loadNutrition,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutrition Insights', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            
            // Calorie trend card
            SectionCard(
              title: 'Calorie Trend',
              trailing: Icon(Icons.show_chart, color: AppColors.primary),
              children: [
                const Text('Daily calorie consumption trend will be shown here.'),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 16/9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Calorie trend chart coming soon!'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Macronutrient distribution card
            SectionCard(
              title: 'Macronutrient Distribution',
              trailing: Icon(Icons.pie_chart, color: AppColors.primary),
              children: [
                const Text('Your average macronutrient distribution.'),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Macronutrient pie chart coming soon!'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Most frequent foods card
            SectionCard(
              title: 'Most Frequent Foods',
              trailing: Icon(Icons.restaurant, color: AppColors.primary),
              children: [
                const Text('Your most commonly logged foods.'),
                const SizedBox(height: 16),
                _foodEntries.isEmpty
                    ? const Text('No food entries recorded yet.')
                    : Column(
                        children: List.generate(
                          _foodEntries.length > 5 ? 5 : _foodEntries.length,
                          (index) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: FoodCategories.getColorForCategory(
                                _foodEntries[index].category,
                              ).withOpacity(0.2),
                              child: Icon(
                                FoodCategories.getIconForCategory(
                                  _foodEntries[index].category,
                                ),
                                color: FoodCategories.getColorForCategory(
                                  _foodEntries[index].category,
                                ),
                              ),
                            ),
                            title: Text(_foodEntries[index].name),
                            subtitle: Text('${_foodEntries[index].calories} calories'),
                            trailing: Text(
                              '${_foodEntries[index].protein}g protein',
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesRemainingCard() {
    // Calculate calories remaining
    final caloriesRemaining = _calorieGoal - _totalCalories;
    final isPositiveBalance = caloriesRemaining >= 0;
    
    return SectionCard(
      title: 'Calories',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal: $_calorieGoal cal',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Food: $_totalCalories cal',
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
                  '${isPositiveBalance ? '' : '-'}${caloriesRemaining.abs()}',
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
          value: '$_totalCalories / $_calorieGoal',
          progress: _calorieGoal > 0 ? _totalCalories / _calorieGoal : 0,
          color: _totalCalories > _calorieGoal 
              ? AppColors.error 
              : AppColors.success,
          showPercentage: true,
        ),
      ],
    );
  }

  Widget _buildMacronutrientsSummary() {
    return SectionCard(
      title: 'Macronutrients',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMacroProgressBar(
                'Protein',
                _totalProtein,
                _proteinGoal,
                Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMacroProgressBar(
                'Carbs',
                _totalCarbs,
                _carbsGoal,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMacroProgressBar(
                'Fat',
                _totalFat,
                _fatGoal,
                Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ratio: $_totalProtein g : $_totalCarbs g : $_totalFat g',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroProgressBar(String label, int value, int goal, Color color) {
    return LabeledProgressBar(
      label: label,
      value: '$value g / $goal g',
      progress: goal > 0 ? value / goal : 0,
      color: color,
      showPercentage: false,
    );
  }

  Widget _buildMealsList() {
    final Map<String, List<NutritionModel>> mealGroups = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snacks': [],
      'Other': [],
    };
    
    // Group entries by meal type
    for (var entry in _dailyFoodEntries) {
      final mealType = entry.mealType ?? 'Other';
      if (mealGroups.containsKey(mealType)) {
        mealGroups[mealType]!.add(entry);
      } else {
        mealGroups['Other']!.add(entry);
      }
    }
    
    return _dailyFoodEntries.isEmpty
        ? EmptyStateWidget(
            icon: Icons.restaurant_menu,
            message: 'No food entries recorded for this day.\nTap the + button to add a food entry.',
            actionLabel: 'Add Food',
            onAction: _addFoodEntry,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meals', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              ...mealGroups.entries.map((entry) {
                if (entry.value.isEmpty) return Container();
                
                // Calculate meal totals
                int mealCalories = 0;
                for (var food in entry.value) {
                  mealCalories += food.calories;
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: AppTextStyles.heading4,
                        ),
                        Text(
                          '$mealCalories cal',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map((food) => _buildFoodEntryItem(food)),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ],
          );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: _selectedFilter == 'all',
          onSelected: (selected) => _filterFoodEntries('all'),
        ),
        ...FoodCategories.all.map((category) => FilterChip(
          label: Text(FoodCategories.getDisplayName(category)),
          selected: _selectedFilter == category,
          onSelected: (selected) => _filterFoodEntries(category),
          avatar: Icon(
            FoodCategories.getIconForCategory(category),
            size: 16,
            color: _selectedFilter == category ? Colors.white : AppColors.primary,
          ),
        )),
      ],
    );
  }

  List<Widget> _buildFoodEntriesByDay() {
    if (_filteredFoodEntries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No food entries match the selected filter.',
              style: AppTextStyles.body,
            ),
          ),
        ),
      ];
    }
    
    // Group food entries by day
    Map<String, List<NutritionModel>> entriesByDay = {};
    
    for (var entry in _filteredFoodEntries) {
      final dayKey = DateFormat('EEEE, MMMM d, yyyy').format(entry.date);
      if (!entriesByDay.containsKey(dayKey)) {
        entriesByDay[dayKey] = [];
      }
      entriesByDay[dayKey]!.add(entry);
    }
    
    // Sort days (most recent first)
    final sortedDays = entriesByDay.keys.toList()
      ..sort((a, b) {
        return DateFormat('EEEE, MMMM d, yyyy').parse(b).compareTo(
          DateFormat('EEEE, MMMM d, yyyy').parse(a)
        );
      });
    
    List<Widget> daySections = [];
    
    for (var day in sortedDays) {
      // Calculate day totals
      int dayCalories = 0;
      for (var entry in entriesByDay[day]!) {
        dayCalories += entry.calories;
      }
      
      daySections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: AppTextStyles.heading3,
              ),
              Text(
                '$dayCalories cal',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
      
      final entriesInDay = entriesByDay[day]!;
      
      // Sort entries by time (breakfast, lunch, dinner, snacks)
      entriesInDay.sort((a, b) {
        // First sort by meal type
        final mealTypeOrder = {
          'Breakfast': 0,
          'Lunch': 1,
          'Dinner': 2,
          'Snacks': 3,
          'Other': 4,
        };
        
        final aMealType = a.mealType ?? 'Other';
        final bMealType = b.mealType ?? 'Other';
        
        final aOrder = mealTypeOrder[aMealType] ?? 5;
        final bOrder = mealTypeOrder[bMealType] ?? 5;
        
        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }
        
        // Then sort by time
        return a.date.compareTo(b.date);
      });
      
      for (var entry in entriesInDay) {
        daySections.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildFoodEntryItem(entry),
          ),
        );
      }
      
      daySections.add(const Divider());
    }
    
    return daySections;
  }

  Widget _buildFoodEntryItem(NutritionModel entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showFoodEntryDetails(entry),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: FoodCategories.getColorForCategory(entry.category).withOpacity(0.2),
                child: Icon(
                  FoodCategories.getIconForCategory(entry.category),
                  color: FoodCategories.getColorForCategory(entry.category),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      entry.servingSize != null 
                          ? '${entry.servingSize} ${entry.servingUnit ?? 'g'}'
                          : '${entry.protein}g protein • ${entry.carbs}g carbs • ${entry.fat}g fat',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.calories} cal',
                    style: AppTextStyles.body,
                  ),
                  if (entry.mealType != null)
                    Text(
                      entry.mealType!,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFoodEntryDetails(NutritionModel entry) {
    // In a real app, we would navigate to a detail screen
    // For now, show a bottom sheet with food entry details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and icon
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: FoodCategories.getColorForCategory(entry.category).withOpacity(0.2),
                      child: Icon(
                        FoodCategories.getIconForCategory(entry.category),
                        color: FoodCategories.getColorForCategory(entry.category),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: AppTextStyles.heading2,
                          ),
                          Text(
                            FoodCategories.getDisplayName(entry.category),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date, time and meal
                Row(
                  children: [
                    const Icon(Icons.event, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMd().format(entry.date),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.jm().format(entry.date),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                if (entry.mealType != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.restaurant, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        entry.mealType!,
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                
                // Serving info
                if (entry.servingSize != null) ...[
                  Text('Serving Information', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.servingSize} ${entry.servingUnit ?? 'g'}',
                        style: AppTextStyles.body,
                      ),
                      if (entry.servingCount != null && entry.servingCount! > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${entry.servingCount} servings)',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Nutrition facts
                Text('Nutrition Facts', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                _buildNutritionFactRow('Calories', '${entry.calories}', false),
                const Divider(),
                _buildNutritionFactRow('Protein', '${entry.protein} g', true),
                _buildNutritionFactRow('Carbohydrates', '${entry.carbs} g', true),
                if (entry.sugar != null)
                  _buildNutritionFactRow('Sugar', '${entry.sugar} g', true, indent: true),
                if (entry.fiber != null)
                  _buildNutritionFactRow('Fiber', '${entry.fiber} g', true, indent: true),
                _buildNutritionFactRow('Fat', '${entry.fat} g', true),
                if (entry.sodium != null)
                  _buildNutritionFactRow('Sodium', '${entry.sodium} mg', true),
                const SizedBox(height: 16),
                
                // Macronutrient ratio
                Text('Macronutrient Ratio', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text('${entry.getMacroRatio()} (protein:carbs:fat)'),
                const SizedBox(height: 24),
                
                // Notes
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  Text('Notes', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text(entry.notes!, style: AppTextStyles.body),
                  const SizedBox(height: 24),
                ],
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Edit food entry
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Delete food entry
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionFactRow(String label, String value, bool showDivider, {bool indent = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent ? 16 : 0, top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Food Entries'),
        content: Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedFilter == 'all',
              onSelected: (selected) {
                _filterFoodEntries('all');
                Navigator.pop(context);
              },
            ),
            ...FoodCategories.all.map((category) => FilterChip(
              label: Text(FoodCategories.getDisplayName(category)),
              selected: _selectedFilter == category,
              onSelected: (selected) {
                _filterFoodEntries(category);
                Navigator.pop(context);
              },
              avatar: Icon(
                FoodCategories.getIconForCategory(category),
                size: 16,
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}