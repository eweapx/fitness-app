import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A service that handles voice commands for the Fuel app
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  
  // Private constructor
  VoiceService._internal();
  
  // Factory constructor
  factory VoiceService() {
    return _instance;
  }
  
  // Speech to text instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _initialized = false;
  bool _isListening = false;
  
  // Getters
  bool get isInitialized => _initialized;
  bool get isListening => _isListening;
  
  /// Initialize the voice service
  Future<bool> initialize() async {
    if (_initialized) return true;
    
    // Request microphone permission
    if (!await Permission.microphone.isGranted) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }
    }
    
    // Initialize speech recognition
    try {
      _initialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          _isListening = false;
        },
      );
      return _initialized;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      _initialized = false;
      return false;
    }
  }
  
  /// Show permission dialog
  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'This app needs microphone access to process voice commands. '
          'Please grant microphone permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Start listening for voice commands
  Future<bool> startListening({
    required Function(String) onResult,
    String? localeId,
  }) async {
    if (!_initialized) {
      final success = await initialize();
      if (!success) return false;
    }
    
    if (_speech.isListening) {
      return false;
    }
    
    final available = await _speech.initialize();
    if (!available) {
      debugPrint('Speech recognition not available');
      return false;
    }
    
    _isListening = await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          onResult(command);
        }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      partialResults: false,
    );
    
    return _isListening;
  }
  
  /// Stop listening for voice commands
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
  
  /// Process a voice command
  Map<String, dynamic> processCommand(String command) {
    command = command.toLowerCase().trim();
    
    // Check for step count commands
    if (command.contains('how many steps') || 
        command.contains('step count') || 
        command.contains('steps today')) {
      return {
        'type': 'query',
        'category': 'steps',
        'action': 'get_count',
      };
    }
    
    // Check for calorie commands
    if (command.contains('calories') || command.contains('calorie count')) {
      return {
        'type': 'query',
        'category': 'calories',
        'action': 'get_count',
      };
    }
    
    // Check for heart rate commands
    if (command.contains('heart rate') || command.contains('pulse')) {
      return {
        'type': 'query',
        'category': 'heart_rate',
        'action': 'get_value',
      };
    }
    
    // Check for workout start/stop commands
    if (command.contains('start workout') || 
        command.contains('begin workout') || 
        command.contains('start tracking')) {
      return {
        'type': 'control',
        'category': 'workout',
        'action': 'start',
      };
    }
    
    if (command.contains('stop workout') || 
        command.contains('end workout') || 
        command.contains('finish workout')) {
      return {
        'type': 'control',
        'category': 'workout',
        'action': 'stop',
      };
    }
    
    // Check for timer commands
    if (command.contains('start timer')) {
      // Extract duration if mentioned, default to 1 minute
      int minutes = 1;
      final regex = RegExp(r'(\d+)\s*(minute|minutes|min)');
      final match = regex.firstMatch(command);
      if (match != null) {
        minutes = int.parse(match.group(1)!);
      }
      
      return {
        'type': 'control',
        'category': 'timer',
        'action': 'start',
        'duration': minutes,
      };
    }
    
    if (command.contains('stop timer') || command.contains('cancel timer')) {
      return {
        'type': 'control',
        'category': 'timer',
        'action': 'stop',
      };
    }
    
    // If we can't identify the command
    return {
      'type': 'unknown',
      'original': command,
    };
  }
  
  /// Get a list of available voice commands as help text
  List<String> getAvailableCommands() {
    return [
      'How many steps did I take today?',
      'What\'s my step count?',
      'How many calories did I burn?',
      'What\'s my heart rate?',
      'Start workout',
      'Stop workout',
      'Start timer for 5 minutes',
      'Stop timer',
    ];
  }
}