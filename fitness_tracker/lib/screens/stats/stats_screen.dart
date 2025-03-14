import 'package:flutter/material.dart';
import '../../utils/app_constants.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 100,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Track your progress and achievements',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Column(
                            children: [
                              Icon(Icons.directions_run, color: Colors.blue),
                              SizedBox(height: 8),
                              Text(
                                'Activities',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.local_fire_department, color: Colors.orange),
                              SizedBox(height: 8),
                              Text(
                                'Calories',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0 kcal',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.nightlight, color: Colors.indigo),
                              SizedBox(height: 8),
                              Text(
                                'Sleep Avg',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0h 0m',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'No achievements yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to achievements
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('View All Achievements'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                // Generate reports
              },
              icon: const Icon(Icons.download),
              label: const Text('Export Data'),
            ),
          ],
        ),
      ),
    );
  }
}