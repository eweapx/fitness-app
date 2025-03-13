import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();
  
  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.signOut();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        await settingsProvider.resetToDefaults();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings reset to defaults'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error resetting settings: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting settings: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri);
    } catch (e) {
      print('Error launching URL: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = userProvider.user;
    final userProfile = userProvider.userProfile;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading settings...')
          : ListView(
              children: [
                // User profile section
                if (user != null) _buildProfileSection(user, userProfile),
                
                // App settings section
                _buildAppSettingsSection(settingsProvider),
                
                // Notifications section
                _buildNotificationsSection(settingsProvider),
                
                // Goals section
                _buildGoalsSection(settingsProvider),
                
                // Support section
                _buildSupportSection(),
                
                // About section
                _buildAboutSection(),
                
                // Sign out button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppButton(
                    label: 'Sign Out',
                    icon: Icons.logout,
                    onPressed: _signOut,
                    isFullWidth: true,
                    color: Colors.red,
                  ),
                ),
                
                // Reset settings button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppButton(
                    label: 'Reset Settings',
                    icon: Icons.restore,
                    onPressed: _resetSettings,
                    isFullWidth: true,
                    isOutlined: true,
                    color: Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
    );
  }
  
  Widget _buildProfileSection(User user, Map<String, dynamic>? userProfile) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null
                      ? Text(
                          (user.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'User',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppSettingsSection(SettingsProvider settingsProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'App Settings',
              style: AppTextStyles.heading3,
            ),
          ),
          const Divider(height: 1),
          
          // Theme mode
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: const Text('Light, dark, or system default'),
            trailing: DropdownButton<ThemeMode>(
              value: settingsProvider.themeMode,
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setThemeMode(value);
                }
              },
            ),
          ),
          
          // Measurement system
          SwitchListTile(
            secondary: const Icon(Icons.straighten),
            title: const Text('Use Metric System'),
            subtitle: Text(
              settingsProvider.useMetricSystem
                  ? 'Using kg, km, cm'
                  : 'Using lbs, miles, feet',
            ),
            value: settingsProvider.useMetricSystem,
            onChanged: (value) {
              settingsProvider.setUseMetricSystem(value);
            },
          ),
          
          // Time format
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time Format'),
            subtitle: Text(
              settingsProvider.timeFormat == AppConstants.timeFormat24h
                  ? '24-hour (13:00)'
                  : '12-hour (1:00 PM)',
            ),
            trailing: DropdownButton<String>(
              value: settingsProvider.timeFormat,
              underline: Container(),
              items: [
                DropdownMenuItem(
                  value: AppConstants.timeFormat24h,
                  child: const Text('24-hour'),
                ),
                DropdownMenuItem(
                  value: AppConstants.timeFormat12h,
                  child: const Text('12-hour'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTimeFormat(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationsSection(SettingsProvider settingsProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: AppTextStyles.heading3,
            ),
          ),
          const Divider(height: 1),
          
          // Notifications master switch
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Turn on/off all notifications'),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) async {
              await settingsProvider.setNotificationsEnabled(value);
              
              // Request permissions if turning on
              if (value) {
                await _notificationService.requestPermissions();
              }
            },
          ),
          
          if (settingsProvider.notificationsEnabled) ...[
            // Workout reminders
            SwitchListTile(
              secondary: const Icon(Icons.fitness_center),
              title: const Text('Workout Reminders'),
              subtitle: const Text('Get reminded about scheduled workouts'),
              value: settingsProvider.notificationChannels[AppConstants.notificationChannelWorkouts] ?? false,
              onChanged: (value) {
                settingsProvider.setNotificationChannelEnabled(
                  AppConstants.notificationChannelWorkouts,
                  value,
                );
              },
            ),
            
            // Habit reminders
            SwitchListTile(
              secondary: const Icon(Icons.repeat),
              title: const Text('Habit Reminders'),
              subtitle: const Text('Get reminded about your habits'),
              value: settingsProvider.notificationChannels[AppConstants.notificationChannelHabits] ?? false,
              onChanged: (value) {
                settingsProvider.setNotificationChannelEnabled(
                  AppConstants.notificationChannelHabits,
                  value,
                );
              },
            ),
            
            // Water reminders
            SwitchListTile(
              secondary: const Icon(Icons.water_drop),
              title: const Text('Water Reminders'),
              subtitle: const Text('Get reminders to stay hydrated'),
              value: settingsProvider.notificationChannels[AppConstants.notificationChannelWater] ?? false,
              onChanged: (value) {
                settingsProvider.setNotificationChannelEnabled(
                  AppConstants.notificationChannelWater,
                  value,
                );
                
                // Schedule or cancel water reminders
                if (value) {
                  _notificationService.scheduleWaterReminders();
                } else {
                  // Cancel water reminders (this would need to be implemented in the service)
                }
              },
            ),
            
            // Meal reminders
            SwitchListTile(
              secondary: const Icon(Icons.restaurant_menu),
              title: const Text('Meal Planning Reminders'),
              subtitle: const Text('Get reminders to plan your meals'),
              value: settingsProvider.notificationChannels[AppConstants.notificationChannelMeals] ?? false,
              onChanged: (value) {
                settingsProvider.setNotificationChannelEnabled(
                  AppConstants.notificationChannelMeals,
                  value,
                );
                
                // Schedule or cancel meal reminders
                if (value) {
                  _notificationService.scheduleMealPlanningReminder();
                } else {
                  // Cancel meal reminders (this would need to be implemented in the service)
                }
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGoalsSection(SettingsProvider settingsProvider) {
    final isMetric = settingsProvider.useMetricSystem;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Goals',
              style: AppTextStyles.heading3,
            ),
          ),
          const Divider(height: 1),
          
          // Steps goal
          ListTile(
            leading: const Icon(Icons.directions_walk),
            title: const Text('Daily Steps Goal'),
            subtitle: Text('${settingsProvider.stepsGoal} steps'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showGoalEditDialog(
                'Steps Goal',
                'Enter your daily steps goal',
                settingsProvider.stepsGoal.toString(),
                (value) {
                  final steps = int.tryParse(value);
                  if (steps != null && steps > 0) {
                    settingsProvider.setStepsGoal(steps);
                  }
                },
              ),
            ),
          ),
          
          // Calories goal
          ListTile(
            leading: const Icon(Icons.local_fire_department),
            title: const Text('Daily Calories Goal'),
            subtitle: Text('${settingsProvider.caloriesGoal} kcal'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showGoalEditDialog(
                'Calories Goal',
                'Enter your daily calories goal',
                settingsProvider.caloriesGoal.toString(),
                (value) {
                  final calories = int.tryParse(value);
                  if (calories != null && calories > 0) {
                    settingsProvider.setCaloriesGoal(calories);
                  }
                },
              ),
            ),
          ),
          
          // Water goal
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Daily Water Intake Goal'),
            subtitle: Text(
              isMetric
                  ? '${settingsProvider.waterGoal} ml'
                  : '${AppHelpers.mlToOz(settingsProvider.waterGoal.toDouble()).toStringAsFixed(1)} oz',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showGoalEditDialog(
                'Water Intake Goal',
                isMetric
                    ? 'Enter your daily water intake goal (ml)'
                    : 'Enter your daily water intake goal (oz)',
                isMetric
                    ? settingsProvider.waterGoal.toString()
                    : AppHelpers.mlToOz(settingsProvider.waterGoal.toDouble()).toStringAsFixed(0),
                (value) {
                  final water = int.tryParse(value);
                  if (water != null && water > 0) {
                    if (isMetric) {
                      settingsProvider.setWaterGoal(water);
                    } else {
                      // Convert oz to ml
                      final waterMl = AppHelpers.ozToMl(water.toDouble()).round();
                      settingsProvider.setWaterGoal(waterMl);
                    }
                  }
                },
              ),
            ),
          ),
          
          // Sleep goal
          ListTile(
            leading: const Icon(Icons.nightlight),
            title: const Text('Daily Sleep Goal'),
            subtitle: Text('${settingsProvider.sleepGoal} hours'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showGoalEditDialog(
                'Sleep Goal',
                'Enter your daily sleep goal (hours)',
                settingsProvider.sleepGoal.toString(),
                (value) {
                  final sleep = int.tryParse(value);
                  if (sleep != null && sleep > 0 && sleep <= 24) {
                    settingsProvider.setSleepGoal(sleep);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupportSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Support',
              style: AppTextStyles.heading3,
            ),
          ),
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & FAQ'),
            onTap: () => _launchURL(AppConstants.supportUrl),
          ),
          
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            onTap: () => _launchURL('mailto:support@fitnesstracker.com?subject=Feedback'),
          ),
          
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a Bug'),
            onTap: () => _launchURL('mailto:support@fitnesstracker.com?subject=Bug%20Report'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAboutSection() {
    const appVersion = '1.0.0';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: AppTextStyles.heading3,
            ),
          ),
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text(appVersion),
          ),
          
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () => _launchURL(AppConstants.termsUrl),
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () => _launchURL(AppConstants.privacyUrl),
          ),
          
          const AboutListTile(
            icon: Icon(Icons.code),
            applicationName: 'Fitness Tracker',
            applicationVersion: appVersion,
            applicationLegalese: '© 2024 Fitness Tracker App',
            aboutBoxChildren: [
              SizedBox(height: 16),
              Text(
                'A comprehensive health and fitness tracking mobile application featuring activity monitoring, nutrition logging, habit tracking, sleep tracking, and detailed progress visualization.',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _showGoalEditDialog(
    String title,
    String hint,
    String initialValue,
    Function(String) onSave,
  ) async {
    final controller = TextEditingController(text: initialValue);
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}