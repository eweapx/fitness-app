import 'package:flutter/material.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nutrition'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTodayTab(),
            _buildHistoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Add food log
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildCalorieCard(),
        const SizedBox(height: 16),
        _buildMacronutrientsCard(),
        const SizedBox(height: 16),
        _buildMealsCard(),
      ],
    );
  }

  Widget _buildCalorieCard() {
    const consumedCalories = 1540;
    const goalCalories = 2200;
    const remainingCalories = goalCalories - consumedCalories;
    const percentComplete = consumedCalories / goalCalories;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Calories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCalorieColumn('Consumed', '$consumedCalories', Colors.green),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: percentComplete,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          'Remaining',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '$remainingCalories',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const Text(
                          'cal',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildCalorieColumn('Goal', '$goalCalories', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const Text(
          'cal',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMacronutrientsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Macronutrients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Carbs'),
                          const Text('180g / 275g'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Protein'),
                          const Text('95g / 165g'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        value: 0.57,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fat'),
                          const Text('45g / 75g'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Meals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMealItem('Breakfast', '520 cal', Icons.free_breakfast),
            const Divider(),
            _buildMealItem('Lunch', '680 cal', Icons.lunch_dining),
            const Divider(),
            _buildMealItem('Dinner', '340 cal', Icons.dinner_dining),
            const Divider(),
            _buildMealItem('Snacks', '220 cal', Icons.local_cafe),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(String mealType, String calories, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              mealType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            calories,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    // Sample days
    final days = [
      {'date': 'Today', 'calories': 1540, 'goal': 2200},
      {'date': 'Yesterday', 'calories': 1980, 'goal': 2200},
      {'date': 'Mar 11, 2025', 'calories': 2150, 'goal': 2200},
      {'date': 'Mar 10, 2025', 'calories': 1890, 'goal': 2200},
      {'date': 'Mar 9, 2025', 'calories': 2050, 'goal': 2200},
      {'date': 'Mar 8, 2025', 'calories': 1760, 'goal': 2200},
      {'date': 'Mar 7, 2025', 'calories': 2300, 'goal': 2200},
    ];

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final percentComplete = (day['calories'] as int) / (day['goal'] as int);
        final isOverGoal = (day['calories'] as int) > (day['goal'] as int);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day['date'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${day['calories']} / ${day['goal']} cal',
                        style: TextStyle(
                          color: isOverGoal ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: LinearProgressIndicator(
                    value: percentComplete > 1 ? 1 : percentComplete,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverGoal ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}