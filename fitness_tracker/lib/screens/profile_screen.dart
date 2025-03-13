import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildSettingsSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Get current user info if available
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'example@email.com';
    final name = user?.displayName ?? 'Fitness User';

    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            // Edit profile
          },
          child: const Text('Edit Profile'),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Height', '175 cm'),
                _buildStatItem('Weight', '70 kg'),
                _buildStatItem('BMI', '22.9'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAchievementStat('Activities', '145'),
                  const VerticalDivider(),
                  _buildAchievementStat('Total Workouts', '67h'),
                  const VerticalDivider(),
                  _buildAchievementStat('Achievements', '12'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildSettingItem('Goal Settings', Icons.flag, Colors.orange, 
            onTap: () {
              // Navigate to Goal Settings
            },
          ),
          const Divider(height: 1),
          _buildSettingItem('Notifications', Icons.notifications, Colors.red,
            onTap: () {
              // Navigate to Notifications Settings
            },
          ),
          const Divider(height: 1),
          _buildSettingItem('Privacy', Icons.privacy_tip, Colors.purple,
            onTap: () {
              // Navigate to Privacy Settings
            },
          ),
          const Divider(height: 1),
          _buildSettingItem('Data Backup', Icons.backup, Colors.green,
            onTap: () {
              // Navigate to Data Backup
            },
          ),
          const Divider(height: 1),
          _buildSettingItem('Help & Support', Icons.help, Colors.blue,
            onTap: () {
              // Navigate to Help & Support
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, Color iconColor, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}