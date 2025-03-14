import 'package:flutter/material.dart';
import '../../utils/app_constants.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.nightlight,
              size: 100,
              color: Colors.indigo,
            ),
            const SizedBox(height: 20),
            const Text(
              'Sleep Tracking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Monitor your sleep patterns and quality',
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
                      const ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text('Last Night'),
                        subtitle: Text('No sleep data'),
                        trailing: Text('0 hr'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Column(
                            children: [
                              Text(
                                'Deep Sleep',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0h 0m',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Light Sleep',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '0h 0m',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'REM',
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
                      const SizedBox(height: 20),
                      const ListTile(
                        leading: Icon(Icons.trending_up),
                        title: Text('Weekly Average'),
                        subtitle: Text('0 hours / night'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Show add sleep form
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Sleep'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // TODO: Navigate to sleep history
              },
              child: const Text('View Sleep History'),
            ),
          ],
        ),
      ),
    );
  }
}