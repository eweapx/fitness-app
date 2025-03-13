import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class WorkoutScreen extends StatefulWidget {
  final String? activityId;
  
  const WorkoutScreen({super.key, this.activityId});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  
  // Workout state
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isWorkoutInProgress = false;
  ActivityModel? _existingActivity;
  Timer? _workoutTimer;
  DateTime? _workoutStartTime;
  Duration _elapsedTime = Duration.zero;
  
  // Form fields
  final TextEditingController _nameController = TextEditingController();
  String _workoutType = ActivityTypes.gymWorkout;
  int _caloriesBurned = 0;
  int _durationMinutes = 0;
  final List<ExerciseSet> _exerciseSets = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if we're editing an existing activity
      if (widget.activityId != null) {
        // In a real app, we'd use the current user's ID
        const String demoUserId = 'demo_user';
        
        // Get activity from Firebase
        final activities = await _firebaseService.getUserActivities(demoUserId);
        _existingActivity = activities.firstWhere(
          (a) => a.id == widget.activityId,
          orElse: () => ActivityModel(
            userId: demoUserId,
            name: '',
            type: ActivityTypes.gymWorkout,
            duration: 0,
            caloriesBurned: 0,
            date: DateTime.now(),
          ),
        );
        
        // Populate form fields
        _nameController.text = _existingActivity!.name;
        _workoutType = _existingActivity!.type;
        _caloriesBurned = _existingActivity!.caloriesBurned;
        _durationMinutes = _existingActivity!.duration;
        _notesController.text = _existingActivity!.notes ?? '';
        
        // Get exercise sets from additional data if available
        if (_existingActivity!.additionalData != null && 
            _existingActivity!.additionalData!.containsKey('exercises')) {
          final exercises = _existingActivity!.additionalData!['exercises'] as List;
          for (var exercise in exercises) {
            _exerciseSets.add(ExerciseSet.fromMap(exercise));
          }
        }
        
        _isEditing = true;
      } else {
        // New workout - set defaults
        _nameController.text = 'Workout';
        _workoutType = ActivityTypes.gymWorkout;
      }
    } catch (e) {
      print('Error loading activity: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading workout: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startWorkout() {
    setState(() {
      _isWorkoutInProgress = true;
      _workoutStartTime = DateTime.now();
      _elapsedTime = Duration.zero;
    });
    
    // Start timer
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_workoutStartTime!);
        _durationMinutes = _elapsedTime.inMinutes;
      });
    });
  }

  void _pauseWorkout() {
    _workoutTimer?.cancel();
    setState(() => _isWorkoutInProgress = false);
  }

  void _resumeWorkout() {
    _startWorkout();
  }

  void _endWorkout() {
    _workoutTimer?.cancel();
    
    // Calculate calories if not manually entered
    if (_caloriesBurned == 0) {
      _caloriesBurned = _calculateEstimatedCalories();
    }
    
    setState(() {
      _isWorkoutInProgress = false;
      _durationMinutes = _elapsedTime.inMinutes;
    });
    
    // Show save dialog
    _showSaveWorkoutDialog();
  }
  
  int _calculateEstimatedCalories() {
    // Simple estimation: ~5-10 calories per minute depending on intensity
    final totalMinutes = _elapsedTime.inMinutes;
    
    // Estimate based on workout type
    int caloriesPerMinute = 5; // Default moderate intensity
    
    switch (_workoutType) {
      case ActivityTypes.hiit:
        caloriesPerMinute = 12; // High intensity
        break;
      case ActivityTypes.running:
        caloriesPerMinute = 10; // High intensity
        break;
      case ActivityTypes.gymWorkout:
        caloriesPerMinute = 8; // Moderate-high intensity
        break;
      case ActivityTypes.cycling:
        caloriesPerMinute = 7; // Moderate intensity
        break;
      case ActivityTypes.walking:
        caloriesPerMinute = 4; // Low intensity
        break;
      default:
        caloriesPerMinute = 6; // Moderate intensity
    }
    
    return totalMinutes * caloriesPerMinute;
  }

  void _addExerciseSet() {
    setState(() {
      _exerciseSets.add(ExerciseSet(
        name: '',
        sets: 3,
        reps: 10,
        weight: 0,
      ));
    });
  }

  void _removeExerciseSet(int index) {
    setState(() {
      _exerciseSets.removeAt(index);
    });
  }

  void _updateExerciseSet(int index, ExerciseSet updatedSet) {
    setState(() {
      _exerciseSets[index] = updatedSet;
    });
  }
  
  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // In a real app, we'd use the current user's ID
      const String demoUserId = 'demo_user';
      
      // Prepare exercise data
      final List<Map<String, dynamic>> exerciseData = _exerciseSets
          .where((set) => set.name.isNotEmpty)
          .map((set) => set.toMap())
          .toList();
      
      // Create activity model
      final activity = ActivityModel(
        id: _existingActivity?.id,
        userId: demoUserId,
        name: _nameController.text,
        type: _workoutType,
        duration: _durationMinutes,
        caloriesBurned: _caloriesBurned,
        date: _existingActivity?.date ?? DateTime.now(),
        notes: _notesController.text,
        additionalData: {
          'exercises': exerciseData,
        },
      );
      
      // Save to Firebase
      if (_isEditing) {
        await _firebaseService.updateActivity(activity);
      } else {
        await _firebaseService.addActivity(activity);
      }
      
      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved successfully')),
      );
      
      Navigator.pop(context, true); // Pass true to indicate successful save
    } catch (e) {
      print('Error saving workout: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }
  
  void _showSaveWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Workout'),
        content: const Text('Do you want to save this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveWorkout();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showExerciseDialog(ExerciseSet exerciseSet, int index) {
    final nameController = TextEditingController(text: exerciseSet.name);
    final setsController = TextEditingController(text: exerciseSet.sets.toString());
    final repsController = TextEditingController(text: exerciseSet.reps.toString());
    final weightController = TextEditingController(text: exerciseSet.weight.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exerciseSet.name.isEmpty ? 'Add Exercise' : 'Edit Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Bench Press',
                ),
              ),
              TextField(
                controller: setsController,
                decoration: const InputDecoration(labelText: 'Sets'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: '0 for bodyweight',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedSet = ExerciseSet(
                name: nameController.text,
                sets: int.tryParse(setsController.text) ?? 0,
                reps: int.tryParse(repsController.text) ?? 0,
                weight: double.tryParse(weightController.text) ?? 0,
              );
              
              _updateExerciseSet(index, updatedSet);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Workout' : 'New Workout'),
        actions: [
          if (!_isWorkoutInProgress && !_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveWorkout,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading workout...')
          : _buildWorkoutForm(),
    );
  }

  Widget _buildWorkoutForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Workout timer section
          if (!_isEditing) _buildWorkoutTimerSection(),
          
          // Workout details section
          _buildWorkoutDetailsSection(),
          
          // Exercises section
          _buildExercisesSection(),
          
          // Notes section
          _buildNotesSection(),
          
          const SizedBox(height: 32),
          
          // Save button
          if (!_isWorkoutInProgress)
            AppButton(
              label: 'Save Workout',
              icon: Icons.save,
              onPressed: _saveWorkout,
              isFullWidth: true,
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTimerSection() {
    final formattedTime = _formatDuration(_elapsedTime);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isWorkoutInProgress)
                  Expanded(
                    child: AppButton(
                      label: _workoutStartTime == null ? 'Start' : 'Resume',
                      icon: Icons.play_arrow,
                      backgroundColor: AppColors.success,
                      onPressed: _workoutStartTime == null ? _startWorkout : _resumeWorkout,
                      isFullWidth: true,
                    ),
                  ),
                if (_isWorkoutInProgress)
                  Expanded(
                    child: AppButton(
                      label: 'Pause',
                      icon: Icons.pause,
                      backgroundColor: AppColors.warning,
                      onPressed: _pauseWorkout,
                      isFullWidth: true,
                    ),
                  ),
                if (_workoutStartTime != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: 'End',
                      icon: Icons.stop,
                      backgroundColor: AppColors.error,
                      onPressed: _endWorkout,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDetailsSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Details',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a workout name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _workoutType,
              decoration: const InputDecoration(
                labelText: 'Workout Type',
                border: OutlineInputBorder(),
              ),
              items: ActivityTypes.all.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(ActivityTypes.getDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _workoutType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _durationMinutes.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _durationMinutes = int.tryParse(value) ?? 0;
                      });
                    },
                    enabled: !_isWorkoutInProgress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _caloriesBurned.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Calories Burned',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _caloriesBurned = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exercises',
                  style: AppTextStyles.heading3,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.primary,
                  onPressed: _addExerciseSet,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_exerciseSets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No exercises added yet. Tap + to add exercises.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exerciseSets.length,
                itemBuilder: (context, index) {
                  final exercise = _exerciseSets[index];
                  return ListTile(
                    title: Text(
                      exercise.name.isEmpty ? 'Untitled Exercise' : exercise.name,
                      style: exercise.name.isEmpty
                          ? AppTextStyles.body.copyWith(color: AppColors.textLight)
                          : AppTextStyles.body,
                    ),
                    subtitle: Text(
                      '${exercise.sets} sets × ${exercise.reps} reps ${exercise.weight > 0 ? '× ${exercise.weight}kg' : ''}',
                      style: AppTextStyles.caption,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showExerciseDialog(exercise, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _removeExerciseSet(index),
                        ),
                      ],
                    ),
                    onTap: () => _showExerciseDialog(exercise, index),
                  );
                },
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              onPressed: _addExerciseSet,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add notes about your workout...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}

class ExerciseSet {
  String name;
  int sets;
  int reps;
  double weight;
  
  ExerciseSet({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });
  
  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      name: map['name'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }
}