import 'package:flutter/material.dart';

class NutritionTabScreen extends StatelessWidget {
  const NutritionTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nutrition summary card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Nutrition",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Calorie progress
                    _buildNutritionProgressBar(
                      context,
                      'Calories',
                      '1,250 / 2,100',
                      0.6,
                      theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    
                    // Macronutrients breakdown
                    Text(
                      'Macronutrients',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Protein
                    _buildNutritionProgressBar(
                      context,
                      'Protein',
                      '68g / 120g',
                      0.57,
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    
                    // Carbs
                    _buildNutritionProgressBar(
                      context,
                      'Carbs',
                      '145g / 240g',
                      0.6,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    
                    // Fat
                    _buildNutritionProgressBar(
                      context,
                      'Fat',
                      '40g / 70g',
                      0.57,
                      Colors.blue,
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Water intake
                    Row(
                      children: [
                        const Icon(Icons.water_drop, color: Colors.blue, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Water Intake',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '1.5 / 2.5 L',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.6,
                      color: Colors.blue,
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 10,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Today's meals heading
            Text(
              "Today's Meals",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Meals list
            _buildMealCard(
              context,
              'Breakfast',
              '7:30 AM',
              'Oatmeal with banana and honey',
              '320 cal',
              Icons.breakfast_dining,
            ),
            _buildMealCard(
              context,
              'Lunch',
              '12:15 PM',
              'Grilled chicken salad with avocado',
              '480 cal',
              Icons.lunch_dining,
            ),
            _buildMealCard(
              context,
              'Snack',
              '3:45 PM',
              'Greek yogurt with berries',
              '180 cal',
              Icons.icecream,
            ),
            _buildMealCard(
              context,
              'Dinner',
              '7:00 PM',
              'Salmon with quinoa and vegetables',
              '550 cal',
              Icons.dinner_dining,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutritionProgressBar(
    BuildContext context,
    String label,
    String value,
    double progress,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          minHeight: 10,
        ),
      ],
    );
  }
  
  Widget _buildMealCard(
    BuildContext context,
    String mealType,
    String time,
    String description,
    String calories,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Meal icon
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            
            // Meal details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mealType,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    calories,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Edit icon
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // TODO: Implement edit meal functionality
              },
              tooltip: 'Edit meal',
            ),
          ],
        ),
      ),
    );
  }
}