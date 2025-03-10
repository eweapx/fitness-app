import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  FirebaseOptions? firebaseOptions;
  bool firebaseInitialized = false;

  try {
    // Use Firebase API key from environment
    firebaseOptions = const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
      appId: '1:123456789012:android:1234567890123456',
      messagingSenderId: '123456789012',
      projectId: 'fuel-fitness-app',
    );
    
    if (firebaseOptions.apiKey.isNotEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
      firebaseInitialized = true;
      print('Firebase initialized successfully');
    } else {
      print('Firebase API key not provided, running in offline mode');
    }
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  // Run the app with Firebase initialization status
  runApp(FuelApp(firebaseInitialized: firebaseInitialized));
}

class FuelApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const FuelApp({
    super.key, 
    required this.firebaseInitialized
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Fitness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(firebaseInitialized: firebaseInitialized),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool firebaseInitialized;
  
  const HomePage({
    super.key, 
    required this.firebaseInitialized
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _caloriesBurned = 0;
  int _stepsCount = 0;
  int _activitiesLogged = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Simulate loading data
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _caloriesBurned = 350;
        _stepsCount = 5280;
        _activitiesLogged = 2;
      });
    });
  }

  void _logActivity() {
    setState(() {
      _caloriesBurned += 150;
      _activitiesLogged++;
    });
    _showActivityLoggedMessage();
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
            _buildActivityItem(
              'Running',
              '250 calories · 30 min',
              Icons.directions_run,
              Colors.blue,
            ),
            const Divider(),
            _buildActivityItem(
              'Weight Training',
              '100 calories · 20 min',
              Icons.fitness_center,
              Colors.purple,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseStatus() {
    final Color statusColor = widget.firebaseInitialized ? Colors.green : Colors.orange;
    final String statusText = widget.firebaseInitialized 
        ? 'Firebase connected successfully'
        : 'Firebase connection requires configuration';
    final String detailText = widget.firebaseInitialized
        ? 'Your fitness data will be synced to the cloud.'
        : 'Add your Firebase API key to enable cloud sync, authentication, and real-time data.';
    
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
                Icon(widget.firebaseInitialized ? Icons.cloud_done : Icons.cloud_off, color: statusColor),
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
            if (!widget.firebaseInitialized)
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
            Text(
              'Firebase Status: ${widget.firebaseInitialized ? 'Connected' : 'Not Connected'}',
              style: TextStyle(
                color: widget.firebaseInitialized ? Colors.green : Colors.orange,
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
    // For now, show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase API key would be configured here'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
