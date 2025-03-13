import 'package:flutter/material.dart';
import '../screens/activity_screen.dart';
import '../screens/workout_screen.dart';
import '../services/step_tracking_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class ActivityTabScreen extends StatefulWidget {
  const ActivityTabScreen({super.key});

  @override
  _ActivityTabScreenState createState() => _ActivityTabScreenState();
}

class _ActivityTabScreenState extends State<ActivityTabScreen> {
  final StepTrackingService _stepTrackingService = StepTrackingService();
  bool _isLoading = true;
  int _todaySteps = 0;
  int _stepGoal = 10000;
  bool _hasStepPermission = false;

  @override
  void initState() {
    super.initState();
    _checkStepPermissions();
  }

  Future<void> _checkStepPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if step tracking permission is granted
      _hasStepPermission = await _stepTrackingService.checkPermissions();
      
      if (_hasStepPermission) {
        // Get today's step count
        final steps = await _stepTrackingService.getStepCount(DateTime.now());
        setState(() => _todaySteps = steps ?? 0);
      }
    } catch (e) {
      print('Error checking step permissions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestStepPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final granted = await _stepTrackingService.requestPermissions();
      setState(() => _hasStepPermission = granted);
      
      if (granted) {
        // Get today's step count
        final steps = await _stepTrackingService.getStepCount(DateTime.now());
        setState(() => _todaySteps = steps ?? 0);
      }
    } catch (e) {
      print('Error requesting step permissions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading activity data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Steps card
                  _buildStepsCard(),
                  const SizedBox(height: 16),
                  
                  // Activity options
                  _buildActivityOptions(),
                  const SizedBox(height: 16),
                  
                  // Recent activities
                  _buildRecentActivities(),
                ],
              ),
            ),
    );
  }

  Widget _buildStepsCard() {
    final percentComplete = _todaySteps / _stepGoal;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Steps',
                        style: AppTextStyles.heading3,
                      ),
                      Text(
                        '$_todaySteps / $_stepGoal steps',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                CircularPercentIndicator(
                  percent: percentComplete > 1.0 ? 1.0 : percentComplete,
                  radius: 40,
                  lineWidth: 10,
                  centerText: '${(percentComplete * 100).toInt()}%',
                  label: 'Goal',
                  color: percentComplete >= 1.0 
                      ? AppColors.success 
                      : AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentComplete > 1.0 ? 1.0 : percentComplete,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentComplete >= 1.0 
                    ? AppColors.success 
                    : AppColors.primary,
              ),
            ),
            
            if (!_hasStepPermission)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: AppButton(
                  label: 'Enable Step Tracking',
                  icon: Icons.directions_walk,
                  onPressed: _requestStepPermissions,
                  isFullWidth: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Start',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActivityOptionCard(
                'Record Workout',
                Icons.fitness_center,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActivityOptionCard(
                'Go for a Run',
                Icons.directions_run,
                Colors.orangeAccent,
                () {
                  // Start run tracking (would be implemented in a real app)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Run tracking would start here')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActivityOptionCard(
                'Activity History',
                Icons.history,
                Colors.blueAccent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivityScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActivityOptionCard(
                'Step Challenges',
                Icons.emoji_events,
                Colors.amber,
                () {
                  // Navigate to challenges screen (would be implemented in a real app)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Step challenges would open here')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityOptionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: AppTextStyles.heading3,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivityScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // In a real app, this would be a list of recent activities
            // For now, we'll show a message to add activities
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No recent activities found.\nComplete a workout to see it here!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Record Activity',
              icon: Icons.add,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutScreen(),
                  ),
                );
              },
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}