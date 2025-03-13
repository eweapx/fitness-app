import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  _SleepTrackingScreenState createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _sleepEntries = [];
  List<Map<String, dynamic>> _weeklyEntries = [];
  late TabController _tabController;
  
  // Sleep stats
  int _totalSleepMinutes = 0;
  int _avgQualityScore = 0;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  DateTime _bedtime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _wakeupTime = DateTime.now();
  double _qualityScore = 3.0;
  final _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSleepData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Get sleep entries for the selected date
      final entries = await _firebaseService.getSleepEntriesForDate(
        userId,
        _selectedDate,
      );
      
      // Get weekly sleep data for chart
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final weeklyEntries = await _firebaseService.getSleepEntriesForDateRange(
        userId,
        weekStart,
        weekEnd,
      );
      
      // Calculate stats
      int totalMinutes = 0;
      int totalQuality = 0;
      
      for (final entry in entries) {
        final duration = entry['durationMinutes'] as int? ?? 0;
        final quality = entry['qualityScore'] as int? ?? 0;
        
        totalMinutes += duration;
        totalQuality += quality;
      }
      
      // Calculate average quality
      final avgQuality = entries.isNotEmpty ? (totalQuality / entries.length).round() : 0;
      
      setState(() {
        _sleepEntries = entries;
        _weeklyEntries = weeklyEntries;
        _totalSleepMinutes = totalMinutes;
        _avgQualityScore = avgQuality;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sleep data: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sleep data: ${e.toString()}')),
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
      _loadSleepData();
    }
  }
  
  Future<void> _selectBedtime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_bedtime),
    );
    
    if (time != null) {
      setState(() {
        _bedtime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          time.hour,
          time.minute,
        );
        
        // If bedtime is after wakeup time, adjust wakeup time
        if (_bedtime.isAfter(_wakeupTime)) {
          _wakeupTime = _bedtime.add(const Duration(hours: 8));
        }
      });
    }
  }
  
  Future<void> _selectWakeupTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_wakeupTime),
    );
    
    if (time != null) {
      setState(() {
        _wakeupTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          time.hour,
          time.minute,
        );
        
        // If wakeup time is before bedtime, adjust bedtime
        if (_wakeupTime.isBefore(_bedtime)) {
          final nextDay = _selectedDate.add(const Duration(days: 1));
          _wakeupTime = DateTime(
            nextDay.year,
            nextDay.month,
            nextDay.day,
            time.hour,
            time.minute,
          );
        }
      });
    }
  }
  
  Future<void> _addSleepEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'demo_user';
      
      // Format date string for database queries
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Calculate sleep duration in minutes
      final Duration sleepDuration = _wakeupTime.difference(_bedtime);
      final durationMinutes = sleepDuration.inMinutes;
      
      // Create sleep entry data
      final sleepData = {
        'userId': userId,
        'date': _selectedDate,
        'dateString': dateString,
        'bedtime': _bedtime,
        'wakeupTime': _wakeupTime,
        'durationMinutes': durationMinutes,
        'qualityScore': _qualityScore.round(),
        'notes': _notesController.text,
        'createdAt': DateTime.now(),
      };
      
      // Save to Firebase
      await _firebaseService.addSleepEntry(sleepData);
      
      // Reset form
      _notesController.clear();
      
      // Reload sleep data
      await _loadSleepData();
      
      // Navigate back to the sleep log tab
      _tabController.animateTo(0);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep entry added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding sleep entry: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding sleep entry: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteSleepEntry(String entryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sleep Entry'),
        content: const Text('Are you sure you want to delete this sleep entry?'),
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
        await _firebaseService.deleteSleepEntry(entryId);
        
        // Reload sleep data
        await _loadSleepData();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sleep entry deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting sleep entry: $e');
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting sleep entry: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    return '$hours hrs ${mins > 0 ? '$mins mins' : ''}';
  }
  
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  String _getSleepQualityDescription(int quality) {
    switch (quality) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'N/A';
    }
  }
  
  Color _getSleepQualityColor(int quality) {
    switch (quality) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      case 5:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sleep Log'),
            Tab(text: 'Add Sleep'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading sleep data...')
          : TabBarView(
              controller: _tabController,
              children: [
                // Sleep Log Tab
                _buildSleepLogTab(),
                
                // Add Sleep Tab
                _buildAddSleepTab(),
              ],
            ),
    );
  }
  
  Widget _buildSleepLogTab() {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final sleepGoalMinutes = settingsProvider.sleepGoalHours * 60;
    
    // Calculate sleep goal achievement
    final goalPercentage = sleepGoalMinutes > 0 
        ? (_totalSleepMinutes / sleepGoalMinutes) 
        : 0.0;
    
    return RefreshIndicator(
      onRefresh: _loadSleepData,
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
                _loadSleepData();
              },
            ),
            const SizedBox(height: 24),
            
            // Sleep summary
            const Text(
              'Sleep Summary',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.bedtime,
                                    color: Colors.indigo,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDuration(_totalSleepMinutes),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'of ${_formatDuration(sleepGoalMinutes)} goal',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.indigo.shade50,
                          ),
                          child: Center(
                            child: Text(
                              '${(goalPercentage * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: goalPercentage.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSleepMetricCard(
                            'Quality',
                            _avgQualityScore > 0 
                                ? '${_avgQualityScore}/5' 
                                : 'N/A',
                            _avgQualityScore > 0 
                                ? _getSleepQualityDescription(_avgQualityScore) 
                                : 'No data',
                            Icons.star,
                            _getSleepQualityColor(_avgQualityScore),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSleepMetricCard(
                            'Entries',
                            '${_sleepEntries.length}',
                            _sleepEntries.length == 1 ? 'record' : 'records',
                            Icons.note_alt,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Weekly sleep chart
            if (_weeklyEntries.isNotEmpty) ...[
              const Text(
                'Weekly Sleep Chart',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildWeeklySleepChart(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Sleep entries
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sleep Entries',
                  style: AppTextStyles.heading3,
                ),
                Text(
                  '${_sleepEntries.length} ${_sleepEntries.length == 1 ? 'entry' : 'entries'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_sleepEntries.isEmpty) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bedtime,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No sleep entries logged for this day',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Add Sleep Entry',
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
                itemCount: _sleepEntries.length,
                itemBuilder: (context, index) {
                  final entry = _sleepEntries[index];
                  final entryId = entry['id'] as String;
                  final bedtime = entry['bedtime'] as DateTime;
                  final wakeupTime = entry['wakeupTime'] as DateTime;
                  final durationMinutes = entry['durationMinutes'] as int;
                  final qualityScore = entry['qualityScore'] as int;
                  final notes = entry['notes'] as String?;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.bedtime,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDuration(durationMinutes),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_formatTime(bedtime)} - ${_formatTime(wakeupTime)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSleepQualityColor(qualityScore).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getSleepQualityColor(qualityScore),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: _getSleepQualityColor(qualityScore),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$qualityScore/5',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getSleepQualityColor(qualityScore),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                tooltip: 'Delete Entry',
                                onPressed: () => _deleteSleepEntry(entryId),
                              ),
                            ],
                          ),
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
  
  Widget _buildSleepMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeeklySleepChart() {
    // Get dates for the current week
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    
    // Prepare data for chart
    final Map<String, double> sleepData = {};
    final Map<String, double> qualityData = {};
    
    // Initialize all days of the week with 0
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final key = DateFormat('E').format(date); // Day of week abbreviation
      sleepData[key] = 0;
      qualityData[key] = 0;
    }
    
    // Fill in actual data
    for (final entry in _weeklyEntries) {
      final date = entry['date'] as DateTime;
      final key = DateFormat('E').format(date);
      final duration = entry['durationMinutes'] as int;
      final quality = entry['qualityScore'] as int;
      
      // Convert to hours for better visualization
      sleepData[key] = (duration / 60);
      qualityData[key] = quality.toDouble();
    }
    
    // Sort by day of week
    final sortedKeys = sleepData.keys.toList()
      ..sort((a, b) {
        const daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return daysOrder.indexOf(a) - daysOrder.indexOf(b);
      });
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = sortedKeys[group.x.toInt()];
                return BarTooltipItem(
                  '$day\n${sleepData[day]!.toStringAsFixed(1)} hrs',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedKeys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        sortedKeys[index],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 2 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${value.toInt()} hrs',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 40,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: List.generate(sortedKeys.length, (index) {
            final day = sortedKeys[index];
            final sleepHours = sleepData[day] ?? 0;
            final quality = qualityData[day] ?? 0;
            
            // Determine bar color based on sleep quality
            Color barColor;
            if (quality > 0) {
              barColor = _getSleepQualityColor(quality.round());
            } else {
              barColor = Colors.indigo;
            }
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: sleepHours,
                  color: barColor,
                  width: 16,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          }),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 2,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          maxY: 12, // 12 hours max
        ),
      ),
    );
  }
  
  Widget _buildAddSleepTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sleep date
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMMd().format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Bedtime selector
            const Text(
              'Bedtime',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectBedtime(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bedtime,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatTime(_bedtime),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Wakeup time selector
            const Text(
              'Wakeup Time',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectWakeupTime(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alarm,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatTime(_wakeupTime),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sleep duration summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sleep Duration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDuration(_wakeupTime.difference(_bedtime).inMinutes),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Sleep quality rating
            const Text(
              'Sleep Quality',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() => _qualityScore = i.toDouble());
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i <= _qualityScore ? Icons.star : Icons.star_border,
                        size: 36,
                        color: i <= _qualityScore 
                            ? _getSleepQualityColor(i) 
                            : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getSleepQualityDescription(_qualityScore.round()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getSleepQualityColor(_qualityScore.round()),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about your sleep',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save Sleep Entry',
                icon: Icons.check,
                onPressed: _addSleepEntry,
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