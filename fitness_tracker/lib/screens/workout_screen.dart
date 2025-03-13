import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/workout_model.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'dart:async';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isWorkoutActive = false;
  String _selectedWorkoutType = 'Cardio';
  final List<String> _workoutTypes = [
    'Cardio',
    'Strength',
    'Flexibility',
    'Sports',
    'HIIT',
    'Other',
  ];
  
  // Workout timer
  int _elapsedSeconds = 0;
  Timer? _timer;
  
  // Form controllers
  final _workoutNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _workoutNameController.text = 'Quick Workout';
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _workoutNameController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _startWorkout() {
    setState(() {
      _isWorkoutActive = true;
      _elapsedSeconds = 0;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }
  
  void _pauseWorkout() {
    _timer?.cancel();
    setState(() {});
  }
  
  void _resumeWorkout() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
    setState(() {});
  }
  
  Future<void> _finishWorkout() async {
    _timer?.cancel();
    
    // Show completion dialog
    bool saveWorkout = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCompletionDialog(),
    ) ?? false;
    
    if (saveWorkout) {
      setState(() => _isLoading = true);
      
      try {
        // In a real app, we'd use the current user's ID
        const String demoUserId = 'demo_user';
        
        // Calculate calories if not provided
        int calories = 0;
        if (_caloriesController.text.isNotEmpty) {
          calories = int.tryParse(_caloriesController.text) ?? 0;
        } else {
          // Simple estimation based on workout type and duration
          calories = (_elapsedSeconds / 60).round() * 5;
        }
        
        // Create workout object
        final workout = Workout(
          id: null, // Firebase will generate an ID
          userId: demoUserId,
          name: _workoutNameController.text,
          type: _selectedWorkoutType,
          duration: _elapsedSeconds,
          caloriesBurned: calories,
          date: DateTime.now(),
          notes: _notesController.text,
        );
        
        // Save to Firebase
        await _firebaseService.addWorkout(workout);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout saved successfully!')),
        );
        
        // Reset state
        setState(() {
          _isWorkoutActive = false;
          _elapsedSeconds = 0;
          _workoutNameController.text = 'Quick Workout';
          _caloriesController.clear();
          _notesController.clear();
        });
      } catch (e) {
        print('Error saving workout: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Just reset the state without saving
      setState(() {
        _isWorkoutActive = false;
        _elapsedSeconds = 0;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracking'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Saving workout...')
          : _isWorkoutActive
              ? _buildActiveWorkoutView()
              : _buildWorkoutSetupView(),
    );
  }
  
  Widget _buildWorkoutSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout type selection
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Workout Type',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _workoutTypes.map((type) {
                      final isSelected = type == _selectedWorkoutType;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedWorkoutType = type);
                          }
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Workout name
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Name',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _workoutNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter workout name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Start button
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Workout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Press to begin tracking your workout',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick workout suggestions
          const Text(
            'Quick Start Workouts',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          _buildQuickWorkoutGrid(),
        ],
      ),
    );
  }
  
  Widget _buildQuickWorkoutGrid() {
    final quickWorkouts = [
      {'name': '30-Min HIIT', 'type': 'HIIT', 'icon': Icons.flash_on, 'color': Colors.orange},
      {'name': 'Full Body Strength', 'type': 'Strength', 'icon': Icons.fitness_center, 'color': Colors.blue},
      {'name': 'Morning Yoga', 'type': 'Flexibility', 'icon': Icons.self_improvement, 'color': Colors.purple},
      {'name': '5K Run', 'type': 'Cardio', 'icon': Icons.directions_run, 'color': Colors.green},
    ];
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: quickWorkouts.map((workout) {
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              setState(() {
                _workoutNameController.text = workout['name'] as String;
                _selectedWorkoutType = workout['type'] as String;
              });
              _startWorkout();
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    workout['icon'] as IconData,
                    color: workout['color'] as Color,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workout['name'] as String,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workout['type'] as String,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildActiveWorkoutView() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    final formattedTime = 
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    // Estimate calories burned (very simple estimate)
    final estimatedCalories = (_elapsedSeconds / 60).round() * 5;
    
    return Column(
      children: [
        // Timer display
        Expanded(
          child: Container(
            color: AppColors.primary.withOpacity(0.1),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _workoutNameController.text,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedWorkoutType,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 32),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Est. Calories: $estimatedCalories',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_timer?.isActive ?? false)
                IconButton(
                  onPressed: _pauseWorkout,
                  icon: const Icon(Icons.pause_circle_outline),
                  iconSize: 64,
                  color: AppColors.warning,
                )
              else
                IconButton(
                  onPressed: _resumeWorkout,
                  icon: const Icon(Icons.play_circle_outline),
                  iconSize: 64,
                  color: AppColors.success,
                ),
              IconButton(
                onPressed: _finishWorkout,
                icon: const Icon(Icons.stop_circle_outlined),
                iconSize: 64,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCompletionDialog() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    final formattedTime = 
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return AlertDialog(
      title: const Text('Workout Complete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: $formattedTime'),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories Burned (optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter calories burned',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter workout notes',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Discard'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Save Workout'),
        ),
      ],
    );
  }
}