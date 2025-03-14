import 'package:flutter/material.dart';

class ActivityTabScreen extends StatelessWidget {
  const ActivityTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity summary card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "This Week's Activity",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Activity metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActivityMetric(
                          context,
                          Icons.directions_walk,
                          '47,352',
                          'Steps',
                        ),
                        _buildActivityMetric(
                          context,
                          Icons.track_changes,
                          '26.4',
                          'km',
                        ),
                        _buildActivityMetric(
                          context,
                          Icons.local_fire_department,
                          '1,875',
                          'Calories',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Weekly chart placeholder
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Weekly Activity Chart',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Recent activities heading
            Text(
              'Recent Activities',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Recent activities list
            _buildActivityItem(
              context,
              'Morning Run',
              'Today, 6:30 AM',
              '5.4 km • 32 min • 320 cal',
              Icons.directions_run,
            ),
            _buildActivityItem(
              context,
              'Strength Training',
              'Yesterday, 5:45 PM',
              '45 min • 280 cal',
              Icons.fitness_center,
            ),
            _buildActivityItem(
              context,
              'Cycling',
              'Wednesday, 7:15 AM',
              '12.3 km • 42 min • 350 cal',
              Icons.pedal_bike,
            ),
            _buildActivityItem(
              context,
              'Evening Walk',
              'Tuesday, 6:30 PM',
              '3.2 km • 35 min • 180 cal',
              Icons.directions_walk,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityMetric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String date,
    String details,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Activity icon
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            
            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}