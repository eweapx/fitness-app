import 'package:flutter/material.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/sleep/sleep_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../themes/app_colors.dart';
import '../utils/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const ActivityScreen(),
    const NutritionScreen(),
    const SleepScreen(),
    const StatsScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nightlight),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show add activity/meal/sleep dialog
          _showAddDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.directions_run,
                  color: AppColors.primary,
                ),
                title: const Text('Add Activity'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 0;
                  });
                  // Show activity form
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.restaurant,
                  color: AppColors.accent,
                ),
                title: const Text('Add Meal'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 1;
                  });
                  // Show meal form
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.nightlight,
                  color: AppColors.deepSleep,
                ),
                title: const Text('Add Sleep'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 2;
                  });
                  // Show sleep form
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.local_drink,
                  color: AppColors.water,
                ),
                title: const Text('Add Water'),
                onTap: () {
                  Navigator.pop(context);
                  // Show water form
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}