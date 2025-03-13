import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'dart:io' show Platform;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isMetric = true;
  bool _notificationsEnabled = true;
  Map<String, bool> _reminderTypes = {
    'Water Intake': true,
    'Workouts': true,
    'Meal Tracking': true,
    'Sleep Tracking': true,
    'Step Goals': true,
    'Weight Tracking': true,
  };
  
  // Goal settings
  int _calorieGoal = 2000;
  int _stepGoal = 10000;
  int _waterGoal = 2000; // ml
  int _sleepGoal = 8; // hours
  
  // User profile
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;
  bool _isConnected = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Load preferences from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
        _isMetric = prefs.getBool('metric_units') ?? true;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
      
      // Load reminder settings
      for (final key in _reminderTypes.keys) {
        final prefKey = 'reminder_${key.toLowerCase().replaceAll(' ', '_')}';
        final value = prefs.getBool(prefKey);
        if (value != null) {
          setState(() => _reminderTypes[key] = value);
        }
      }
      
      // Load goal settings
      setState(() {
        _calorieGoal = prefs.getInt('goal_calories') ?? 2000;
        _stepGoal = prefs.getInt('goal_steps') ?? 10000;
        _waterGoal = prefs.getInt('goal_water') ?? 2000;
        _sleepGoal = prefs.getInt('goal_sleep') ?? 8;
      });
      
      // In a real app, we'd use the current user's ID
      try {
        // Get current Firebase user
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          setState(() {
            _userName = firebaseUser.displayName;
            _userEmail = firebaseUser.email;
            _userPhotoUrl = firebaseUser.photoURL;
          });
          
          // Get user profile
          final userProfile = await _firebaseService.getUserProfile(firebaseUser.uid);
          if (userProfile != null && userProfile.goals != null) {
            setState(() {
              if (userProfile.goals!.containsKey('dailyCalories')) {
                _calorieGoal = userProfile.goals!['dailyCalories'];
              }
              if (userProfile.goals!.containsKey('dailySteps')) {
                _stepGoal = userProfile.goals!['dailySteps'];
              }
              if (userProfile.goals!.containsKey('dailyWater')) {
                _waterGoal = userProfile.goals!['dailyWater'];
              }
              if (userProfile.goals!.containsKey('dailySleepHours')) {
                _sleepGoal = userProfile.goals!['dailySleepHours'];
              }
            });
          }
        }
      } catch (e) {
        print('Error loading Firebase user data: $e');
        // Continue with SharedPreferences data
      }
      
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Save preferences to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
      await prefs.setBool('metric_units', _isMetric);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      
      // Save reminder settings
      for (final entry in _reminderTypes.entries) {
        final prefKey = 'reminder_${entry.key.toLowerCase().replaceAll(' ', '_')}';
        await prefs.setBool(prefKey, entry.value);
      }
      
      // Save goal settings
      await prefs.setInt('goal_calories', _calorieGoal);
      await prefs.setInt('goal_steps', _stepGoal);
      await prefs.setInt('goal_water', _waterGoal);
      await prefs.setInt('goal_sleep', _sleepGoal);
      
      // Save to Firebase if authenticated
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          await _firebaseService.updateUserGoals(firebaseUser.uid, {
            'dailyCalories': _calorieGoal,
            'dailySteps': _stepGoal,
            'dailyWater': _waterGoal,
            'dailySleepHours': _sleepGoal,
          });
        }
      } catch (e) {
        print('Error saving to Firebase: $e');
        // Continue with local storage only
      }
      
      // Update notification settings
      if (_notificationsEnabled) {
        await _notificationService.requestPermissions();
        
        // Schedule notifications for each enabled reminder type
        for (final entry in _reminderTypes.entries) {
          if (entry.value) {
            await _notificationService.scheduleReminderNotification(
              entry.key,
              'Time to track your ${entry.key.toLowerCase()}!',
            );
          } else {
            await _notificationService.cancelReminderNotification(entry.key);
          }
        }
      } else {
        // Cancel all notifications
        await _notificationService.cancelAllNotifications();
      }
      
      // Apply theme change
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error signing out: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _showCalorieGoalDialog() async {
    final controller = TextEditingController(text: _calorieGoal.toString());
    
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Calorie Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Calorie Goal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                Navigator.pop(context, goal);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid goal')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newGoal != null) {
      setState(() => _calorieGoal = newGoal);
      await _saveSettings();
    }
  }
  
  Future<void> _showStepGoalDialog() async {
    final controller = TextEditingController(text: _stepGoal.toString());
    
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Step Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Step Goal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                Navigator.pop(context, goal);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid goal')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newGoal != null) {
      setState(() => _stepGoal = newGoal);
      await _saveSettings();
    }
  }
  
  Future<void> _showWaterGoalDialog() async {
    final controller = TextEditingController(text: _waterGoal.toString());
    
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Water Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Water Goal (ml)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                Navigator.pop(context, goal);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid goal')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newGoal != null) {
      setState(() => _waterGoal = newGoal);
      await _saveSettings();
    }
  }
  
  Future<void> _showSleepGoalDialog() async {
    final controller = TextEditingController(text: _sleepGoal.toString());
    
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Sleep Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Sleep Goal (hours)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0 && goal <= 24) {
                Navigator.pop(context, goal);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid goal (1-24 hours)')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newGoal != null) {
      setState(() => _sleepGoal = newGoal);
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading settings...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserProfileSection(),
                  const SizedBox(height: 16),
                  _buildThemeSection(),
                  const SizedBox(height: 16),
                  _buildUnitsSection(),
                  const SizedBox(height: 16),
                  _buildGoalsSection(),
                  const SizedBox(height: 16),
                  _buildNotificationsSection(),
                  const SizedBox(height: 16),
                  _buildDataSection(),
                  const SizedBox(height: 16),
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                  _buildSignOutButton(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildUserProfileSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Profile',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // User profile image
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _userPhotoUrl != null
                      ? NetworkImage(_userPhotoUrl!)
                      : null,
                  child: _userPhotoUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName ?? 'Demo User',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail ?? 'demo@example.com',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _isConnected ? Icons.cloud_done : Icons.cloud_off,
                            color: _isConnected ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isConnected ? 'Connected' : 'Offline',
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Edit Profile',
              icon: Icons.edit,
              onPressed: () {
                // Navigate to profile edit page
                Navigator.pushNamed(context, '/profile');
              },
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme for the app'),
              value: _isDarkMode,
              onChanged: (value) => setState(() => _isDarkMode = value),
              secondary: const Icon(Icons.dark_mode),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnitsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Units',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Measurement System'),
              subtitle: Text(_isMetric ? 'Metric (kg, cm)' : 'Imperial (lb, in)'),
              trailing: Switch(
                value: _isMetric,
                onChanged: (value) => setState(() => _isMetric = value),
              ),
              leading: const Icon(Icons.straighten),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoalsSection() {
    final weightUnit = _isMetric ? 'kg' : 'lb';
    final distanceUnit = _isMetric ? 'km' : 'mi';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goals',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _buildGoalTile(
              icon: Icons.local_fire_department,
              title: 'Daily Calorie Goal',
              value: '$_calorieGoal calories',
              onTap: _showCalorieGoalDialog,
            ),
            _buildGoalTile(
              icon: Icons.directions_walk,
              title: 'Daily Step Goal',
              value: '$_stepGoal steps',
              onTap: _showStepGoalDialog,
            ),
            _buildGoalTile(
              icon: Icons.water_drop,
              title: 'Daily Water Goal',
              value: '$_waterGoal ml',
              onTap: _showWaterGoalDialog,
            ),
            _buildGoalTile(
              icon: Icons.bedtime,
              title: 'Daily Sleep Goal',
              value: '$_sleepGoal hours',
              onTap: _showSleepGoalDialog,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoalTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit),
      onTap: onTap,
    );
  }
  
  Widget _buildNotificationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive reminders and updates'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                if (value) {
                  _notificationService.requestPermissions();
                }
              },
              secondary: const Icon(Icons.notifications),
            ),
            if (_notificationsEnabled) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Reminder Types',
                  style: AppTextStyles.heading4,
                ),
              ),
              ..._reminderTypes.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _reminderTypes[entry.key] = value);
                    }
                  },
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Management',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Download your health data as CSV'),
              leading: const Icon(Icons.download),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data export feature coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text('Sync Data'),
              subtitle: const Text('Sync data across devices'),
              leading: const Icon(Icons.sync),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synchronizing data...')),
                );
              },
            ),
            ListTile(
              title: const Text('Clear Local Data'),
              subtitle: const Text('Reset all app data on this device'),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Data'),
                    content: const Text(
                      'Are you sure you want to clear all local data? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Clear SharedPreferences
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Local data cleared')),
                            );
                            _loadSettings();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Clear Data'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
              leading: const Icon(Icons.info),
            ),
            ListTile(
              title: const Text('Terms of Service'),
              leading: const Icon(Icons.description),
              onTap: () {
                // Navigate to terms of service page
              },
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              leading: const Icon(Icons.privacy_tip),
              onTap: () {
                // Navigate to privacy policy page
              },
            ),
            ListTile(
              title: const Text('Help & Support'),
              leading: const Icon(Icons.help),
              onTap: () {
                // Navigate to help page
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }
}