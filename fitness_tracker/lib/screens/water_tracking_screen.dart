import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  _WaterTrackingScreenState createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  
  // Water tracking data
  int _waterGoal = 2000; // ml
  int _waterIntake = 0; // ml
  List<WaterEntry> _waterEntries = [];
  
  // Predefined water amounts
  final List<int> _quickAddAmounts = [50, 100, 200, 250, 500, 750];
  
  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Get user profile to fetch water goal
      final userProfile = await _firebaseService.getUserProfile(demoUserId);
      if (userProfile != null && userProfile.goals != null) {
        if (userProfile.goals!.containsKey('dailyWater')) {
          _waterGoal = userProfile.goals!['dailyWater'];
        }
      }
      
      // Load water entries for the selected date
      final prefs = await SharedPreferences.getInstance();
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final entriesJson = prefs.getStringList('water_entries_$dateString') ?? [];
      
      _waterEntries = entriesJson
          .map((json) => WaterEntry.fromJson(json))
          .toList();
      
      // Calculate total water intake
      _waterIntake = _waterEntries.fold(
        0, 
        (sum, entry) => sum + entry.amount,
      );
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading water data: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading water data: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveWaterEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final entriesJson = _waterEntries
          .map((entry) => entry.toJson())
          .toList();
      
      await prefs.setStringList('water_entries_$dateString', entriesJson);
      
      // Update user's water goal if changed
      if (userGoalChanged) {
        const String demoUserId = 'demo_user';
        await _firebaseService.setUserGoals(demoUserId, {
          'dailyWater': _waterGoal,
        });
      }
    } catch (e) {
      print('Error saving water entries: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving water data: ${e.toString()}')),
      );
    }
  }

  void _addWaterEntry(int amount) {
    final newEntry = WaterEntry(
      amount: amount,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _waterEntries.add(newEntry);
      _waterIntake += amount;
    });
    
    _saveWaterEntries();
  }

  void _removeWaterEntry(int index) {
    final entry = _waterEntries[index];
    
    setState(() {
      _waterEntries.removeAt(index);
      _waterIntake -= entry.amount;
    });
    
    _saveWaterEntries();
  }
  
  void _updateWaterGoal(int newGoal) {
    setState(() {
      _waterGoal = newGoal;
      userGoalChanged = true;
    });
    
    _saveWaterEntries();
  }
  
  void _showCustomAmountDialog() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Amount'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (ml)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(textController.text);
              if (amount != null && amount > 0) {
                _addWaterEntry(amount);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  bool userGoalChanged = false;
  
  void _showUpdateGoalDialog() {
    final textController = TextEditingController(text: _waterGoal.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Water Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Goal (ml)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommended: 2000-3000 ml per day',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final goal = int.tryParse(textController.text);
              if (goal != null && goal > 0) {
                _updateWaterGoal(goal);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _loadWaterData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showUpdateGoalDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading water data...')
          : _buildWaterTrackingContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCustomAmountDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWaterTrackingContent() {
    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DateSelector(
            selectedDate: _selectedDate,
            onDateSelected: _onDateChanged,
          ),
        ),
        
        // Water intake progress
        _buildWaterProgress(),
        
        // Quick add buttons
        _buildQuickAddSection(),
        
        // Water entries list
        Expanded(
          child: _buildWaterEntriesList(),
        ),
      ],
    );
  }

  Widget _buildWaterProgress() {
    final percentageComplete = _waterIntake / _waterGoal;
    final formattedPercentage = (percentageComplete * 100).toInt();
    final remaining = _waterGoal - _waterIntake;
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Intake',
                      style: AppTextStyles.heading3,
                    ),
                    Text(
                      '$_waterIntake / $_waterGoal ml',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                CircularPercentIndicator(
                  percent: percentageComplete > 1.0 ? 1.0 : percentageComplete,
                  radius: 40,
                  lineWidth: 10,
                  centerText: '$formattedPercentage%',
                  label: 'Complete',
                  color: percentageComplete >= 1.0 
                      ? AppColors.success 
                      : AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentageComplete > 1.0 ? 1.0 : percentageComplete,
              minHeight: 20,
              backgroundColor: Colors.blue[100],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentageComplete >= 1.0 
                    ? AppColors.success 
                    : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Text(
              remaining > 0
                  ? 'You need to drink $remaining ml more today'
                  : 'You reached your daily goal! 🎉',
              style: AppTextStyles.caption.copyWith(
                color: remaining > 0 ? AppColors.textSecondary : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Quick Add',
            style: AppTextStyles.heading4,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickAddAmounts.map((amount) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ActionChip(
                    avatar: const Icon(
                      Icons.water_drop,
                      color: Colors.blue,
                      size: 18,
                    ),
                    label: Text('$amount ml'),
                    onPressed: () => _addWaterEntry(amount),
                    backgroundColor: Colors.blue[50],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildWaterEntriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Today\'s Entries',
            style: AppTextStyles.heading4,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _waterEntries.isEmpty
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.water_drop,
                    message: 'No water entries for today.\nTap the + button to add your first glass.',
                    actionLabel: 'Add Water',
                    onAction: _showCustomAmountDialog,
                  ),
                )
              : ListView.builder(
                  itemCount: _waterEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _waterEntries[_waterEntries.length - 1 - index];
                    final time = DateFormat.jm().format(entry.timestamp);
                    
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.water_drop,
                          color: Colors.white,
                        ),
                      ),
                      title: Text('${entry.amount} ml'),
                      subtitle: Text('Added at $time'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeWaterEntry(_waterEntries.length - 1 - index),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class WaterEntry {
  final int amount; // in ml
  final DateTime timestamp;
  
  WaterEntry({
    required this.amount,
    required this.timestamp,
  });
  
  factory WaterEntry.fromJson(String json) {
    final parts = json.split('|');
    return WaterEntry(
      amount: int.parse(parts[0]),
      timestamp: DateTime.parse(parts[1]),
    );
  }
  
  String toJson() {
    return '$amount|${timestamp.toIso8601String()}';
  }
}