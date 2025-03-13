import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/sleep_model.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  _SleepTrackingScreenState createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<SleepEntry> _sleepEntries = [];
  List<FlSpot> _sleepData = [];
  List<FlSpot> _qualityData = [];
  DateTime _selectedDate = DateTime.now();
  
  // Sleep factors
  final List<String> _sleepFactors = [
    'Caffeine',
    'Late Meal',
    'Screen Time',
    'Exercise',
    'Stress',
    'Alcohol',
    'Late Work',
  ];
  
  Map<String, bool> _selectedFactors = {};
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 0); // 6:00 AM
  double _sleepQuality = 3; // 1-5 scale
  String _sleepNotes = '';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize selected factors
    for (final factor in _sleepFactors) {
      _selectedFactors[factor] = false;
    }
    
    _loadSleepData();
  }
  
  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Calculate date range (past 7 days)
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      // Get sleep entries from Firebase
      final entries = await _firebaseService.getSleepEntriesForDateRange(
        demoUserId,
        sevenDaysAgo,
        now,
      );
      
      setState(() {
        _sleepEntries = entries;
        
        // Process sleep data for chart
        _sleepData = _processSleepDurationData(entries);
        _qualityData = _processSleepQualityData(entries);
        
        // Check if there's an entry for today
        final today = DateFormat('yyyy-MM-dd').format(now);
        final todayEntry = entries.where((entry) => 
          DateFormat('yyyy-MM-dd').format(entry.date) == today
        ).toList();
        
        if (todayEntry.isNotEmpty) {
          // Pre-fill form with today's data
          final entry = todayEntry.first;
          _bedTime = TimeOfDay(
            hour: entry.bedTime.hour,
            minute: entry.bedTime.minute,
          );
          _wakeTime = TimeOfDay(
            hour: entry.wakeTime.hour,
            minute: entry.wakeTime.minute,
          );
          _sleepQuality = entry.quality.toDouble();
          _sleepNotes = entry.notes;
          
          for (final factor in entry.factors) {
            if (_selectedFactors.containsKey(factor)) {
              _selectedFactors[factor] = true;
            }
          }
        }
        
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
  
  List<FlSpot> _processSleepDurationData(List<SleepEntry> entries) {
    // Sort entries by date
    entries.sort((a, b) => a.date.compareTo(b.date));
    
    // Limit to the last 7 days
    if (entries.length > 7) {
      entries = entries.sublist(entries.length - 7);
    }
    
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      
      // Calculate sleep duration in hours (with decimal)
      final bedTime = entry.bedTime;
      final wakeTime = entry.wakeTime;
      
      DateTime bedDateTime = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
        bedTime.hour,
        bedTime.minute,
      );
      
      DateTime wakeDateTime = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
        wakeTime.hour,
        wakeTime.minute,
      );
      
      // If wake time is earlier than bed time, it's the next day
      if (wakeDateTime.isBefore(bedDateTime)) {
        wakeDateTime = wakeDateTime.add(const Duration(days: 1));
      }
      
      final durationMinutes = wakeDateTime.difference(bedDateTime).inMinutes;
      final durationHours = durationMinutes / 60;
      
      return FlSpot(index.toDouble(), durationHours);
    });
  }
  
  List<FlSpot> _processSleepQualityData(List<SleepEntry> entries) {
    // Sort entries by date
    entries.sort((a, b) => a.date.compareTo(b.date));
    
    // Limit to the last 7 days
    if (entries.length > 7) {
      entries = entries.sublist(entries.length - 7);
    }
    
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return FlSpot(index.toDouble(), entry.quality.toDouble());
    });
  }
  
  Future<void> _selectBedTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _bedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.blueGrey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() => _bedTime = pickedTime);
    }
  }
  
  Future<void> _selectWakeTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.blueGrey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() => _wakeTime = pickedTime);
    }
  }
  
  Future<void> _saveSleepEntry() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Convert TimeOfDay to DateTime
      final now = DateTime.now();
      final bedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _bedTime.hour,
        _bedTime.minute,
      );
      
      final wakeDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _wakeTime.hour,
        _wakeTime.minute,
      );
      
      // If wake time is earlier than bed time, it's the next day
      DateTime adjustedWakeDateTime = wakeDateTime;
      if (wakeDateTime.isBefore(bedDateTime)) {
        adjustedWakeDateTime = wakeDateTime.add(const Duration(days: 1));
      }
      
      // Calculate duration in minutes
      final durationMinutes = adjustedWakeDateTime.difference(bedDateTime).inMinutes;
      
      // Get selected factors
      final selectedFactors = _selectedFactors.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      // Check if there's already an entry for today
      final today = DateFormat('yyyy-MM-dd').format(now);
      final todayEntry = _sleepEntries.where((entry) => 
        DateFormat('yyyy-MM-dd').format(entry.date) == today
      ).toList();
      
      SleepEntry sleepEntry;
      if (todayEntry.isNotEmpty) {
        // Update existing entry
        sleepEntry = SleepEntry(
          id: todayEntry.first.id,
          userId: demoUserId,
          date: now,
          bedTime: _bedTime,
          wakeTime: _wakeTime,
          duration: durationMinutes,
          quality: _sleepQuality.round(),
          factors: selectedFactors,
          notes: _sleepNotes,
        );
        
        await _firebaseService.updateSleepEntry(sleepEntry);
      } else {
        // Create new entry
        sleepEntry = SleepEntry(
          id: null,
          userId: demoUserId,
          date: now,
          bedTime: _bedTime,
          wakeTime: _wakeTime,
          duration: durationMinutes,
          quality: _sleepQuality.round(),
          factors: selectedFactors,
          notes: _sleepNotes,
        );
        
        await _firebaseService.addSleepEntry(sleepEntry);
      }
      
      // Reload sleep data
      await _loadSleepData();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep entry saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving sleep entry: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sleep entry: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteSleepEntry() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sleep Entry'),
        content: const Text('Are you sure you want to delete today\'s sleep entry?'),
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
        // Check if there's an entry for today
        final now = DateTime.now();
        final today = DateFormat('yyyy-MM-dd').format(now);
        final todayEntry = _sleepEntries.where((entry) => 
          DateFormat('yyyy-MM-dd').format(entry.date) == today
        ).toList();
        
        if (todayEntry.isNotEmpty) {
          // Delete the entry
          await _firebaseService.deleteSleepEntry(todayEntry.first.id!);
          
          // Reset form
          setState(() {
            _bedTime = const TimeOfDay(hour: 22, minute: 0);
            _wakeTime = const TimeOfDay(hour: 6, minute: 0);
            _sleepQuality = 3;
            _sleepNotes = '';
            for (final factor in _sleepFactors) {
              _selectedFactors[factor] = false;
            }
          });
          
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
        } else {
          setState(() => _isLoading = false);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No sleep entry found for today')),
            );
          }
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSleepEntry,
            tooltip: 'Delete Entry',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading sleep data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSleepChart(),
                  const SizedBox(height: 24),
                  _buildSleepForm(),
                  const SizedBox(height: 24),
                  _buildFactors(),
                  const SizedBox(height: 16),
                  _buildNotesField(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Save Sleep Entry',
                      icon: Icons.save,
                      onPressed: _saveSleepEntry,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSleepChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sleep Overview',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _sleepData.isEmpty
                  ? const Center(
                      child: Text('No sleep data available yet'),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1,
                          verticalInterval: 1,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < _sleepEntries.length) {
                                  final entry = _sleepEntries[value.toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('E').format(entry.date),
                                      style: AppTextStyles.caption,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}h',
                                  style: AppTextStyles.caption,
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        minX: 0,
                        maxX: _sleepData.length - 1.0,
                        minY: 0,
                        maxY: 12, // Max 12 hours
                        lineBarsData: [
                          LineChartBarData(
                            spots: _sleepData,
                            isCurved: true,
                            color: Colors.indigo,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.indigo.withOpacity(0.2),
                            ),
                          ),
                          LineChartBarData(
                            spots: _qualityData.map((spot) => 
                              FlSpot(spot.x, spot.y * 1.5) // Scale quality (1-5) to show on same chart
                            ).toList(),
                            isCurved: true,
                            color: Colors.amber,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Sleep Duration', Colors.indigo),
                const SizedBox(width: 16),
                _buildLegendItem('Sleep Quality', Colors.amber),
              ],
            ),
            if (_sleepData.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildSleepInsights(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
  
  Widget _buildSleepInsights() {
    // Calculate average sleep duration
    final totalDuration = _sleepData.fold<double>(
      0, (sum, item) => sum + item.y);
    final avgDuration = totalDuration / _sleepData.length;
    
    // Calculate average sleep quality
    final totalQuality = _qualityData.fold<double>(
      0, (sum, item) => sum + item.y);
    final avgQuality = totalQuality / _qualityData.length;
    
    // Determine if duration is good
    String durationInsight;
    Color durationColor;
    if (avgDuration >= 7 && avgDuration <= 9) {
      durationInsight = 'Optimal sleep duration (7-9 hours)';
      durationColor = Colors.green;
    } else if (avgDuration < 7) {
      durationInsight = 'Below recommended sleep duration';
      durationColor = Colors.red;
    } else {
      durationInsight = 'Above recommended sleep duration';
      durationColor = Colors.orange;
    }
    
    // Determine if quality is good
    String qualityInsight;
    Color qualityColor;
    if (avgQuality >= 4) {
      qualityInsight = 'Excellent sleep quality';
      qualityColor = Colors.green;
    } else if (avgQuality >= 3) {
      qualityInsight = 'Good sleep quality';
      qualityColor = Colors.green.shade700;
    } else if (avgQuality >= 2) {
      qualityInsight = 'Fair sleep quality';
      qualityColor = Colors.orange;
    } else {
      qualityInsight = 'Poor sleep quality';
      qualityColor = Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sleep Insights',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.science, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'Avg. Duration: ',
                  style: AppTextStyles.body.copyWith(color: Colors.black87),
                  children: [
                    TextSpan(
                      text: '${avgDuration.toStringAsFixed(1)} hours',
                      style: TextStyle(fontWeight: FontWeight.bold, color: durationColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.tips_and_updates, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                durationInsight,
                style: TextStyle(color: durationColor, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'Avg. Quality: ',
                  style: AppTextStyles.body.copyWith(color: Colors.black87),
                  children: [
                    TextSpan(
                      text: '${avgQuality.toStringAsFixed(1)} / 5',
                      style: TextStyle(fontWeight: FontWeight.bold, color: qualityColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.tips_and_updates, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                qualityInsight,
                style: TextStyle(color: qualityColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSleepForm() {
    // Calculate sleep duration
    final now = DateTime.now();
    final bedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _bedTime.hour,
      _bedTime.minute,
    );
    
    final wakeDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _wakeTime.hour,
      _wakeTime.minute,
    );
    
    // If wake time is earlier than bed time, it's the next day
    DateTime adjustedWakeDateTime = wakeDateTime;
    if (wakeDateTime.isBefore(bedDateTime)) {
      adjustedWakeDateTime = wakeDateTime.add(const Duration(days: 1));
    }
    
    final durationMinutes = adjustedWakeDateTime.difference(bedDateTime).inMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log Your Sleep',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTimeField(
                    'Bed Time',
                    Icons.bedtime,
                    '${_bedTime.hour}:${_bedTime.minute.toString().padLeft(2, '0')}',
                    _selectBedTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildTimeField(
                    'Wake Time',
                    Icons.wb_sunny,
                    '${_wakeTime.hour}:${_wakeTime.minute.toString().padLeft(2, '0')}',
                    _selectWakeTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildInfoField(
                    'Sleep Duration',
                    Icons.timelapse,
                    '$hours hr ${minutes.toString().padLeft(2, '0')} min',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sleep Quality',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red),
                Expanded(
                  child: Slider(
                    value: _sleepQuality,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _getSleepQualityLabel(_sleepQuality.round()),
                    onChanged: (value) {
                      setState(() => _sleepQuality = value);
                    },
                  ),
                ),
                const Icon(Icons.sentiment_very_satisfied, color: Colors.green),
              ],
            ),
            Center(
              child: Text(
                _getSleepQualityLabel(_sleepQuality.round()),
                style: AppTextStyles.caption.copyWith(
                  color: _getSleepQualityColor(_sleepQuality.round()),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeField(
    String label,
    IconData icon,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoField(
    String label,
    IconData icon,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getSleepQualityLabel(int quality) {
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
        return 'Fair';
    }
  }
  
  Color _getSleepQualityColor(int quality) {
    switch (quality) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.amber;
    }
  }
  
  Widget _buildFactors() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'External Factors',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select factors that may have affected your sleep:',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sleepFactors.map((factor) {
                final isSelected = _selectedFactors[factor] ?? false;
                return FilterChip(
                  label: Text(factor),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFactors[factor] = selected;
                    });
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesField() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add any notes about your sleep (optional)',
                border: OutlineInputBorder(),
              ),
              value: _sleepNotes,
              onChanged: (value) {
                setState(() => _sleepNotes = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}