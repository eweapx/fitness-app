import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

void main() {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app
  runApp(const FuelApp());
}

class FuelApp extends StatelessWidget {
  const FuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Fitness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _caloriesBurned = 0;
  int _stepsCount = 0;
  int _activitiesLogged = 0;
  
  final List<ActivityRecord> _recentActivities = [];
  final DateFormat _dateFormatter = DateFormat('MMM d, yyyy');
  
  @override
  void initState() {
    super.initState();
    // Add some sample activities
    _recentActivities.add(
      ActivityRecord(
        name: 'Running', 
        calories: 250, 
        duration: 30, 
        iconData: Icons.directions_run,
        color: Colors.blue,
        date: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );
    _recentActivities.add(
      ActivityRecord(
        name: 'Weight Training', 
        calories: 150, 
        duration: 45, 
        iconData: Icons.fitness_center,
        color: Colors.purple,
        date: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    );
  }

  // Simple activity logging for quick actions
  void _logActivity() {
    // Show dialog to log activity
    showDialog(
      context: context,
      builder: (context) => ActivityLogDialog(
        onSave: (ActivityRecord activity) {
          setState(() {
            _recentActivities.insert(0, activity);
            _caloriesBurned += activity.calories;
            _activitiesLogged++;
          });
          _showActivityLoggedMessage();
        },
      ),
    );
  }

  void _showActivityLoggedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity logged successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Fuel Fitness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildDailyStatsSummary(),
            const SizedBox(height: 30),
            _buildRecentActivities(),
            const SizedBox(height: 30),
            _buildFirebaseStatus(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logActivity,
        label: const Text('Log Activity'),
        icon: const Icon(Icons.fitness_center),
      ),
    );
  }

  Widget _buildDailyStatsSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  value: '$_caloriesBurned',
                  label: 'Calories',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.directions_walk,
                  value: '$_stepsCount',
                  label: 'Steps',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.fitness_center,
                  value: '$_activitiesLogged',
                  label: 'Activities',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No activities logged yet. Tap the + button to add one!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: _recentActivities.map((activity) {
                  return Column(
                    children: [
                      _buildActivityItem(
                        activity.name,
                        '${activity.calories} calories · ${activity.duration} min',
                        activity.iconData,
                        activity.color,
                        _dateFormatter.format(activity.date),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String date,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseStatus() {
    final Color statusColor = Colors.orange;
    final String statusText = 'Firebase connection requires configuration';
    final String detailText = 'Add your Firebase API key to enable cloud sync, authentication, and real-time data.';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Firebase Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detailText,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _configureFirebase,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Configure Firebase'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Fuel Fitness'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform: ${kIsWeb ? 'Web' : 'Mobile'}'),
            const SizedBox(height: 8),
            const Text('A comprehensive fitness tracking application'),
            const SizedBox(height: 8),
            Text('Version: 1.0.0 (${DateTime.now().year})'),
            const SizedBox(height: 16),
            const Text(
                'This app helps you track workouts, calories, and healthy habits.'),
            const SizedBox(height: 16),
            const Text(
              'Firebase Status: Not Connected',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  void _configureFirebase() {
    // Show dialog to get Firebase API key
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Firebase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To enable cloud features, you need to provide a Firebase API key.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Firebase API Key',
                border: OutlineInputBorder(),
                hintText: 'Enter your Firebase API key',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _askForFirebaseApiKey();
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  void _askForFirebaseApiKey() {
    // In a real app, this would get and store the Firebase API key
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase API key would be configured here'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// Model class for activity records
class ActivityRecord {
  final String name;
  final int calories;
  final int duration;
  final IconData iconData;
  final Color color;
  final DateTime date;
  
  ActivityRecord({
    required this.name, 
    required this.calories, 
    required this.duration, 
    required this.iconData,
    required this.color,
    required this.date,
  });
}

// Dialog for logging new activities
class ActivityLogDialog extends StatefulWidget {
  final Function(ActivityRecord) onSave;
  
  const ActivityLogDialog({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ActivityLogDialog> createState() => _ActivityLogDialogState();
}

class _ActivityLogDialogState extends State<ActivityLogDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  IconData _selectedIcon = Icons.directions_run;
  Color _selectedColor = Colors.blue;
  
  final List<MapEntry<IconData, String>> _availableIcons = [
    MapEntry(Icons.directions_run, 'Running'),
    MapEntry(Icons.directions_bike, 'Cycling'),
    MapEntry(Icons.fitness_center, 'Weights'),
    MapEntry(Icons.pool, 'Swimming'),
    MapEntry(Icons.sports_tennis, 'Tennis'),
    MapEntry(Icons.sports_basketball, 'Basketball'),
  ];
  
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log New Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Activity Name',
                hintText: 'e.g. Running, Cycling',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories Burned',
                hintText: 'e.g. 200',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'e.g. 30',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Select Icon:'),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _availableIcons.map((iconEntry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconEntry.key;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: _selectedIcon == iconEntry.key
                            ? Colors.grey.shade300
                            : Colors.transparent,
                        child: Icon(iconEntry.key),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Color:'),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _availableColors.map((color) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: color,
                        child: _selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate inputs
            if (_nameController.text.isEmpty ||
                _caloriesController.text.isEmpty ||
                _durationController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all fields'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            // Create activity record
            final activity = ActivityRecord(
              name: _nameController.text,
              calories: int.tryParse(_caloriesController.text) ?? 0,
              duration: int.tryParse(_durationController.text) ?? 0,
              iconData: _selectedIcon,
              color: _selectedColor,
              date: DateTime.now(),
            );
            
            // Pass to parent widget
            widget.onSave(activity);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}