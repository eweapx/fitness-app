import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<Map<String, dynamic>> _activities = [
    {
      'name': 'Morning Run',
      'type': 'Running',
      'duration': 32,
      'calories': 320,
      'date': DateTime.now().subtract(const Duration(hours: 3)),
    },
    {
      'name': 'Cycling',
      'type': 'Cycling',
      'duration': 45,
      'calories': 410,
      'date': DateTime.now().subtract(const Duration(hours: 8)),
    },
    {
      'name': 'Weight Training',
      'type': 'Strength',
      'duration': 45,
      'calories': 250,
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'name': 'Swimming',
      'type': 'Swimming',
      'duration': 30,
      'calories': 280,
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildActivityStats(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Activity History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._activities.map((activity) => _buildActivityCard(activity)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new activity
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActivityStats() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('Activities', '12', Colors.white),
              _buildStatColumn('Calories', '2,543', Colors.white),
              _buildStatColumn('Duration', '4h 35m', Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            '70% of weekly goal',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    // Format date
    final dateStr = '${activity['date'].day}/${activity['date'].month}/${activity['date'].year}';
    final timeStr = '${activity['date'].hour}:${activity['date'].minute.toString().padLeft(2, '0')}';
    
    IconData activityIcon;
    
    switch (activity['type']) {
      case 'Running':
        activityIcon = Icons.directions_run;
        break;
      case 'Cycling':
        activityIcon = Icons.directions_bike;
        break;
      case 'Swimming':
        activityIcon = Icons.pool;
        break;
      case 'Strength':
        activityIcon = Icons.fitness_center;
        break;
      default:
        activityIcon = Icons.sports;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(activityIcon, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${activity['type']} • ${activity['duration']} min • ${activity['calories']} cal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '$dateStr at $timeStr',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options
              },
            ),
          ],
        ),
      ),
    );
  }
}