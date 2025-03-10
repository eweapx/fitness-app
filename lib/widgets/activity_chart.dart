import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// A widget that displays activity data in a bar chart
class ActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> activityData;
  final bool showTotal;
  final bool showLegend;
  final String title;

  const ActivityChart({
    Key? key,
    required this.activityData,
    this.showTotal = true,
    this.showLegend = true,
    this.title = 'Activity Summary',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    int totalCalories = 0;
    int totalMinutes = 0;
    Map<String, int> activityTypes = {};

    for (final activity in activityData) {
      final int calories = activity['calories'] ?? 0;
      final int duration = activity['duration'] ?? 0;
      final String type = activity['type'] ?? 'Other';

      totalCalories += calories;
      totalMinutes += duration;
      
      if (activityTypes.containsKey(type)) {
        activityTypes[type] = activityTypes[type]! + calories;
      } else {
        activityTypes[type] = calories;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        if (showTotal && activityData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryItem(
                  icon: Icons.local_fire_department,
                  value: '$totalCalories',
                  label: 'Total Calories',
                  color: Colors.orange,
                ),
                _SummaryItem(
                  icon: Icons.timer,
                  value: '${totalMinutes}m',
                  label: 'Total Minutes',
                  color: Colors.blue,
                ),
                _SummaryItem(
                  icon: Icons.fitness_center,
                  value: '${activityData.length}',
                  label: 'Activities',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        
        if (activityData.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No activity data available.\nLog your workouts to see them here!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(activityData),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final activity = activityData[groupIndex];
                        final date = DateTime.fromMillisecondsSinceEpoch(
                            activity['timestamp'] ?? 0);
                        return BarTooltipItem(
                          '${activity['type']}\n${DateFormat.MMMd().format(date)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${activity['calories']} cal · ${activity['duration']} min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
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
                          if (value >= activityData.length || value < 0) {
                            return const SizedBox.shrink();
                          }
                          final activity = activityData[value.toInt()];
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              activity['timestamp'] ?? 0);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat.Md().format(date),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      left: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  barGroups: _getBarGroups(activityData),
                ),
              ),
            ),
          ),
          
        if (showLegend && activityTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: activityTypes.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _getColorForActivity(entry.key),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key}: ${entry.value} cal',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  List<BarChartGroupData> _getBarGroups(List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final activity = entry.value;
      final int calories = activity['calories'] ?? 0;
      final String type = activity['type'] ?? 'Other';
      final bool isAuto = activity['auto'] ?? false;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: calories.toDouble(),
            color: _getColorForActivity(type),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxValue(data),
              color: Colors.grey.shade200,
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxValue(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 500;
    
    double maxCalories = 0;
    for (final activity in data) {
      final int calories = activity['calories'] ?? 0;
      if (calories > maxCalories) {
        maxCalories = calories.toDouble();
      }
    }
    
    // Add some padding at the top
    return (maxCalories * 1.2).roundToDouble();
  }

  Color _getColorForActivity(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
      case 'jogging':
        return Colors.red;
      case 'cycling':
        return Colors.blue;
      case 'swimming':
        return Colors.lightBlue;
      case 'walking':
        return Colors.green;
      case 'hiking':
        return Colors.brown;
      case 'yoga':
        return Colors.purple;
      case 'workout':
      case 'training':
      case 'weights':
      case 'lifting':
      case 'gym':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}