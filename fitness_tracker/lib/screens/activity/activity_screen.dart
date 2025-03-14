import 'package:flutter/material.dart';
import '../../utils/app_constants.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_run,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Activity Tracking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Track your workouts, steps, and calories',
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
                        leading: const Icon(Icons.directions_walk),
                        title: const Text('Daily Steps'),
                        subtitle: const Text('0 / 10,000'),
                        trailing: const Text('0%'),
                      ),
                      const LinearProgressIndicator(
                        value: 0,
                        backgroundColor: Colors.grey,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.local_fire_department),
                        title: const Text('Calories Burned'),
                        subtitle: const Text('0 kcal'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            // Show dialog to add activity manually
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Show activity form
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Activity'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // TODO: Navigate to activity history
              },
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}