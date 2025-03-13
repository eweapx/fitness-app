import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _meals = [];
  late TabController _tabController;
  
  // Nutrition summary
  int _totalCalories = 0;
  int _totalProtein = 0;
  int _totalCarbs = 0;
  int _totalFat = 0;
  int _totalWater = 0;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  MealType _selectedMealType = MealType.lunch;
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Water tracking
  final _waterController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeals();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _mealNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _descriptionController.dispose();
    _waterController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Get meals for the selected date
      final meals = await _firebaseService.getMealEntriesForDate(
        userId,
        _selectedDate,
      );
      
      // Calculate nutritional totals
      int totalCalories = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;
      int totalWater = 0;
      
      for (final meal in meals) {
        totalCalories += meal['calories'] as int? ?? 0;
        totalProtein += meal['protein'] as int? ?? 0;
        totalCarbs += meal['carbs'] as int? ?? 0;
        totalFat += meal['fat'] as int? ?? 0;
      }
      
      // Get water intake
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final waterIntake = meals.firstWhere(
        (meal) => meal['type'] == 'water',
        orElse: () => {'amount': 0},
      );
      
      totalWater = waterIntake['amount'] as int? ?? 0;
      
      setState(() {
        _meals = meals.where((meal) => meal['type'] != 'water').toList();
        _totalCalories = totalCalories;
        _totalProtein = totalProtein;
        _totalCarbs = totalCarbs;
        _totalFat = totalFat;
        _totalWater = totalWater;
        _waterController.text = totalWater.toString();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meals: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meals: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadMeals();
    }
  }
  
  Future<void> _addMeal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Parse form values
      final name = _mealNameController.text.trim();
      final type = _selectedMealType.toString().split('.').last;
      final calories = int.parse(_caloriesController.text);
      final protein = int.parse(_proteinController.text);
      final carbs = int.parse(_carbsController.text);
      final fat = int.parse(_fatController.text);
      final description = _descriptionController.text;
      
      // Format date string for database queries
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Create meal data
      final mealData = {
        'userId': userId,
        'name': name,
        'type': type,
        'date': _selectedDate,
        'dateString': dateString,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'description': description,
        'createdAt': DateTime.now(),
      };
      
      // Save to Firebase
      await _firebaseService.addMealEntry(mealData);
      
      // Reset form
      _mealNameController.clear();
      _caloriesController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatController.clear();
      _descriptionController.clear();
      
      // Reload meals
      await _loadMeals();
      
      // Navigate back to the meal log tab
      _tabController.animateTo(0);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding meal: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding meal: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteMeal(String mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
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
        await _firebaseService.deleteMealEntry(mealId);
        
        // Reload meals
        await _loadMeals();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting meal: $e');
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting meal: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  Future<void> _updateWaterIntake() async {
    if (_waterController.text.isEmpty) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Parse water amount
      final waterAmount = int.parse(_waterController.text);
      
      // Format date string for database queries
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Check if water entry exists for today
      final meals = await _firebaseService.getMealEntriesForDate(
        userId,
        _selectedDate,
      );
      
      final waterEntry = meals.firstWhere(
        (meal) => meal['type'] == 'water',
        orElse: () => {'id': null},
      );
      
      if (waterEntry['id'] != null) {
        // Update existing water entry
        final waterData = {
          'amount': waterAmount,
          'updatedAt': DateTime.now(),
        };
        
        await _firebaseService.updateMealEntry(waterEntry['id'], waterData);
      } else {
        // Create new water entry
        final waterData = {
          'userId': userId,
          'type': 'water',
          'date': _selectedDate,
          'dateString': dateString,
          'amount': waterAmount,
          'createdAt': DateTime.now(),
        };
        
        await _firebaseService.addMealEntry(waterData);
      }
      
      // Reload meals
      await _loadMeals();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Water intake updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating water intake: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating water intake: ${e.toString()}')),
        );
      }
    }
  }
  
  Color _getMealTypeColor(String type) {
    switch (type) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  String _getMealTypeIcon(String type) {
    switch (type) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍲';
      case 'dinner':
        return '🍽️';
      case 'snack':
        return '🍎';
      default:
        return '🍴';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isMetric = settingsProvider.useMetricSystem;
    final waterGoal = settingsProvider.waterGoal;
    final waterUnit = isMetric ? AppConstants.unitMl : AppConstants.unitOz;
    
    // Convert water from ml to oz if using imperial
    int displayWater = _totalWater;
    int displayWaterGoal = waterGoal;
    
    if (!isMetric) {
      displayWater = AppHelpers.mlToOz(_totalWater.toDouble()).round();
      displayWaterGoal = AppHelpers.mlToOz(waterGoal.toDouble()).round();
    }
    
    // Calculate calorie goal
    final userProvider = Provider.of<UserProvider>(context);
    int calorieGoal = settingsProvider.caloriesGoal;
    
    final dailyNeeds = userProvider.getUserDailyCalorieNeeds();
    if (dailyNeeds != null) {
      calorieGoal = dailyNeeds;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meal Log'),
            Tab(text: 'Add Meal'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading nutrition data...')
          : TabBarView(
              controller: _tabController,
              children: [
                // Meal Log Tab
                _buildMealLogTab(isMetric, waterUnit, displayWater, displayWaterGoal, calorieGoal),
                
                // Add Meal Tab
                _buildAddMealTab(),
              ],
            ),
    );
  }
  
  Widget _buildMealLogTab(bool isMetric, String waterUnit, int displayWater, int displayWaterGoal, int calorieGoal) {
    // Calculate macronutrient percentages
    final totalMacros = _totalProtein + _totalCarbs + _totalFat;
    final proteinPercentage = totalMacros > 0 ? _totalProtein / totalMacros * 100 : 0;
    final carbsPercentage = totalMacros > 0 ? _totalCarbs / totalMacros * 100 : 0;
    final fatPercentage = totalMacros > 0 ? _totalFat / totalMacros * 100 : 0;
    
    // Calculate remaining calories
    final remainingCalories = calorieGoal - _totalCalories;
    
    return RefreshIndicator(
      onRefresh: _loadMeals,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            DateRangeSelector(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                _loadMeals();
              },
            ),
            const SizedBox(height: 24),
            
            // Calorie summary
            const Text(
              'Calorie Summary',
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
                            Text(
                              '$_totalCalories kcal',
                              style: AppTextStyles.heading2.copyWith(
                                color: remainingCalories >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              'consumed',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$calorieGoal kcal',
                              style: AppTextStyles.heading4,
                            ),
                            Text(
                              'daily goal',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _totalCalories / calorieGoal,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        remainingCalories >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remainingCalories >= 0
                          ? '$remainingCalories kcal remaining'
                          : '${-remainingCalories} kcal over budget',
                      style: TextStyle(
                        color: remainingCalories >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Water tracking
            const Text(
              'Water Intake',
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
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: AppColors.water,
                              size: 36,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$displayWater $waterUnit',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.water,
                                  ),
                                ),
                                Text(
                                  'of $displayWaterGoal $waterUnit goal',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(displayWater / displayWaterGoal * 100).round()}%',
                              style: AppTextStyles.heading4,
                            ),
                            Text(
                              'of daily goal',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: displayWater / displayWaterGoal,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.water),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _waterController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Water Intake',
                              border: const OutlineInputBorder(),
                              suffixText: waterUnit,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        AppButton(
                          label: 'Update',
                          icon: Icons.save,
                          onPressed: _updateWaterIntake,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMetric
                          ? '1 glass ≈ 250 ml'
                          : '1 glass ≈ 8 oz',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Macronutrient breakdown
            const Text(
              'Macronutrient Breakdown',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _totalCalories > 0
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMacronutrientInfo(
                                'Protein',
                                _totalProtein,
                                AppColors.protein,
                                proteinPercentage.round(),
                              ),
                              _buildMacronutrientInfo(
                                'Carbs',
                                _totalCarbs,
                                AppColors.carbs,
                                carbsPercentage.round(),
                              ),
                              _buildMacronutrientInfo(
                                'Fat',
                                _totalFat,
                                AppColors.fat,
                                fatPercentage.round(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 20,
                            child: Stack(
                              children: [
                                // Protein bar
                                Row(
                                  children: [
                                    Expanded(
                                      flex: proteinPercentage.round(),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: AppColors.protein,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            bottomLeft: Radius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: carbsPercentage.round() + fatPercentage.round(),
                                      child: Container(),
                                    ),
                                  ],
                                ),
                                // Carbs bar
                                Row(
                                  children: [
                                    Expanded(
                                      flex: proteinPercentage.round(),
                                      child: Container(),
                                    ),
                                    Expanded(
                                      flex: carbsPercentage.round(),
                                      child: Container(color: AppColors.carbs),
                                    ),
                                    Expanded(
                                      flex: fatPercentage.round(),
                                      child: Container(),
                                    ),
                                  ],
                                ),
                                // Fat bar
                                Row(
                                  children: [
                                    Expanded(
                                      flex: proteinPercentage.round() + carbsPercentage.round(),
                                      child: Container(),
                                    ),
                                    Expanded(
                                      flex: fatPercentage.round(),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: AppColors.fat,
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(10),
                                            bottomRight: Radius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No meal data available for macronutrient breakdown',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            
            // Meal list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Meals',
                  style: AppTextStyles.heading3,
                ),
                Text(
                  '${_meals.length} ${_meals.length == 1 ? 'meal' : 'meals'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_meals.isEmpty) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No meals logged for this day',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Add Meal',
                      icon: Icons.add,
                      onPressed: () => _tabController.animateTo(1),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _meals.length,
                itemBuilder: (context, index) {
                  final meal = _meals[index];
                  final mealId = meal['id'] as String;
                  final name = meal['name'] as String;
                  final type = meal['type'] as String;
                  final calories = meal['calories'] as int;
                  final protein = meal['protein'] as int;
                  final carbs = meal['carbs'] as int;
                  final fat = meal['fat'] as int;
                  final description = meal['description'] as String?;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getMealTypeColor(type).withOpacity(0.2),
                                child: Text(
                                  _getMealTypeIcon(type),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.heading4,
                                    ),
                                    Text(
                                      type.substring(0, 1).toUpperCase() + type.substring(1),
                                      style: TextStyle(
                                        color: _getMealTypeColor(type),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$calories kcal',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'P: $protein  C: $carbs  F: $fat',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                tooltip: 'Delete Meal',
                                onPressed: () => _deleteMeal(mealId),
                              ),
                            ],
                          ),
                          if (description != null && description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              description,
                              style: AppTextStyles.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMacronutrientInfo(String name, int grams, Color color, int percentage) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '$grams g',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
  
  Widget _buildAddMealTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal date
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMMd().format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Meal name
            TextFormField(
              controller: _mealNameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                hintText: 'e.g. Grilled Chicken Salad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a meal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Meal type
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: MealType.values.map((type) {
                String label = type.toString().split('.').last;
                label = label.substring(0, 1).toUpperCase() + label.substring(1);
                
                String emoji;
                Color color;
                switch (type) {
                  case MealType.breakfast:
                    emoji = '🍳';
                    color = Colors.orange;
                    break;
                  case MealType.lunch:
                    emoji = '🍲';
                    color = Colors.green;
                    break;
                  case MealType.dinner:
                    emoji = '🍽️';
                    color = Colors.indigo;
                    break;
                  case MealType.snack:
                    emoji = '🍎';
                    color = Colors.purple;
                    break;
                }
                
                return DropdownMenuItem<MealType>(
                  value: type,
                  child: Row(
                    children: [
                      Text(emoji),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMealType = value);
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Nutritional info header
            const Text(
              'Nutritional Information',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            
            // Calories
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories',
                hintText: 'e.g. 350',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
                suffixText: 'kcal',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the calories';
                }
                try {
                  final calories = int.parse(value);
                  if (calories < 0) {
                    return 'Calories cannot be negative';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Protein, Carbs, and Fat in a row
            Row(
              children: [
                // Protein
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      hintText: 'e.g. 25',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      try {
                        final protein = int.parse(value);
                        if (protein < 0) {
                          return 'Invalid';
                        }
                      } catch (e) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Carbs
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      hintText: 'e.g. 40',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      try {
                        final carbs = int.parse(value);
                        if (carbs < 0) {
                          return 'Invalid';
                        }
                      } catch (e) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Fat
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fat',
                      hintText: 'e.g. 15',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      try {
                        final fat = int.parse(value);
                        if (fat < 0) {
                          return 'Invalid';
                        }
                      } catch (e) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add any notes about this meal',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save Meal',
                icon: Icons.check,
                onPressed: _addMeal,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}