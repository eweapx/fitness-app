import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  bool _isLoading = true;
  List<ActivityModel> _activities = [];
  List<ActivityModel> _recentActivities = [];
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadActivities();
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

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd get the current user ID
      const String demoUserId = 'demo_user';
      
      // Load all activities
      final allActivities = await _firebaseService.getUserActivities(demoUserId);
      
      // Load activities for selected date
      final activitiesForDate = await _firebaseService.getActivitiesByDate(
        demoUserId, 
        _selectedDate,
      );
      
      setState(() {
        _activities = allActivities;
        _recentActivities = activitiesForDate;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading activities: ${e.toString()}')),
      );
    }
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _loadActivities();
  }

  void _filterActivities(String filter) {
    setState(() => _selectedFilter = filter);
  }

  List<ActivityModel> get _filteredActivities {
    if (_selectedFilter == 'all') {
      return _activities;
    } else {
      return _activities.where((activity) => activity.type == _selectedFilter).toList();
    }
  }

  void _addActivity() {
    // Navigate to add activity screen
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add activity feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading activities...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildHistoryTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivity,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: Column(
        children: [
          // Date selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DateSelector(
              selectedDate: _selectedDate,
              onDateSelected: _onDateChanged,
            ),
          ),
          
          // Stats summary
          if (_recentActivities.isNotEmpty) _buildTodayStats(),
          
          // Activities list
          Expanded(
            child: _recentActivities.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.directions_run,
                    message: 'No activities recorded for this day.\nTap the + button to add an activity.',
                    actionLabel: 'Add Activity',
                    onAction: _addActivity,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recentActivities.length,
                    itemBuilder: (context, index) {
                      return _buildActivityCard(_recentActivities[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: _activities.isEmpty
          ? EmptyStateWidget(
              icon: Icons.fitness_center,
              message: 'No activities recorded yet.\nTap the + button to add your first activity.',
              actionLabel: 'Add Activity',
              onAction: _addActivity,
            )
          : ListView(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildFilterChips(),
                ),
                
                // Stats summary
                _buildHistoryStats(),
                
                // Activities grouped by month
                ..._buildActivitiesByMonth(),
              ],
            ),
    );
  }

  Widget _buildTodayStats() {
    // Calculate today's stats
    int totalDuration = 0;
    int totalCalories = 0;
    double totalDistance = 0;
    
    for (var activity in _recentActivities) {
      totalDuration += activity.duration;
      totalCalories += activity.caloriesBurned;
      totalDistance += activity.distance ?? 0;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(Icons.timer, '$totalDuration', 'minutes'),
          _buildStatColumn(Icons.local_fire_department, '$totalCalories', 'calories'),
          _buildStatColumn(Icons.directions_run, '${totalDistance.toStringAsFixed(1)}', 'km'),
        ],
      ),
    );
  }

  Widget _buildHistoryStats() {
    // Calculate overall stats
    int totalActivities = _filteredActivities.length;
    int totalDuration = 0;
    int totalCalories = 0;
    
    for (var activity in _filteredActivities) {
      totalDuration += activity.duration;
      totalCalories += activity.caloriesBurned;
    }
    
    // Calculate average duration per activity
    double avgDuration = totalActivities > 0 
        ? totalDuration / totalActivities 
        : 0;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SectionCard(
        title: 'Activity Summary',
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                Icons.event_available, 
                '$totalActivities', 
                'workouts'
              ),
              _buildStatColumn(
                Icons.timer, 
                '${avgDuration.toStringAsFixed(0)}', 
                'avg min'
              ),
              _buildStatColumn(
                Icons.local_fire_department, 
                '$totalCalories', 
                'calories'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: _selectedFilter == 'all',
          onSelected: (selected) => _filterActivities('all'),
        ),
        ...ActivityTypes.all.map((type) => FilterChip(
          label: Text(ActivityTypes.getDisplayName(type)),
          selected: _selectedFilter == type,
          onSelected: (selected) => _filterActivities(type),
          avatar: Icon(
            ActivityTypes.getIconForType(type),
            size: 16,
            color: _selectedFilter == type ? Colors.white : AppColors.primary,
          ),
        )),
      ],
    );
  }

  List<Widget> _buildActivitiesByMonth() {
    if (_filteredActivities.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No activities match the selected filter.',
              style: AppTextStyles.body,
            ),
          ),
        ),
      ];
    }
    
    // Group activities by month
    Map<String, List<ActivityModel>> activitiesByMonth = {};
    
    for (var activity in _filteredActivities) {
      final monthKey = DateFormat('MMMM yyyy').format(activity.date);
      if (!activitiesByMonth.containsKey(monthKey)) {
        activitiesByMonth[monthKey] = [];
      }
      activitiesByMonth[monthKey]!.add(activity);
    }
    
    // Sort months (most recent first)
    final sortedMonths = activitiesByMonth.keys.toList()
      ..sort((a, b) {
        return DateFormat('MMMM yyyy').parse(b).compareTo(
          DateFormat('MMMM yyyy').parse(a)
        );
      });
    
    List<Widget> monthSections = [];
    
    for (var month in sortedMonths) {
      monthSections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            month,
            style: AppTextStyles.heading3,
          ),
        ),
      );
      
      final activitiesInMonth = activitiesByMonth[month]!;
      
      // Sort activities by date (most recent first)
      activitiesInMonth.sort((a, b) => b.date.compareTo(a.date));
      
      for (var activity in activitiesInMonth) {
        monthSections.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildActivityCard(activity),
          ),
        );
      }
    }
    
    return monthSections;
  }

  Widget _buildActivityCard(ActivityModel activity) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _showActivityDetails(activity),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ActivityTypes.getColorForType(activity.type).withOpacity(0.2),
                    child: Icon(
                      ActivityTypes.getIconForType(activity.type),
                      color: ActivityTypes.getColorForType(activity.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: AppTextStyles.heading4,
                        ),
                        Text(
                          '${ActivityTypes.getDisplayName(activity.type)} • ${DateFormat.jm().format(activity.date)}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActivityStat(Icons.timer, '${activity.duration} min'),
                  _buildActivityStat(
                    Icons.local_fire_department, 
                    '${activity.caloriesBurned} cal'
                  ),
                  if (activity.distance != null)
                    _buildActivityStat(
                      Icons.straight, 
                      '${activity.distance!.toStringAsFixed(1)} km'
                    ),
                  if (activity.steps != null)
                    _buildActivityStat(
                      Icons.directions_walk, 
                      '${activity.steps} steps'
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  void _showActivityDetails(ActivityModel activity) {
    // In a real app, we would navigate to a detail screen
    // For now, show a bottom sheet with activity details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and icon
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: ActivityTypes.getColorForType(activity.type).withOpacity(0.2),
                      child: Icon(
                        ActivityTypes.getIconForType(activity.type),
                        color: ActivityTypes.getColorForType(activity.type),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: AppTextStyles.heading2,
                          ),
                          Text(
                            ActivityTypes.getDisplayName(activity.type),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date and time
                Row(
                  children: [
                    const Icon(Icons.event, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMd().format(activity.date),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.jm().format(activity.date),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDetailStat('Duration', '${activity.duration} min', Icons.timer),
                    _buildDetailStat('Calories', '${activity.caloriesBurned} cal', Icons.local_fire_department),
                    if (activity.distance != null)
                      _buildDetailStat('Distance', '${activity.distance!.toStringAsFixed(2)} km', Icons.straighten),
                    if (activity.steps != null)
                      _buildDetailStat('Steps', '${activity.steps}', Icons.directions_walk),
                    if (activity.distance != null && activity.duration > 0)
                      _buildDetailStat(
                        'Pace', 
                        activity.getPace() ?? '--', 
                        Icons.speed
                      ),
                    _buildDetailStat(
                      'Intensity', 
                      '${(activity.caloriesBurned / activity.duration).toStringAsFixed(1)} cal/min', 
                      Icons.trending_up
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Notes
                if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                  Text('Notes', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text(activity.notes!, style: AppTextStyles.body),
                  const SizedBox(height: 24),
                ],
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Edit activity
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Delete activity
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Activities'),
        content: Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedFilter == 'all',
              onSelected: (selected) {
                _filterActivities('all');
                Navigator.pop(context);
              },
            ),
            ...ActivityTypes.all.map((type) => FilterChip(
              label: Text(ActivityTypes.getDisplayName(type)),
              selected: _selectedFilter == type,
              onSelected: (selected) {
                _filterActivities(type);
                Navigator.pop(context);
              },
              avatar: Icon(
                ActivityTypes.getIconForType(type),
                size: 16,
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}