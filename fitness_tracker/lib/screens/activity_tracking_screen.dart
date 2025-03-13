import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class ActivityTrackingScreen extends StatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  _ActivityTrackingScreenState createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _activities = [];
  Map<String, double> _activityTypeSummary = {};
  late TabController _tabController;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _activityNameController = TextEditingController();
  ActivityType _selectedActivityType = ActivityType.running;
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _distanceController = TextEditingController();
  final _stepsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _automaticCalculation = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivities();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _activityNameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _distanceController.dispose();
    _stepsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Get activities for the selected date
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final activities = await _firebaseService.getActivitiesForDateRange(
        userId,
        startOfDay,
        endOfDay,
      );
      
      // Calculate activity type summary
      final Map<String, double> typeSummary = {};
      for (final activity in activities) {
        final type = activity['type'] as String? ?? 'other';
        final calories = activity['calories'] as int? ?? 0;
        
        typeSummary[type] = (typeSummary[type] ?? 0) + calories;
      }
      
      setState(() {
        _activities = activities;
        _activityTypeSummary = typeSummary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activities: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadActivities();
    }
  }
  
  Future<void> _addActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Parse form values
      final name = _activityNameController.text.trim();
      final type = _selectedActivityType.toString().split('.').last;
      final duration = int.parse(_durationController.text);
      final calories = int.parse(_caloriesController.text);
      
      // Parse optional values
      int? steps;
      double? distance;
      
      if (_stepsController.text.isNotEmpty) {
        steps = int.parse(_stepsController.text);
      }
      
      if (_distanceController.text.isNotEmpty) {
        distance = double.parse(_distanceController.text);
      }
      
      // Create activity data
      final activityData = {
        'userId': userId,
        'name': name,
        'type': type,
        'date': _selectedDate,
        'duration': duration,
        'calories': calories,
        'notes': _notesController.text,
      };
      
      if (steps != null) {
        activityData['steps'] = steps;
      }
      
      if (distance != null) {
        activityData['distance'] = distance;
      }
      
      // Save to Firebase
      await _firebaseService.addActivity(activityData);
      
      // Reset form
      _activityNameController.clear();
      _durationController.clear();
      _caloriesController.clear();
      _distanceController.clear();
      _stepsController.clear();
      _notesController.clear();
      
      // Reload activities
      await _loadActivities();
      
      // Navigate back to the log tab
      _tabController.animateTo(0);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding activity: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding activity: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteActivity(String activityId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        await _firebaseService.deleteActivity(activityId);
        
        // Reload activities
        await _loadActivities();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting activity: $e');
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting activity: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  Color _getActivityColor(String type) {
    switch (type) {
      case 'running':
        return AppColors.running;
      case 'walking':
        return AppColors.walking;
      case 'cycling':
        return AppColors.cycling;
      case 'swimming':
        return AppColors.swimming;
      case 'yoga':
        return AppColors.yoga;
      case 'weightTraining':
        return AppColors.gym;
      default:
        return Colors.grey;
    }
  }
  
  String _getActivityIcon(String type) {
    switch (type) {
      case 'running':
        return '🏃';
      case 'walking':
        return '🚶';
      case 'cycling':
        return '🚴';
      case 'swimming':
        return '🏊';
      case 'yoga':
        return '🧘';
      case 'weightTraining':
        return '🏋️';
      case 'hiking':
        return '🥾';
      default:
        return '🏆';
    }
  }
  
  // Calculate calories based on activity type, duration, and user data
  void _calculateCalories() {
    if (!_automaticCalculation) return;
    
    if (_durationController.text.isEmpty) {
      _caloriesController.clear();
      return;
    }
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userProfile = userProvider.userProfile;
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      // Get user weight in kg
      double weight = 70; // Default weight if user profile not available
      if (userProfile != null && userProfile['weight'] != null) {
        weight = (userProfile['weight'] as num).toDouble();
      }
      
      // Get activity duration in minutes
      final duration = int.parse(_durationController.text);
      
      // Calculate calories based on MET (Metabolic Equivalent of Task) values
      double met;
      switch (_selectedActivityType) {
        case ActivityType.running:
          met = 9.8; // Running at 6 mph
          break;
        case ActivityType.walking:
          met = 3.5; // Walking at moderate pace
          break;
        case ActivityType.cycling:
          met = 7.5; // Cycling at moderate effort
          break;
        case ActivityType.swimming:
          met = 8.0; // Swimming laps
          break;
        case ActivityType.yoga:
          met = 3.0; // Yoga
          break;
        case ActivityType.hiking:
          met = 5.3; // Hiking
          break;
        case ActivityType.weightTraining:
          met = 3.5; // Weight training
          break;
        case ActivityType.other:
          met = 4.0; // General exercise
          break;
      }
      
      // Calories = MET * weight (kg) * duration (hours)
      final hours = duration / 60.0;
      final calories = (met * weight * hours).round();
      
      // Update calories field
      _caloriesController.text = calories.toString();
    } catch (e) {
      print('Error calculating calories: $e');
    }
  }
  
  void _calculateSteps() {
    if (!_automaticCalculation) return;
    
    if (_durationController.text.isEmpty) {
      _stepsController.clear();
      return;
    }
    
    // Only auto calculate steps for walking and running
    if (_selectedActivityType != ActivityType.walking && 
        _selectedActivityType != ActivityType.running) {
      return;
    }
    
    try {
      // Get activity duration in minutes
      final duration = int.parse(_durationController.text);
      
      // Calculate steps based on activity type and duration
      int stepsPerMinute;
      if (_selectedActivityType == ActivityType.running) {
        stepsPerMinute = 150; // Average steps per minute when running
      } else {
        stepsPerMinute = 100; // Average steps per minute when walking
      }
      
      final steps = duration * stepsPerMinute;
      
      // Update steps field
      _stepsController.text = steps.toString();
    } catch (e) {
      print('Error calculating steps: $e');
    }
  }
  
  void _calculateDistance() {
    if (!_automaticCalculation) return;
    
    if (_durationController.text.isEmpty) {
      _distanceController.clear();
      return;
    }
    
    // Only auto calculate distance for walking, running, and cycling
    if (_selectedActivityType != ActivityType.walking && 
        _selectedActivityType != ActivityType.running &&
        _selectedActivityType != ActivityType.cycling) {
      return;
    }
    
    try {
      final isMetric = Provider.of<SettingsProvider>(context, listen: false).useMetricSystem;
      
      // Get activity duration in minutes
      final duration = int.parse(_durationController.text);
      
      // Calculate distance based on activity type and duration
      double speedKmPerHour;
      if (_selectedActivityType == ActivityType.running) {
        speedKmPerHour = 10.0; // Average running speed: 10 km/h
      } else if (_selectedActivityType == ActivityType.cycling) {
        speedKmPerHour = 20.0; // Average cycling speed: 20 km/h
      } else {
        speedKmPerHour = 5.0; // Average walking speed: 5 km/h
      }
      
      // Calculate distance in km
      final hours = duration / 60.0;
      double distance = speedKmPerHour * hours;
      
      // Convert to miles if using imperial units
      if (!isMetric) {
        distance = AppHelpers.kmToMiles(distance);
      }
      
      // Update distance field with 2 decimal places
      _distanceController.text = distance.toStringAsFixed(2);
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }
  
  String _getDurationString(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '$hours hr ${mins > 0 ? '$mins min' : ''}';
    } else {
      return '$mins min';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isMetric = Provider.of<SettingsProvider>(context).useMetricSystem;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activity Log'),
            Tab(text: 'Add Activity'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading activities...')
          : TabBarView(
              controller: _tabController,
              children: [
                // Activity Log Tab
                _buildActivityLogTab(isMetric),
                
                // Add Activity Tab
                _buildAddActivityTab(isMetric),
              ],
            ),
    );
  }
  
  Widget _buildActivityLogTab(bool isMetric) {
    // Calculate daily totals
    int totalCalories = 0;
    int totalSteps = 0;
    double totalDistance = 0.0;
    int totalDuration = 0;
    
    for (final activity in _activities) {
      totalCalories += activity['calories'] ?? 0;
      totalSteps += activity['steps'] ?? 0;
      totalDistance += activity['distance'] ?? 0.0;
      totalDuration += activity['duration'] ?? 0;
    }
    
    final distanceUnit = isMetric ? AppConstants.unitKm : AppConstants.unitMi;
    
    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            DateRangeSelector(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                _loadActivities();
              },
            ),
            const SizedBox(height: 24),
            
            // Daily summary
            const Text(
              'Daily Summary',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Calories',
                    value: '$totalCalories',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Steps',
                    value: '$totalSteps',
                    icon: Icons.directions_walk,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Distance',
                    value: '${totalDistance.toStringAsFixed(2)} $distanceUnit',
                    icon: Icons.straighten,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Duration',
                    value: _getDurationString(totalDuration),
                    icon: Icons.timer,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Activity breakdown
            if (_activityTypeSummary.isNotEmpty) ...[
              const Text(
                'Activity Breakdown',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildActivityPieChart(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Activity list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activities',
                  style: AppTextStyles.heading3,
                ),
                Text(
                  '${_activities.length} ${_activities.length == 1 ? 'activity' : 'activities'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_activities.isEmpty) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_run,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No activities logged for this day',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Add Activity',
                      icon: Icons.add,
                      onPressed: () => _tabController.animateTo(1),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  final activityId = activity['id'] as String;
                  final name = activity['name'] as String;
                  final type = activity['type'] as String? ?? 'other';
                  final duration = activity['duration'] as int? ?? 0;
                  final calories = activity['calories'] as int? ?? 0;
                  final steps = activity['steps'] as int?;
                  final distance = activity['distance'] as double?;
                  final notes = activity['notes'] as String?;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getActivityColor(type).withOpacity(0.2),
                                child: Text(
                                  _getActivityIcon(type),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.heading4,
                                    ),
                                    Text(
                                      '${_getDurationString(duration)} • ${calories} kcal',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                tooltip: 'Delete Activity',
                                onPressed: () => _deleteActivity(activityId),
                              ),
                            ],
                          ),
                          if (steps != null || distance != null) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (steps != null) ...[
                                  const Icon(
                                    Icons.directions_walk,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$steps steps',
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (distance != null) ...[
                                  const Icon(
                                    Icons.straighten,
                                    size: 16,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${distance.toStringAsFixed(2)} $distanceUnit',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (notes != null && notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              notes,
                              style: AppTextStyles.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityPieChart() {
    // Convert activity type summary to pie chart data
    final List<PieChartSectionData> sections = [];
    double totalCalories = 0;
    
    _activityTypeSummary.forEach((type, calories) {
      totalCalories += calories;
    });
    
    if (totalCalories == 0) {
      return const Center(
        child: Text('No activity data to display'),
      );
    }
    
    const double radius = 80;
    final List<String> activityTypes = _activityTypeSummary.keys.toList();
    
    for (var i = 0; i < activityTypes.length; i++) {
      final type = activityTypes[i];
      final calories = _activityTypeSummary[type]!;
      final percentage = calories / totalCalories;
      
      sections.add(
        PieChartSectionData(
          color: _getActivityColor(type),
          value: calories,
          title: '${(percentage * 100).round()}%',
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              startDegreeOffset: -90,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: activityTypes.map((type) {
              final calories = _activityTypeSummary[type]!;
              final percentage = calories / totalCalories * 100;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getActivityColor(type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type.substring(0, 1).toUpperCase() + type.substring(1),
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${calories.toInt()} kcal (${percentage.toInt()}%)',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddActivityTab(bool isMetric) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity date
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMMd().format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Activity name
            TextFormField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Activity Name',
                hintText: 'e.g. Morning Run, Yoga Class',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an activity name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Activity type
            DropdownButtonFormField<ActivityType>(
              value: _selectedActivityType,
              decoration: const InputDecoration(
                labelText: 'Activity Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ActivityType.values.map((type) {
                String label = type.toString().split('.').last;
                label = label.substring(0, 1).toUpperCase() + label.substring(1);
                
                IconData iconData;
                switch (type) {
                  case ActivityType.running:
                    iconData = Icons.directions_run;
                    break;
                  case ActivityType.walking:
                    iconData = Icons.directions_walk;
                    break;
                  case ActivityType.cycling:
                    iconData = Icons.directions_bike;
                    break;
                  case ActivityType.swimming:
                    iconData = Icons.pool;
                    break;
                  case ActivityType.yoga:
                    iconData = Icons.self_improvement;
                    break;
                  case ActivityType.hiking:
                    iconData = Icons.terrain;
                    break;
                  case ActivityType.weightTraining:
                    iconData = Icons.fitness_center;
                    break;
                  case ActivityType.other:
                    iconData = Icons.more_horiz;
                    break;
                }
                
                return DropdownMenuItem<ActivityType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(iconData, color: _getActivityColor(type.toString().split('.').last)),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedActivityType = value);
                  
                  // Recalculate values based on new activity type
                  if (_durationController.text.isNotEmpty) {
                    _calculateCalories();
                    _calculateSteps();
                    _calculateDistance();
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Duration
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'e.g. 30',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a duration';
                }
                try {
                  final duration = int.parse(value);
                  if (duration <= 0) {
                    return 'Duration must be greater than 0';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _calculateCalories();
                  _calculateSteps();
                  _calculateDistance();
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Automatic calculation switch
            SwitchListTile(
              title: const Text('Automatic Calculation'),
              subtitle: const Text('Calculate calories, steps and distance based on activity type and duration'),
              value: _automaticCalculation,
              onChanged: (value) {
                setState(() => _automaticCalculation = value);
                
                if (value && _durationController.text.isNotEmpty) {
                  _calculateCalories();
                  _calculateSteps();
                  _calculateDistance();
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Calories
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories Burned',
                hintText: 'e.g. 250',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
                suffixText: 'kcal',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter calories burned';
                }
                try {
                  final calories = int.parse(value);
                  if (calories <= 0) {
                    return 'Calories must be greater than 0';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              enabled: !_automaticCalculation,
            ),
            const SizedBox(height: 16),
            
            // Steps and Distance in a row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Steps
                Expanded(
                  child: TextFormField(
                    controller: _stepsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Steps (optional)',
                      hintText: 'e.g. 5000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_walk),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final steps = int.parse(value);
                          if (steps <= 0) {
                            return 'Steps must be greater than 0';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                    enabled: !_automaticCalculation || 
                            (_selectedActivityType != ActivityType.walking && 
                             _selectedActivityType != ActivityType.running),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Distance
                Expanded(
                  child: TextFormField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Distance (optional)',
                      hintText: 'e.g. 5.2',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.straighten),
                      suffixText: isMetric ? AppConstants.unitKm : AppConstants.unitMi,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final distance = double.parse(value);
                          if (distance <= 0) {
                            return 'Distance must be greater than 0';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                    enabled: !_automaticCalculation || 
                            (_selectedActivityType != ActivityType.walking && 
                             _selectedActivityType != ActivityType.running &&
                             _selectedActivityType != ActivityType.cycling),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this activity',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save Activity',
                icon: Icons.check,
                onPressed: _addActivity,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}