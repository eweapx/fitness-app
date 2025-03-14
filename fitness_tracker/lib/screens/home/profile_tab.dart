import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            _buildProfileHeader(context, authProvider),
            
            const SizedBox(height: 32),
            
            // Settings section
            _buildSettingsSection(context, themeProvider),
            
            const SizedBox(height: 24),
            
            // Account section
            _buildAccountSection(context, authProvider),
            
            const SizedBox(height: 24),
            
            // Help section
            _buildHelpSection(context),
            
            const SizedBox(height: 32),
            
            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context, authProvider),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.colorScheme.error),
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // Profile header
  Widget _buildProfileHeader(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Profile picture
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            user?.displayName?.isNotEmpty == true 
              ? user!.displayName!.substring(0, 1).toUpperCase() 
              : '?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? 'User',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {},
                child: Text(
                  'Edit Profile',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Settings section
  Widget _buildSettingsSection(BuildContext context, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Theme settings
        _buildSettingsItem(
          context: context,
          icon: Icons.brightness_6_outlined,
          title: 'Theme',
          subtitle: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
          onTap: () => _toggleTheme(context, themeProvider),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (_) => _toggleTheme(context, themeProvider),
          ),
        ),
        
        // Units settings
        _buildSettingsItem(
          context: context,
          icon: Icons.straighten_outlined,
          title: 'Units',
          subtitle: 'Imperial (lb, ft, in)',
          onTap: () {},
        ),
        
        // Notifications settings
        _buildSettingsItem(
          context: context,
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage reminders and alerts',
          onTap: () {},
        ),
      ],
    );
  }
  
  // Account section
  Widget _buildAccountSection(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Health data settings
        _buildSettingsItem(
          context: context,
          icon: Icons.health_and_safety_outlined,
          title: 'Health Data',
          subtitle: 'Manage your health information',
          onTap: () {},
        ),
        
        // Privacy settings
        _buildSettingsItem(
          context: context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy',
          subtitle: 'Manage data and permissions',
          onTap: () {},
        ),
        
        // Subscription settings
        _buildSettingsItem(
          context: context,
          icon: Icons.card_membership_outlined,
          title: 'Subscription',
          subtitle: 'Free Plan',
          onTap: () {},
        ),
      ],
    );
  }
  
  // Help section
  Widget _buildHelpSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help & Support',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // FAQ settings
        _buildSettingsItem(
          context: context,
          icon: Icons.help_outline,
          title: 'FAQ',
          subtitle: 'Frequently asked questions',
          onTap: () {},
        ),
        
        // Contact support settings
        _buildSettingsItem(
          context: context,
          icon: Icons.support_agent_outlined,
          title: 'Contact Support',
          subtitle: 'Get help with any issues',
          onTap: () {},
        ),
        
        // About settings
        _buildSettingsItem(
          context: context,
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version and information',
          onTap: () {},
        ),
      ],
    );
  }
  
  // Settings item widget
  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }
  
  // Toggle theme
  void _toggleTheme(BuildContext context, ThemeProvider themeProvider) {
    themeProvider.toggleTheme();
  }
  
  // Sign out
  void _signOut(BuildContext context, AuthProvider authProvider) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    // Sign out if confirmed
    if (confirm == true) {
      await authProvider.signOut();
      // Navigation will be handled by auth state listener
    }
  }
}