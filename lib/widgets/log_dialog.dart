import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/logger.dart';
import '../services/health_service.dart';

class LogDialog extends StatefulWidget {
  final VoidCallback? onActivityLogged;
  
  const LogDialog({Key? key, this.onActivityLogged}) : super(key: key);
  
  @override
  _LogDialogState createState() => _LogDialogState();
}

class _LogDialogState extends State<LogDialog> {
  final _formKey = GlobalKey<FormState>();
  final HealthService _healthService = HealthService();
  
  // Form field controllers
  final _activityController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  
  // Activity type and loading state
  String _selectedActivityType = 'Cardio';
  bool _isLoading = false;
  
  // Common activity types
  final List<String> _activityTypes = [
    'Cardio',
    'Strength Training',
    'Walking',
    'Running',
    'Cycling',
    'Swimming',
    'Yoga',
    'HIIT',
    'Sports',
    'Other',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Set default values
    _durationController.text = '30';
    _caloriesController.text = '150';
  }
  
  @override
  void dispose() {
    _activityController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }
  
  /// Save the activity to Firestore
  Future<void> _saveActivity() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Prepare activity data
      String activityName = _selectedActivityType;
      if (activityName == 'Other' && _activityController.text.isNotEmpty) {
        activityName = _activityController.text.trim();
      }
      
      int calories = int.parse(_caloriesController.text);
      int duration = int.parse(_durationController.text);
      double? distance;
      if (_distanceController.text.isNotEmpty) {
        distance = double.parse(_distanceController.text);
      }
      
      // Save using health service
      bool success = await _healthService.logManualActivity(
        activityType: activityName,
        calories: calories,
        duration: duration,
        distance: distance,
      );
      
      if (success) {
        // Call callback if provided
        widget.onActivityLogged?.call();
        
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Activity logged: $activityName, $calories cal'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to log activity');
      }
    } catch (e, stack) {
      Logger.logError('Failed to save activity', e, stack);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Activity'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Activity type dropdown
              DropdownButtonFormField<String>(
                value: _selectedActivityType,
                decoration: const InputDecoration(
                  labelText: 'Activity Type',
                  border: OutlineInputBorder(),
                ),
                items: _activityTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedActivityType = value!;
                  });
                },
              ),
              
              // Custom activity name (if Other is selected)
              if (_selectedActivityType == 'Other')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: _activityController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedActivityType == 'Other' && 
                          (value == null || value.isEmpty)) {
                        return 'Please enter an activity name';
                      }
                      return null;
                    },
                  ),
                ),
              
              // Duration field
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Please enter a valid duration';
                    }
                    return null;
                  },
                ),
              ),
              
              // Calories field
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories Burned',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter calories';
                    }
                    final calories = int.tryParse(value);
                    if (calories == null || calories <= 0) {
                      return 'Please enter a valid calorie amount';
                    }
                    return null;
                  },
                ),
              ),
              
              // Distance field (optional)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: _distanceController,
                  decoration: const InputDecoration(
                    labelText: 'Distance (km, optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final distance = double.tryParse(value);
                      if (distance == null || distance <= 0) {
                        return 'Please enter a valid distance';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveActivity,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
