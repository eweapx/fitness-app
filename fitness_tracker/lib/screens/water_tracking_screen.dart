import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/hydration_model.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'dart:math' as math;

class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  _WaterTrackingScreenState createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  int _waterConsumed = 0; // in milliliters
  int _waterGoal = 2000; // default goal: 2000ml (2L)
  late AnimationController _waveController;
  List<HydrationEntry> _recentEntries = [];
  
  // Default water amounts
  final List<int> _quickAddAmounts = [100, 250, 500, 750];
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _loadWaterData();
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }
  
  Future<void> _loadWaterData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load from SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      _waterConsumed = prefs.getInt('water_consumed_today') ?? 0;
      _waterGoal = prefs.getInt('water_goal') ?? 2000;
      
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Attempt to load from Firebase for persistence across devices
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      try {
        final hydrationData = await _firebaseService.getHydrationByDate(
          demoUserId, 
          startOfDay,
        );
        
        if (hydrationData != null) {
          // Use Firebase data if available
          _waterConsumed = hydrationData.totalAmount;
          
          // Save to SharedPreferences for faster access next time
          await prefs.setInt('water_consumed_today', _waterConsumed);
        }
        
        // Get user profile for goal
        final userProfile = await _firebaseService.getUserProfile(demoUserId);
        if (userProfile != null && userProfile.goals != null) {
          if (userProfile.goals!.containsKey('dailyWater')) {
            _waterGoal = userProfile.goals!['dailyWater'];
            await prefs.setInt('water_goal', _waterGoal);
          }
        }
        
        // Get recent entries
        final recentEntries = await _firebaseService.getRecentHydrationEntries(
          demoUserId,
          5, // Get last 5 entries
        );
        _recentEntries = recentEntries;
      } catch (e) {
        print('Error loading from Firebase: $e');
        // Continue with SharedPreferences data
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading water data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addWater(int amount) async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Update local state
      setState(() => _waterConsumed += amount);
      
      // Save to SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('water_consumed_today', _waterConsumed);
      
      // Save to Firebase for persistence
      final entry = HydrationEntry(
        id: null, // Firebase will generate an ID
        userId: demoUserId,
        amount: amount,
        date: DateTime.now(),
        type: 'Water', // Could be 'Water', 'Coffee', 'Tea', etc.
      );
      
      await _firebaseService.addHydrationEntry(entry);
      
      // Update recent entries
      final recentEntries = await _firebaseService.getRecentHydrationEntries(
        demoUserId,
        5, // Get last 5 entries
      );
      setState(() => _recentEntries = recentEntries);
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${amount}ml of water')),
      );
    } catch (e) {
      print('Error adding water: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding water: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _setWaterGoal() async {
    // Show dialog to set water goal
    final goalController = TextEditingController(text: _waterGoal.toString());
    
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Water Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Goal (ml)',
                border: OutlineInputBorder(),
                hintText: 'Enter your daily water goal',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommended: 2000-3000ml per day',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(goalController.text);
              if (goal != null && goal > 0) {
                Navigator.of(context).pop(goal);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid goal')),
                );
              }
            },
            child: const Text('Set Goal'),
          ),
        ],
      ),
    );
    
    if (newGoal != null) {
      setState(() => _waterGoal = newGoal);
      
      try {
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('water_goal', newGoal);
        
        // Save to Firebase
        const String demoUserId = 'demo_user';
        await _firebaseService.updateUserGoal(demoUserId, 'dailyWater', newGoal);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Water goal updated')),
        );
      } catch (e) {
        print('Error updating water goal: $e');
      }
    }
  }
  
  Future<void> _resetWaterCounter() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Water Counter'),
        content: const Text('Are you sure you want to reset your water counter for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _waterConsumed = 0);
      
      try {
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('water_consumed_today', 0);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Water counter reset')),
        );
      } catch (e) {
        print('Error resetting water counter: $e');
      }
    }
  }
  
  Future<void> _addCustomAmount() async {
    // Show dialog to add custom amount
    final amountController = TextEditingController();
    
    final customAmount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Amount'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (ml)',
            border: OutlineInputBorder(),
            hintText: 'Enter water amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.of(context).pop(amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (customAmount != null) {
      _addWater(customAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _setWaterGoal,
            tooltip: 'Set Water Goal',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading water data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWaterProgressView(),
                  const SizedBox(height: 24),
                  _buildQuickAddButtons(),
                  const SizedBox(height: 24),
                  _buildRecentEntriesView(),
                  const SizedBox(height: 24),
                  _buildHydrationTipsView(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildWaterProgressView() {
    final percentComplete = _waterConsumed / _waterGoal;
    final formattedPercentage = (percentComplete * 100).toInt();
    
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
                        'Today\'s Hydration',
                        style: AppTextStyles.heading3,
                      ),
                      Text(
                        '$_waterConsumed / $_waterGoal ml',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'reset') {
                      _resetWaterCounter();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'reset',
                      child: Text('Reset Counter'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: WaterPainter(
                        percentFull: percentComplete > 1.0 ? 1.0 : percentComplete,
                        animationValue: _waveController.value,
                      ),
                      child: Container(
                        height: 200,
                        width: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$formattedPercentage%',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'of daily goal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickAddButtons() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Add',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _quickAddAmounts.map((amount) {
                return _buildQuickAddButton(amount);
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Add Custom Amount',
                icon: Icons.add,
                onPressed: _addCustomAmount,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickAddButton(int amount) {
    return Column(
      children: [
        InkWell(
          onTap: () => _addWater(amount),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/water_drop.png',
                    height: 32,
                    width: 32,
                    color: AppColors.primary,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.water_drop,
                        size: 32,
                        color: AppColors.primary,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$amount ml',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getContainerLabel(amount),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
  
  String _getContainerLabel(int amount) {
    if (amount <= 100) return 'Small Glass';
    if (amount <= 250) return 'Glass';
    if (amount <= 500) return 'Large Glass';
    return 'Bottle';
  }
  
  Widget _buildRecentEntriesView() {
    if (_recentEntries.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Entries',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            ..._recentEntries.map((entry) {
              final timeString = _formatDateTime(entry.date);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.water_drop,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.amount} ml',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    Text(
                      timeString,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    
    if (entryDate == today) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
  
  Widget _buildHydrationTipsView() {
    final tips = [
      'Drink a glass of water when you wake up to kickstart your metabolism.',
      'Carry a reusable water bottle with you during the day.',
      'Set reminders on your phone to drink water regularly.',
      'Drink water before, during, and after physical activity.',
      'Add natural flavors like lemon or cucumber to make water more appealing.',
    ];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hydration Tips',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the water animation
class WaterPainter extends CustomPainter {
  final double percentFull;
  final double animationValue;
  
  WaterPainter({
    required this.percentFull,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final containerWidth = size.width;
    final containerHeight = size.height;
    
    // Draw the container circle
    final containerPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(containerWidth / 2, containerHeight / 2),
      containerWidth / 2,
      containerPaint,
    );
    
    // Clip to the container circle
    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(Rect.fromCircle(
          center: Offset(containerWidth / 2, containerHeight / 2),
          radius: containerWidth / 2,
        )),
    );
    
    // Calculate water level
    final waterHeight = containerHeight * (1 - percentFull);
    
    // Draw water
    final waterPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Starting point for the wave
    path.moveTo(0, waterHeight);
    
    // Draw the wave
    for (double i = 0; i <= containerWidth; i++) {
      final waveHeight = 10.0; // Height of the wave
      final frequency = 0.05; // Frequency of the wave
      final offset = animationValue * 2 * math.pi; // Offset based on animation
      
      final y = waterHeight + math.sin((i * frequency) + offset) * waveHeight;
      path.lineTo(i, y);
    }
    
    // Complete the path
    path.lineTo(containerWidth, containerHeight);
    path.lineTo(0, containerHeight);
    path.close();
    
    canvas.drawPath(path, waterPaint);
    
    // Restore canvas
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) {
    return oldDelegate.percentFull != percentFull || 
           oldDelegate.animationValue != animationValue;
  }
}