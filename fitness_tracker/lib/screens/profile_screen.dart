import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  bool _isLoading = true;
  UserModel? _user;
  
  // Demo user data (in a real app, this would come from Firebase)
  final Map<String, dynamic> _demoUserData = {
    'id': 'demo_user',
    'email': 'user@example.com',
    'name': 'John Doe',
    'photoUrl': null,
    'age': 30,
    'weight': 75.0, // kg
    'height': 175.0, // cm
    'gender': 'male',
    'birthDate': DateTime(1993, 5, 15),
    'goals': {
      'dailyCalories': 2200,
      'dailySteps': 10000,
      'dailyWater': 2500, // ml
      'weeklyWorkouts': 4,
      'targetWeight': 70.0, // kg
    },
    'settings': {
      'useDarkMode': false,
      'useMetricSystem': true,
      'enableNotifications': true,
      'notificationTimes': [
        '08:00', // morning
        '12:00', // lunch
        '18:00', // dinner
      ],
    },
    'createdAt': DateTime.now().subtract(const Duration(days: 90)),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd get the current user profile from Firebase
      // For now, we'll use the demo user data
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network request
      
      // Create a UserModel from the demo data
      final user = UserModel(
        id: _demoUserData['id'],
        email: _demoUserData['email'],
        name: _demoUserData['name'],
        photoUrl: _demoUserData['photoUrl'],
        age: _demoUserData['age'],
        weight: _demoUserData['weight'],
        height: _demoUserData['height'],
        gender: _demoUserData['gender'],
        birthDate: _demoUserData['birthDate'],
        goals: _demoUserData['goals'],
        settings: _demoUserData['settings'],
        createdAt: _demoUserData['createdAt'],
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    }
  }

  void _signOut() {
    // In a real app, we would sign out the user
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign out feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading profile...')
          : _user == null
              ? const Center(child: Text('User profile not found'))
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      // Profile header
                      _buildProfileHeader(),
                      
                      // Tab bar
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Profile'),
                          Tab(text: 'Goals'),
                          Tab(text: 'Settings'),
                        ],
                      ),
                      
                      // Tab views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProfileTab(),
                            _buildGoalsTab(),
                            _buildSettingsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Column(
        children: [
          // Profile avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: _user!.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      _user!.photoUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    _user!.name?.isNotEmpty == true
                        ? _user!.name!.substring(0, 1).toUpperCase()
                        : _user!.email.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          
          // User name
          Text(
            _user!.name ?? 'No name',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 4),
          
          // User email
          Text(
            _user!.email,
            style: AppTextStyles.bodySmall,
          ),
          
          // Edit profile button
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to edit profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile feature coming soon!')),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal information
          SectionCard(
            title: 'Personal Information',
            children: [
              _buildInfoRow('Email', _user!.email),
              _buildInfoRow(
                'Age', 
                _user!.age != null ? '${_user!.age} years' : 'Not set',
              ),
              _buildInfoRow(
                'Gender', 
                _user!.gender != null ? _capitalizeFirst(_user!.gender!) : 'Not set',
              ),
              _buildInfoRow(
                'Birth Date',
                _user!.birthDate != null 
                    ? DateFormat.yMMMMd().format(_user!.birthDate!) 
                    : 'Not set',
              ),
              _buildInfoRow(
                'Member Since',
                _user!.createdAt != null 
                    ? DateFormat.yMMMMd().format(_user!.createdAt!) 
                    : 'Unknown',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Physical metrics
          SectionCard(
            title: 'Physical Metrics',
            children: [
              _buildInfoRow(
                'Height', 
                _user!.height != null ? '${_user!.height!.toStringAsFixed(1)} cm' : 'Not set',
              ),
              _buildInfoRow(
                'Weight', 
                _user!.weight != null ? '${_user!.weight!.toStringAsFixed(1)} kg' : 'Not set',
              ),
              _buildInfoRow(
                'BMI',
                _user!.bmi != null 
                    ? '${_user!.bmi!.toStringAsFixed(1)} (${_user!.bmiCategory})' 
                    : 'Not available',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Actions
          SectionCard(
            title: 'Account Actions',
            children: [
              ListTile(
                leading: const Icon(Icons.security, color: AppColors.primary),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change password feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: AppColors.primary),
                title: const Text('Export Data'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export data feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account deletion feature coming soon!')),
                            );
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    // Get user goals
    final goals = _user!.goals ?? {};
    final dailyCalories = goals['dailyCalories'] ?? 2000;
    final dailySteps = goals['dailySteps'] ?? 10000;
    final dailyWater = goals['dailyWater'] ?? 2000;
    final weeklyWorkouts = goals['weeklyWorkouts'] ?? 3;
    final targetWeight = goals['targetWeight'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Your Fitness Goals',
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                // Navigate to edit goals screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit goals feature coming soon!')),
                );
              },
            ),
            children: [
              // Nutrition goals
              Text('Nutrition', style: AppTextStyles.heading4),
              const SizedBox(height: 8),
              _buildGoalItem(Icons.local_fire_department, 'Daily Calories', '$dailyCalories calories'),
              _buildGoalItem(Icons.water_drop, 'Daily Water', '$dailyWater ml'),
              
              const SizedBox(height: 16),
              
              // Activity goals
              Text('Activity', style: AppTextStyles.heading4),
              const SizedBox(height: 8),
              _buildGoalItem(Icons.directions_walk, 'Daily Steps', '$dailySteps steps'),
              _buildGoalItem(Icons.fitness_center, 'Weekly Workouts', '$weeklyWorkouts workouts'),
              
              if (targetWeight != null) ...[
                const SizedBox(height: 16),
                
                // Weight goal
                Text('Weight', style: AppTextStyles.heading4),
                const SizedBox(height: 8),
                _buildGoalItem(
                  Icons.monitor_weight, 
                  'Target Weight', 
                  '${targetWeight.toStringAsFixed(1)} kg',
                  subtitle: _user!.weight != null 
                      ? '${(targetWeight - _user!.weight!).abs().toStringAsFixed(1)} kg ${targetWeight < _user!.weight! ? 'to lose' : 'to gain'}' 
                      : null,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress visualization
          SectionCard(
            title: 'Goal Progress',
            children: [
              const Text('Visualized progress toward your goals will be shown here.'),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Goal progress charts coming soon!'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    // Get user settings
    final settings = _user!.settings ?? {};
    final useDarkMode = settings['useDarkMode'] ?? false;
    final useMetricSystem = settings['useMetricSystem'] ?? true;
    final enableNotifications = settings['enableNotifications'] ?? true;
    final notificationTimes = settings['notificationTimes'] as List<dynamic>? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App settings
          SectionCard(
            title: 'App Settings',
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: useDarkMode,
                onChanged: (value) {
                  // In a real app, update user settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme toggle feature coming soon!')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Use Metric System'),
                subtitle: const Text('Switch between metric and imperial units'),
                value: useMetricSystem,
                onChanged: (value) {
                  // In a real app, update user settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unit system toggle feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notification settings
          SectionCard(
            title: 'Notification Settings',
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive reminders and updates'),
                value: enableNotifications,
                onChanged: (value) {
                  // In a real app, update user settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification toggle feature coming soon!')),
                  );
                },
              ),
              if (enableNotifications && notificationTimes.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text('Notification Times'),
                ),
                ...notificationTimes.map((time) => ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(time),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Edit notification time
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit notification time feature coming soon!')),
                      );
                    },
                  ),
                )),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Notification Time'),
                  onPressed: () {
                    // Add notification time
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add notification time feature coming soon!')),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // About app
          SectionCard(
            title: 'About',
            children: [
              ListTile(
                title: const Text('App Version'),
                trailing: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to terms of service
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of service feature coming soon!')),
                  );
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to privacy policy
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy policy feature coming soon!')),
                  );
                },
              ),
              ListTile(
                title: const Text('Licenses'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show licenses
                  showLicensePage(context: context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildGoalItem(IconData icon, String title, String value, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Text(
        value,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}