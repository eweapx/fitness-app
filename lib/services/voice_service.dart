import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'health_service.dart';

/// Service for voice commands and speech recognition
class VoiceService {
  // Singleton implementation
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();
  
  // In a real app, we would use the speech_to_text package
  // final SpeechToText _speech = SpeechToText();
  
  bool _isListening = false;
  bool _isInitialized = false;
  final HealthService _healthService = HealthService();
  
  // Stream controller for voice commands
  final StreamController<String> _commandStreamController = StreamController<String>.broadcast();
  Stream<String> get commandStream => _commandStreamController.stream;
  
  /// Initialize the voice service
  Future<bool> initialize() async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          return false;
        }
      }
      
      // In a real app, we would initialize the speech to text service
      // _isInitialized = await _speech.initialize(
      //   onStatus: _onSpeechStatus,
      //   onError: _onSpeechError,
      // );
      
      _isInitialized = true;
      return _isInitialized;
    } catch (e, stack) {
      Logger.logError('Voice service initialization failed', e, stack);
      return false;
    }
  }
  
  /// Start listening for voice commands
  Future<bool> startListening() async {
    if (!_isInitialized) {
      if (!await initialize()) {
        return false;
      }
    }
    
    try {
      // In a real app, we would start the speech recognition
      // await _speech.listen(
      //   onResult: _onSpeechResult,
      //   listenFor: Duration(seconds: 30),
      //   pauseFor: Duration(seconds: 5),
      //   partialResults: true,
      //   localeId: 'en_US',
      // );
      
      _isListening = true;
      Logger.logEvent('Voice listening started');
      
      // Simulate a voice command after a delay for testing
      Future.delayed(const Duration(seconds: 2), () {
        if (_isListening) {
          _onSpeechResult('log running 30 minutes');
        }
      });
      
      return true;
    } catch (e, stack) {
      Logger.logError('Start listening failed', e, stack);
      return false;
    }
  }
  
  /// Stop listening for voice commands
  Future<bool> stopListening() async {
    if (!_isInitialized || !_isListening) {
      return false;
    }
    
    try {
      // In a real app, we would stop the speech recognition
      // await _speech.stop();
      
      _isListening = false;
      Logger.logEvent('Voice listening stopped');
      return true;
    } catch (e, stack) {
      Logger.logError('Stop listening failed', e, stack);
      return false;
    }
  }
  
  /// Process voice command result
  void _onSpeechResult(String text) {
    if (!_isListening) return;
    
    final String command = text.toLowerCase();
    Logger.logEvent('Voice command received', {'command': command});
    
    // Process command
    _processCommand(command);
    
    // Push to stream
    _commandStreamController.add(command);
  }
  
  /// Process a voice command
  Future<void> _processCommand(String command) async {
    // Simple command detection for demo
    try {
      // Logging an activity
      if (command.contains('log') || command.contains('add')) {
        await _processActivityLogCommand(command);
      }
      // Starting tracking
      else if ((command.contains('start') || command.contains('begin')) && 
          (command.contains('track') || command.contains('tracking'))) {
        await _healthService.startAutoTracking();
        await _notifySuccess('Tracking started');
      }
      // Stopping tracking
      else if ((command.contains('stop') || command.contains('end')) && 
          (command.contains('track') || command.contains('tracking'))) {
        await _healthService.stopAutoTracking();
        await _notifySuccess('Tracking stopped');
      }
      // Show summary
      else if (command.contains('summary') || command.contains('report')) {
        await _notifySuccess('Showing activity summary');
        // In a real app, this would navigate to the summary screen
      }
      else {
        await _notifyError('Unrecognized command: $command');
      }
    } catch (e, stack) {
      Logger.logError('Error processing command', e, stack);
      await _notifyError('Error processing command');
    }
  }
  
  /// Process activity logging commands
  Future<void> _processActivityLogCommand(String command) async {
    // Extract activity type and duration
    String? activityType;
    int? duration;
    
    // Check for common activities
    final activities = [
      'walking', 'running', 'jogging', 'cycling', 'swimming',
      'hiking', 'yoga', 'workout', 'exercise', 'training',
      'weights', 'lifting', 'gym', 'cardio'
    ];
    
    for (final activity in activities) {
      if (command.contains(activity)) {
        activityType = activity;
        break;
      }
    }
    
    // If no matching activity, use default
    activityType ??= 'exercise';
    
    // Extract duration
    final RegExp durationRegex = RegExp(r'(\d+)\s*(min|minute|minutes|hour|hours|hr|hrs)');
    final match = durationRegex.firstMatch(command);
    
    if (match != null) {
      duration = int.parse(match.group(1)!);
      final unit = match.group(2);
      
      // Convert hours to minutes
      if (unit != null && (unit.contains('hour') || unit.contains('hr'))) {
        duration *= 60;
      }
    } else {
      // Default duration if not specified
      duration = 30;
    }
    
    // Calculate estimated calories (simple estimate)
    int calories = 0;
    switch (activityType) {
      case 'running':
      case 'jogging':
        calories = (duration * 10).round(); // About 10 cal/min
        break;
      case 'cycling':
        calories = (duration * 8).round(); // About 8 cal/min
        break;
      case 'swimming':
        calories = (duration * 9).round(); // About 9 cal/min
        break;
      case 'walking':
        calories = (duration * 5).round(); // About 5 cal/min
        break;
      default:
        calories = (duration * 7).round(); // Default ~7 cal/min
    }
    
    // Log the activity
    final activityData = {
      'type': activityType,
      'duration': duration,
      'calories': calories,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'auto': false,
    };
    
    final success = await _healthService.logManualActivity(activityData);
    
    if (success) {
      await _notifySuccess('Logged $activityType for $duration minutes');
    } else {
      await _notifyError('Failed to log activity');
    }
  }
  
  /// Notify user of success
  Future<void> _notifySuccess(String message) async {
    // In a real app, this would display a notification or speak the response
    Logger.logEvent('Voice command success', {'message': message});
  }
  
  /// Notify user of error
  Future<void> _notifyError(String message) async {
    // In a real app, this would display a notification or speak the response
    Logger.logEvent('Voice command error', {'message': message});
  }
  
  /// Dispose resources
  void dispose() {
    _commandStreamController.close();
  }
}