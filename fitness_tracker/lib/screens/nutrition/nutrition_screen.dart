import 'package:flutter/material.dart';
import '../../utils/app_constants.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Nutrition Tracking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Track your meals and nutrition intake',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.local_fire_department),
                        title: const Text('Daily Calories'),
                        subtitle: const Text('0 / 2000 kcal'),
                        trailing: const Text('0%'),
                      ),
                      const LinearProgressIndicator(
                        value: 0,
                        backgroundColor: Colors.grey,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Column(
                            children: [
                              Text(
                                'Protein',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0g',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Carbs',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0g',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Fat',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0g',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Show add meal form
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // TODO: Navigate to meal history
              },
              child: const Text('View Meal History'),
            ),
          ],
        ),
      ),
    );
  }
}