import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../activity_tab_screen.dart';
import '../nutrition_tab_screen.dart';
import '../sleep_tab_screen.dart';
import '../profile_tab_screen.dart';
import '../dashboard.dart';
import '../../utils/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const Dashboard(),
    const ActivityTabScreen(),
    const NutritionTabScreen(),
    const SleepTabScreen(),
    const ProfileTabScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebDesktop = kIsWeb && screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      // For web desktop layout, use a Row with navigation rail instead of bottom navigation
      body: isWebDesktop
          ? Row(
              children: [
                // Navigation Rail for larger screens
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.directions_run),
                      selectedIcon: Icon(Icons.directions_run),
                      label: Text('Activity'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.restaurant_menu),
                      selectedIcon: Icon(Icons.restaurant_menu),
                      label: Text('Nutrition'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bedtime),
                      selectedIcon: Icon(Icons.bedtime),
                      label: Text('Sleep'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                // Vertical divider for visual separation
                const VerticalDivider(thickness: 1, width: 1),
                // Main content area
                Expanded(
                  child: Center(
                    child: _screens[_currentIndex],
                  ),
                ),
              ],
            )
          : _screens[_currentIndex],
      // Only show bottom navigation for mobile view
      bottomNavigationBar: isWebDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_run),
                  label: 'Activity',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Nutrition',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bedtime),
                  label: 'Sleep',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
      floatingActionButton: _currentIndex != 4 ? FloatingActionButton(
        onPressed: () => _showAddActionDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add new entry',
      ) : null,
    );
  }
  
  String _getAppBarTitle() {
    // For web, show the app name alongside the current section
    if (kIsWeb) {
      String sectionName = "";
      switch (_currentIndex) {
        case 0: sectionName = 'Dashboard'; break;
        case 1: sectionName = 'Activity Tracking'; break;
        case 2: sectionName = 'Nutrition'; break;
        case 3: sectionName = 'Sleep Tracking'; break;
        case 4: sectionName = 'Profile'; break;
        default: sectionName = ''; break;
      }
      return '${AppConstants.appName} - $sectionName';
    } else {
      // For mobile, just show the section name
      switch (_currentIndex) {
        case 0: return 'Dashboard';
        case 1: return 'Activity Tracking';
        case 2: return 'Nutrition';
        case 3: return 'Sleep Tracking';
        case 4: return 'Profile';
        default: return AppConstants.appName;
      }
    }
  }
  
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
    }
  }
  
  Future<void> _showAddActionDialog(BuildContext context) async {
    final theme = Theme.of(context);
    
    // Use a Dialog for web and BottomSheet for mobile
    if (kIsWeb && MediaQuery.of(context).size.width > 800) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 400, // Fixed width for web dialog
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Entry',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Options based on current tab
                _buildActionOptions(context),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Entry',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Options based on current tab
              _buildActionOptions(context),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildActionOptions(BuildContext context) {
    switch (_currentIndex) {
      case 0: // Dashboard
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionTile(
              context: context,
              icon: Icons.directions_run,
              title: 'Add Activity',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add activity screen
              },
            ),
            _buildActionTile(
              context: context,
              icon: Icons.restaurant_menu,
              title: 'Add Meal',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add meal screen
              },
            ),
            _buildActionTile(
              context: context,
              icon: Icons.bedtime,
              title: 'Add Sleep Record',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add sleep record screen
              },
            ),
          ],
        );
        
      case 1: // Activity
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionTile(
              context: context,
              icon: Icons.fitness_center,
              title: 'Add Workout',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add workout screen
              },
            ),
            _buildActionTile(
              context: context,
              icon: Icons.directions_walk,
              title: 'Add Steps',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add steps screen
              },
            ),
          ],
        );
        
      case 2: // Nutrition
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionTile(
              context: context,
              icon: Icons.restaurant,
              title: 'Add Meal',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add meal screen
              },
            ),
            _buildActionTile(
              context: context,
              icon: Icons.local_drink,
              title: 'Add Water Intake',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add water intake screen
              },
            ),
          ],
        );
        
      case 3: // Sleep
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionTile(
              context: context,
              icon: Icons.hotel,
              title: 'Add Sleep Record',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add sleep record screen
              },
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isWeb = kIsWeb;
    
    // Use different styling for web
    if (isWeb) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      );
    } else {
      // Use ListTile for mobile
      return ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
    }
  }
}