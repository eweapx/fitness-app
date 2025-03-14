import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile section
          if (userProvider.isAuthenticated) _buildProfileSection(userProvider),
          
          // Units & Preferences
          _buildUnitsSection(settingsProvider),
          
          // Goal settings
          _buildGoalsSection(settingsProvider),
          
          // Display settings
          _buildDisplaySection(settingsProvider),
          
          // Notifications settings
          _buildNotificationsSection(settingsProvider),
          
          // Support section
          _buildSupportSection(),
          
          // About section
          _buildAboutSection(),
          
          // Logout button
          if (userProvider.isAuthenticated) _buildLogoutButton(userProvider),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileSection(UserProvider userProvider) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: AppTextStyles.heading3,
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: userProvider.userPhotoUrl != null
                    ? NetworkImage(userProvider.userPhotoUrl!)
                    : null,
                child: userProvider.userPhotoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(userProvider.userName ?? 'User'),
              subtitle: Text(userProvider.userEmail ?? 'No email'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsSection(SettingsProvider settingsProvider) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Units & Preferences',
              style: AppTextStyles.heading3,
            ),
            SwitchListTile(
              title: const Text('Use Metric System'),
              subtitle: const Text('Switch between metric and imperial units'),
              value: settingsProvider.useMetricUnits,
              onChanged: (value) {
                settingsProvider.setUseMetricUnits(value);
              },
            ),
            if (!settingsProvider.useMetricUnits) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'You are using imperial units (lb, ft, mi, oz)',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ] else ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'You are using metric units (kg, cm, km, ml)',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(SettingsProvider settingsProvider) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals',
              style: AppTextStyles.heading3,
            ),
            ListTile(
              title: const Text('Daily Step Goal'),
              subtitle: Text('${AppHelpers.formatNumber(settingsProvider.stepGoal)} steps'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showStepGoalDialog(settingsProvider);
                },
              ),
            ),
            ListTile(
              title: const Text('Daily Water Goal'),
              subtitle: settingsProvider.useMetricUnits
                  ? Text('${settingsProvider.waterGoal} ml')
                  : Text('${AppHelpers.mlToOz(settingsProvider.waterGoal.toDouble()).toStringAsFixed(1)} oz'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showWaterGoalDialog(settingsProvider);
                },
              ),
            ),
            ListTile(
              title: const Text('Daily Calorie Goal'),
              subtitle: Text('${AppHelpers.formatNumber(settingsProvider.calorieGoal)} calories'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showCalorieGoalDialog(settingsProvider);
                },
              ),
            ),
            ListTile(
              title: const Text('Daily Sleep Goal'),
              subtitle: Text(AppHelpers.formatDuration(settingsProvider.sleepGoal)),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showSleepGoalDialog(settingsProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection(SettingsProvider settingsProvider) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display',
              style: AppTextStyles.heading3,
            ),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(
                settingsProvider.themeMode == ThemeMode.system
                    ? 'System Default'
                    : settingsProvider.themeMode == ThemeMode.light
                        ? 'Light'
                        : 'Dark',
              ),
              trailing: DropdownButton<ThemeMode>(
                value: settingsProvider.themeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    settingsProvider.setThemeMode(newValue);
                  }
                },
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(SettingsProvider settingsProvider) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: AppTextStyles.heading3,
            ),
            SwitchListTile(
              title: const Text('Daily Reminders'),
              subtitle: Text(
                'Remind me at ${AppHelpers.formatTimeOfDay(settingsProvider.reminderTime, settingsProvider.timeFormat == '24h')}',
              ),
              value: settingsProvider.reminderEnabled,
              onChanged: (value) {
                if (value) {
                  _showReminderTimeDialog(settingsProvider);
                } else {
                  settingsProvider.setReminder(false);
                }
              },
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(AppHelpers.formatTimeOfDay(settingsProvider.reminderTime, settingsProvider.timeFormat == '24h')),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: settingsProvider.reminderEnabled
                    ? () {
                        _showReminderTimeDialog(settingsProvider);
                      }
                    : null,
              ),
              enabled: settingsProvider.reminderEnabled,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Activity Reminders'),
              subtitle: const Text('Remind me to move if inactive'),
              value: true,
              onChanged: (value) {
                // This would be implemented with a provider method
              },
            ),
            SwitchListTile(
              title: const Text('Water Reminders'),
              subtitle: const Text('Remind me to drink water'),
              value: true,
              onChanged: (value) {
                // This would be implemented with a provider method
              },
            ),
            SwitchListTile(
              title: const Text('Meal Reminders'),
              subtitle: const Text(
                'Remind me to log meals',
              ),
              value: true,
              onChanged: (value) {
                // This would be implemented with a provider method
              },
              secondary: const Icon(Icons.notifications_active),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support',
              style: AppTextStyles.heading3,
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help using the app'),
              onTap: () => _launchURL(AppConstants.supportUrl),
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Send Feedback'),
              subtitle: const Text('Help us improve the app'),
              onTap: () {
                // Implement feedback form
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback form not implemented yet')),
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
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: AppTextStyles.heading3,
            ),
            ListTile(
              title: const Text('App Version'),
              subtitle: Text(AppConstants.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Service'),
              onTap: () => _launchURL(AppConstants.termsUrl),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () => _launchURL(AppConstants.privacyUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('LOGOUT'),
                ),
              ],
            ),
          );
          
          if (confirm == true && mounted) {
            await userProvider.logout();
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('LOGOUT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Future<void> _showStepGoalDialog(SettingsProvider settingsProvider) async {
    final controller = TextEditingController(
      text: settingsProvider.stepGoal.toString(),
    );
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Daily Step Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Steps',
              hintText: 'Enter your daily step goal',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SAVE'),
              onPressed: () {
                final steps = int.tryParse(controller.text);
                if (steps != null && steps > 0) {
                  settingsProvider.setStepGoal(steps);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWaterGoalDialog(SettingsProvider settingsProvider) async {
    final isMetric = settingsProvider.useMetricUnits;
    final waterValue = isMetric
        ? settingsProvider.waterGoal
        : AppHelpers.mlToOz(settingsProvider.waterGoal.toDouble()).round();
    
    final controller = TextEditingController(
      text: waterValue.toString(),
    );
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Daily Water Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isMetric ? 'Milliliters (ml)' : 'Fluid Ounces (oz)',
              hintText: 'Enter your daily water goal',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SAVE'),
              onPressed: () {
                final water = int.tryParse(controller.text);
                if (water != null && water > 0) {
                  final waterMl = isMetric
                      ? water
                      : AppHelpers.ozToMl(water.toDouble()).round();
                  settingsProvider.setWaterGoal(waterMl);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCalorieGoalDialog(SettingsProvider settingsProvider) async {
    final controller = TextEditingController(
      text: settingsProvider.calorieGoal.toString(),
    );
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Daily Calorie Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calories',
              hintText: 'Enter your daily calorie goal',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SAVE'),
              onPressed: () {
                final calories = int.tryParse(controller.text);
                if (calories != null && calories > 0) {
                  settingsProvider.setCalorieGoal(calories);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSleepGoalDialog(SettingsProvider settingsProvider) async {
    // Convert minutes to hours and minutes
    final hours = settingsProvider.sleepGoal ~/ 60;
    final minutes = settingsProvider.sleepGoal % 60;
    
    int selectedHours = hours;
    int selectedMinutes = minutes;
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Daily Sleep Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select your target sleep duration:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours
                  SizedBox(
                    width: 60,
                    child: DropdownButton<int>(
                      value: selectedHours,
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            selectedHours = value;
                          });
                        }
                      },
                      items: List.generate(
                        12,
                        (index) => DropdownMenuItem<int>(
                          value: index,
                          child: Text('$index'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('hours'),
                  const SizedBox(width: 16),
                  
                  // Minutes
                  SizedBox(
                    width: 60,
                    child: DropdownButton<int>(
                      value: selectedMinutes,
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            selectedMinutes = value;
                          });
                        }
                      },
                      items: List.generate(
                        12,
                        (index) => DropdownMenuItem<int>(
                          value: index * 5,
                          child: Text('${index * 5}'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('minutes'),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SAVE'),
              onPressed: () {
                final totalMinutes = (selectedHours * 60) + selectedMinutes;
                settingsProvider.setSleepGoal(totalMinutes);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReminderTimeDialog(SettingsProvider settingsProvider) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: settingsProvider.reminderTime,
    );
    
    if (selectedTime != null) {
      settingsProvider.setReminder(true, selectedTime);
    }
  }
}