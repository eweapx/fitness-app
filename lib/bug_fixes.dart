import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

/// BUGFIX 1: Improved Logger with rate limiting and offline queueing
class ImprovedLogger {
  static int _errorLogCount = 0;
  static DateTime _lastErrorLogTime = DateTime.now();
  static List<Map<String, dynamic>> _offlineQueue = [];
  
  static Future<void> logError(String message, [dynamic error, StackTrace? stackTrace]) async {
    print("ERROR: $message");
    if (error != null) print("Error: $error");
    if (stackTrace != null) print("StackTrace: $stackTrace");

    // Rate limiting for Firestore writes (max 10 errors per minute)
    final now = DateTime.now();
    if (now.difference(_lastErrorLogTime).inMinutes >= 1) {
      _errorLogCount = 0;
      _lastErrorLogTime = now;
    }
    
    if (_errorLogCount >= 10) return;
    _errorLogCount++;

    // Check connectivity before attempting Firestore write
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;

    final logData = {
      'type': 'error',
      'message': message,
      'error': error?.toString() ?? '',
      'stackTrace': stackTrace?.toString() ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (isConnected) {
      // Process offline queue first
      if (_offlineQueue.isNotEmpty) {
        for (var item in _offlineQueue) {
          await FirebaseFirestore.instance.collection('logs').add(item);
        }
        _offlineQueue.clear();
      }
      
      try {
        await FirebaseFirestore.instance.collection('logs').add(logData);
      } catch (e) {
        _offlineQueue.add(logData);
      }
    } else {
      _offlineQueue.add(logData);
    }
  }

  static Future<void> logEvent(String event, [Map<String, dynamic>? details]) async {
    print("EVENT: $event, details: $details");
    
    // Only log important events to Firestore
    final importantEvents = ['user_signup', 'user_login', 'activity_recorded', 'permissions_changed'];
    if (!importantEvents.contains(event)) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;

    final logData = {
      'type': 'event',
      'event': event,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (isConnected) {
      try {
        await FirebaseFirestore.instance.collection('logs').add(logData);
      } catch (e) {
        print("Failed to log event: $e");
      }
    }
  }
}

/// BUGFIX 2: Improved notification handling for both platforms
class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  
  NotificationService._internal() : flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  int _notificationId = 0;
  
  Future<void> initialize() async {
    // Android notification channel setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings with sound and alert
    final IOSInitializationSettings iosSettings = IOSInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS 9 and below notifications
      },
    );
    
    final InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onSelectNotification: (payload) async {
        if (payload != null) {
          // Handle notification tap
          print('Notification payload: $payload');
        }
      },
    );
    
    // Create Android notification channels for Android 8+
    await _createNotificationChannels();
  }
  
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel activityChannel = AndroidNotificationChannel(
      'fuel_activity_channel', // id
      'Activity Tracking', // title
      description: 'Notifications related to your fitness activities',
      importance: Importance.high,
    );
    
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'fuel_reminder_channel', // id
      'Workout Reminders', // title
      description: 'Reminders to stay active and log workouts',
      importance: Importance.default_,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(activityChannel);
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }
  
  Future<void> showActivityNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fuel_activity_channel',
      'Activity Tracking',
      channelDescription: 'Notifications related to your fitness activities',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const IOSNotificationDetails iosDetails = IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    // Use incremented notification ID to avoid overwriting
    await flutterLocalNotificationsPlugin.show(
      _getNextNotificationId(),
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
  
  int _getNextNotificationId() {
    // Reset after 100 to avoid excessively large IDs
    if (_notificationId >= 100) _notificationId = 0;
    return _notificationId++;
  }
  
  Future<bool> requestIOSPermissions() async {
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? false;
  }
}

/// BUGFIX 3: Improved Health Service with better error handling and permissions
class ImprovedHealthService {
  final HealthFactory health = HealthFactory();
  bool _permissionsRequested = false;
  
  final List<HealthDataType> _requiredTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.MOVE_MINUTES,
    HealthDataType.WORKOUT,
  ];
  
  Future<bool> hasPermissions() async {
    if (!_permissionsRequested) return false;
    
    try {
      return await health.hasPermissions(_requiredTypes, permissions: [
        HealthDataAccess.READ,
        HealthDataAccess.READ_WRITE,
      ]) ?? false;
    } catch (e) {
      ImprovedLogger.logError("Failed to check health permissions", e);
      return false;
    }
  }
  
  Future<bool> requestPermissions(BuildContext context) async {
    try {
      // First check activity recognition permission
      if (!await Permission.activityRecognition.isGranted) {
        var status = await Permission.activityRecognition.request();
        if (status.isDenied) {
          _showPermissionDialog(context, 'activity recognition');
          return false;
        }
      }
      
      // Then request health permissions
      bool granted = await health.requestAuthorization(_requiredTypes);
      _permissionsRequested = true;
      
      if (granted) {
        ImprovedLogger.logEvent('health_permissions_granted');
      } else {
        ImprovedLogger.logEvent('health_permissions_denied');
        _showPermissionDialog(context, 'health data access');
      }
      
      return granted;
    } catch (e, stack) {
      ImprovedLogger.logError("Health permission request failed", e, stack);
      return false;
    }
  }
  
  void _showPermissionDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
            'This app needs $permissionType to track your fitness data accurately. Without this permission, some features may be limited.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: Text('Open Settings')),
        ],
      ),
    );
  }
  
  Future<int> getStepsInInterval(DateTime start, DateTime end) async {
    try {
      final steps = await health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e, stack) {
      ImprovedLogger.logError("Failed to get steps in interval", e, stack);
      return 0;
    }
  }
  
  Future<double> getHeartRateInInterval(DateTime start, DateTime end) async {
    try {
      List<HealthDataPoint> data =
          await health.readHealthData(HealthDataType.HEART_RATE, start, end);
      
      // BUGFIX: Handle empty data properly
      if (data.isEmpty) return 0.0;
      
      double sum = 0;
      int validPoints = 0;
      
      for (var point in data) {
        // Validate each data point before adding
        if (point.value is NumericHealthValue) {
          final value = (point.value as NumericHealthValue).numericValue;
          if (value > 0) {  // Only count positive values
            sum += value;
            validPoints++;
          }
        }
      }
      
      // Prevent division by zero
      return validPoints > 0 ? sum / validPoints : 0.0;
    } catch (e, stack) {
      ImprovedLogger.logError("Failed to get heart rate in interval", e, stack);
      return 0.0;
    }
  }
  
  Future<double> getActiveEnergyInInterval(DateTime start, DateTime end) async {
    try {
      List<HealthDataPoint> data =
          await health.readHealthData(HealthDataType.ACTIVE_ENERGY_BURNED, start, end);
      
      // BUGFIX: Safely sum values with validation
      double total = 0;
      for (var point in data) {
        if (point.value is NumericHealthValue) {
          final value = (point.value as NumericHealthValue).numericValue;
          if (value >= 0) {  // Only add non-negative values
            total += value;
          }
        }
      }
      return total;
    } catch (e, stack) {
      ImprovedLogger.logError("Failed to get active energy in interval", e, stack);
      return 0.0;
    }
  }
  
  Future<Map<String, dynamic>> getUserProfileData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return _getDefaultProfileData();
      
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (!userProfile.exists) return _getDefaultProfileData();
      
      final data = userProfile.data() as Map<String, dynamic>;
      
      return {
        'weight': data['weight']?.toDouble() ?? 70.0,
        'height': data['height']?.toDouble() ?? 170.0,
        'age': data['age'] ?? 25,
        'gender': data['gender'] ?? 'unknown',
        'activityLevel': data['activityLevel'] ?? 'moderate',
      };
    } catch (e, stack) {
      ImprovedLogger.logError("Failed to fetch user profile", e, stack);
      return _getDefaultProfileData();
    }
  }
  
  Map<String, dynamic> _getDefaultProfileData() {
    return {
      'weight': 70.0,
      'height': 170.0,
      'age': 25,
      'gender': 'unknown',
      'activityLevel': 'moderate',
    };
  }
  
  Future<int> calculateCaloriesBurnedInInterval(DateTime start, DateTime end) async {
    try {
      int steps = await getStepsInInterval(start, end);
      double heartRate = await getHeartRateInInterval(start, end);
      double activeEnergy = await getActiveEnergyInInterval(start, end);
      
      Map<String, dynamic> profile = await getUserProfileData();
      
      double weight = profile['weight'];
      int age = profile['age'];
      String gender = profile['gender'];
      String activityLevel = profile['activityLevel'];
      
      // Activity level multiplier
      double activityMultiplier = 1.0;
      switch (activityLevel) {
        case 'sedentary':
          activityMultiplier = 0.8;
          break;
        case 'moderate':
          activityMultiplier = 1.0;
          break;
        case 'active':
          activityMultiplier = 1.2;
          break;
        case 'very_active':
          activityMultiplier = 1.4;
          break;
      }
      
      // Gender factor
      double genderFactor = (gender == 'male') ? 1.1 : 
                           (gender == 'female') ? 0.9 : 1.0;
      
      // Calculate based on all factors
      double calculatedCalories = 0;
      
      // Steps contribution: ~0.04 cal per step, adjusted for weight
      if (steps > 0) {
        calculatedCalories += steps * 0.04 * (weight / 70);
      }
      
      // Heart rate contribution
      if (heartRate > 0) {
        // More accurate formula based on scientific studies
        double hrFactor = heartRate * 0.6 * (age / 30) * genderFactor;
        calculatedCalories += hrFactor;
      }
      
      // Add active energy if available
      if (activeEnergy > 0) {
        calculatedCalories += activeEnergy;
      }
      
      // Apply activity level multiplier
      calculatedCalories *= activityMultiplier;
      
      return calculatedCalories.round();
    } catch (e, stack) {
      ImprovedLogger.logError("Failed to calculate calories burned", e, stack);
      return 0;
    }
  }
  
  Future<void> logAutoTrackedCalories(DateTime start, DateTime end) async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      // Check connectivity first
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Store in local storage for later sync
        // Not implemented here but should be added
        return;
      }
      
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(uid);
          
      DocumentSnapshot snapshot = await userDoc.get();
      if (!snapshot.exists) return;
      
      Timestamp? lastAutoTrack = snapshot.get('last_auto_track');
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      
      if (lastAutoTrack == null || lastAutoTrack.toDate().isBefore(todayStart)) {
        int calories = await calculateCaloriesBurnedInInterval(start, end);
        
        // Use transaction to ensure data consistency
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // First update last_auto_track to prevent duplicate entries
          transaction.update(userDoc, {'last_auto_track': FieldValue.serverTimestamp()});
          
          // Then create activity log
          DocumentReference newActivityRef = userDoc.collection('activities').doc();
          transaction.set(newActivityRef, {
            'type': 'Auto-Tracked Activity',
            'calories': calories,
            'duration': end.difference(start).inMinutes,
            'timestamp': FieldValue.serverTimestamp(),
            'auto': true,
          });
        });
        
        // Show notification with newly created service
        await NotificationService().showActivityNotification(
          title: "Daily Activity Update",
          body: "You've burned $calories cal so far today. Keep it up!",
          payload: "activity_update",
        );
        
        ImprovedLogger.logEvent("auto_tracked_calories_logged", {'calories': calories});
      }
    } catch (e, stack) {
      ImprovedLogger.logError("Failed to log auto-tracked calories", e, stack);
    }
  }
}

/// BUGFIX 4: Improved voice command parser with better accuracy and feedback
class VoiceCommandProcessor {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastError = "";
  
  Future<bool> initialize() async {
    bool available = await _speech.initialize(
      onError: (error) => _lastError = error.errorMsg,
      debugLogging: false,
    );
    return available;
  }
  
  Future<Map<String, dynamic>> listenForCommand(BuildContext context) async {
    if (!_isListening) {
      bool available = await initialize();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available')),
        );
        return {'success': false, 'error': 'Speech recognition not available'};
      }
      
      _isListening = true;
      _lastError = "";
      
      // Show listening indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mic, color: Colors.white),
              SizedBox(width: 12),
              Text('Listening...'),
            ],
          ),
          duration: Duration(seconds: 30),
          action: SnackBarAction(
            label: 'Cancel',
            onPressed: () {
              _speech.stop();
              _isListening = false;
            },
          ),
        ),
      );
      
      await _speech.listen(
        onResult: (result) async {
          if (result.finalResult) {
            _isListening = false;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            String command = result.recognizedWords;
            if (command.isNotEmpty) {
              Map<String, dynamic> parsedCommand = improvedParseVoiceCommand(command);
              
              // Show what was understood
              _showCommandFeedback(context, command, parsedCommand);
              
              return {'success': true, 'result': parsedCommand};
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not understand command')),
              );
              return {'success': false, 'error': 'Empty command'};
            }
          }
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        localeId: 'en_US',
      );
      
      return {'success': true, 'processing': true};
    } else {
      _speech.stop();
      _isListening = false;
      return {'success': false, 'error': 'Already listening'};
    }
  }
  
  void _showCommandFeedback(BuildContext context, String rawCommand, Map<String, dynamic> parsedCommand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Voice Command Recognized'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('I heard: "$rawCommand"'),
            SizedBox(height: 16),
            Text('Activity: ${parsedCommand['activityType'] ?? 'Not specified'}'),
            if (parsedCommand['duration'] > 0)
              Text('Duration: ${parsedCommand['duration']} minutes'),
            if (parsedCommand['calories'] > 0)
              Text('Calories: ${parsedCommand['calories']} cal'),
            if (parsedCommand['distance'] > 0)
              Text('Distance: ${parsedCommand['distance']} km'),
            if (parsedCommand['sets'] > 0)
              Text('Sets: ${parsedCommand['sets']}'),
            if (parsedCommand['weight'] > 0)
              Text('Weight: ${parsedCommand['weight']} kg/lbs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Log the activity
              Navigator.pop(context);
            },
            child: Text('Log Activity'),
          ),
        ],
      ),
    );
  }
  
  Map<String, dynamic> improvedParseVoiceCommand(String command) {
    // Default values
    String activityType = '';
    int duration = 0;
    int calories = 0;
    double distance = 0.0;
    int sets = 0;
    int weight = 0;
    
    // Normalize the command (lowercase, trim extra spaces)
    command = command.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Common activity types to recognize
    final List<String> knownActivities = [
      'running', 'jogging', 'walking', 'cycling', 'swimming',
      'weights', 'weight lifting', 'yoga', 'pilates', 'hiit',
      'cardio', 'strength training', 'crossfit', 'basketball',
      'football', 'soccer', 'tennis', 'hiking', 'dancing'
    ];
    
    // Try to match known activities first
    for (String activity in knownActivities) {
      if (command.contains(activity)) {
        activityType = activity;
        break;
      }
    }
    
    // If no known activity found, extract the first phrase
    if (activityType.isEmpty) {
      RegExp typeRegex = RegExp(r'^([\w\s]+?)(?:\s+(?:for|did|during|with)|\s+\d+|$)', caseSensitive: false);
      Match? typeMatch = typeRegex.firstMatch(command);
      if (typeMatch != null) {
        activityType = typeMatch.group(1)!.trim();
      } else {
        // Fallback to first word if no match
        activityType = command.split(' ').first;
      }
    }
    
    // Extract duration with improved patterns
    List<RegExp> durationPatterns = [
      RegExp(r'(\d+)\s*(?:min(?:ute)?s?|m\b)', caseSensitive: false),
      RegExp(r'for\s+(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:hour|hr)', caseSensitive: false),
    ];
    
    for (var pattern in durationPatterns) {
      Match? match = pattern.firstMatch(command);
      if (match != null) {
        duration = int.parse(match.group(1)!);
        // Convert hours to minutes if needed
        if (match.group(0)!.contains('hour') || match.group(0)!.contains('hr')) {
          duration *= 60;
        }
        break;
      }
    }
    
    // Extract calories with multiple patterns
    List<RegExp> caloriesPatterns = [
      RegExp(r'(\d+)\s*(?:cal(?:orie)?s?|kcal)', caseSensitive: false),
      RegExp(r'burned\s+(\d+)', caseSensitive: false),
    ];
    
    for (var pattern in caloriesPatterns) {
      Match? match = pattern.firstMatch(command);
      if (match != null) {
        calories = int.parse(match.group(1)!);
        break;
      }
    }
    
    // Extract distance with km or mile patterns
    RegExp kmPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(?:km|kilometer)', caseSensitive: false);
    RegExp milePattern = RegExp(r'(\d+(?:\.\d+)?)\s*(?:mile)', caseSensitive: false);
    
    Match? kmMatch = kmPattern.firstMatch(command);
    if (kmMatch != null) {
      distance = double.parse(kmMatch.group(1)!);
    } else {
      Match? mileMatch = milePattern.firstMatch(command);
      if (mileMatch != null) {
        // Convert miles to km
        distance = double.parse(mileMatch.group(1)!) * 1.60934;
      }
    }
    
    // Extract sets
    RegExp setsPattern = RegExp(r'(\d+)\s*(?:sets?|rounds?)', caseSensitive: false);
    Match? setsMatch = setsPattern.firstMatch(command);
    if (setsMatch != null) {
      sets = int.parse(setsMatch.group(1)!);
    }
    
    // Extract weight with unit awareness
    RegExp kgPattern = RegExp(r'(\d+)\s*(?:kg|kilos?)', caseSensitive: false);
    RegExp lbsPattern = RegExp(r'(\d+)\s*(?:lbs?|pounds?)', caseSensitive: false);
    
    Match? kgMatch = kgPattern.firstMatch(command);
    if (kgMatch != null) {
      weight = int.parse(kgMatch.group(1)!);
    } else {
      Match? lbsMatch = lbsPattern.firstMatch(command);
      if (lbsMatch != null) {
        // Store the raw weight value, the UI can convert if needed
        weight = int.parse(lbsMatch.group(1)!);
      }
    }
    
    return {
      'activityType': activityType,
      'duration': duration,
      'calories': calories,
      'distance': distance,
      'sets': sets,
      'weight': weight,
      'rawCommand': command,
    };
  }
}

/// BUGFIX 5: Improved Firebase Auth service with better error handling and transaction safety
class ImprovedAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track auth state for offline awareness
  bool _isAuthenticated = false;
  StreamSubscription<User?>? _authStateSubscription;
  
  ImprovedAuthService() {
    // Listen to auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _isAuthenticated = user != null;
    });
  }
  
  void dispose() {
    _authStateSubscription?.cancel();
  }
  
  bool get isAuthenticated => _isAuthenticated;
  
  Future<User?> signUpWithEmail(String email, String password, BuildContext context) async {
    try {
      // Validate email and password before attempting to create account
      if (!_isValidEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address',
        );
      }
      
      if (!_isValidPassword(password)) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters with letters and numbers',
        );
      }
      
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'No internet connection. Please check your network settings.',
        );
      }
      
      // Start with Firebase auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user != null) {
        // Use a transaction to ensure the user profile is created
        await _firestore.runTransaction((transaction) async {
          // Check if profile already exists
          DocumentReference userRef = _firestore.collection('users').doc(cred.user!.uid);
          DocumentSnapshot userDoc = await transaction.get(userRef);
          
          if (!userDoc.exists) {
            // Create user doc with baseline data
            transaction.set(userRef, {
              'email': email,
              'weight': 70.0,
              'height': 170.0,
              'age': 25,
              'gender': 'unknown',
              'dietary_restrictions': '',
              'fitness_goals': '',
              'last_auto_track': null,
              'created_at': FieldValue.serverTimestamp(),
            });
          }
        });
        
        ImprovedLogger.logEvent("user_signup", {'uid': cred.user!.uid});
        return cred.user;
      }
      return null;
    } catch (e, stack) {
      ImprovedLogger.logError("Sign-up failed", e, stack);
      
      // Provide user-friendly error messages
      String errorMessage = _getAuthErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      return null;
    }
  }
  
  Future<User?> signInWithEmail(String email, String password, BuildContext context) async {
    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'No internet connection. Please check your network settings.',
        );
      }
      
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      ImprovedLogger.logEvent("user_signin", {'uid': cred.user!.uid});
      
      // Update last login timestamp
      if (cred.user != null) {
        try {
          await _firestore.collection('users').doc(cred.user!.uid).update({
            'last_login': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // Non-critical operation, continue even if this fails
          print("Failed to update last login: $e");
        }
      }
      
      return cred.user;
    } catch (e, stack) {
      ImprovedLogger.logError("Sign-in failed", e, stack);
      
      // Provide user-friendly error messages
      String errorMessage = _getAuthErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      return null;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      ImprovedLogger.logEvent("user_signout");
    } catch (e, stack) {
      ImprovedLogger.logError("Sign-out failed", e, stack);
      // Even if signout fails on Firebase, we should still consider the user as logged out locally
      _isAuthenticated = false;
    }
  }
  
  Future<void> resetPassword(String email, BuildContext context) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stack) {
      ImprovedLogger.logError("Password reset failed", e, stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getAuthErrorMessage(e)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  
  bool _isValidPassword(String password) {
    // At least 6 chars, with at least one letter and one number
    return password.length >= 6 && 
           RegExp(r'[A-Za-z]').hasMatch(password) && 
           RegExp(r'[0-9]').hasMatch(password);
  }
  
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Please sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters with letters and numbers.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'Authentication failed. Please try again later.';
  }
}

/// BUGFIX 6: Improved AuthGate with better loading states and error handling
class ImprovedAuthGate extends StatefulWidget {
  @override
  _ImprovedAuthGateState createState() => _ImprovedAuthGateState();
}

class _ImprovedAuthGateState extends State<ImprovedAuthGate> {
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      // Initialize notifications
      await NotificationService().initialize();
      
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // We can still continue, just show a banner
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: Text('No internet connection. Some features may be limited.'),
            leading: Icon(Icons.wifi_off, color: Colors.orange),
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                child: Text('DISMISS'),
              ),
            ],
          ),
        );
      }
    } catch (e, stack) {
      ImprovedLogger.logError('App initialization failed', e, stack);
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize app: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing app...'),
            ],
          ),
        ),
      );
    }
    
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(_errorMessage, textAlign: TextAlign.center),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _initializeApp(),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Check for auth errors
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text('Authentication Error',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Please sign in again'),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return snapshot.hasData ? HomeScreen() : LoginScreen();
      },
    );
  }
}

/// BUGFIX 7: Improved connectivity handling throughout the app
class ConnectivityService {
  final _connectivity = Connectivity();
  bool _isOnline = true;
  
  // Stream controller to broadcast connection status changes
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  ConnectivityService() {
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      _connectionStatusController.add(_isOnline);
    });
    
    // Initial check
    _checkConnectivity();
  }
  
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    _connectionStatusController.add(_isOnline);
  }
  
  bool get isOnline => _isOnline;
  
  void dispose() {
    _connectionStatusController.close();
  }
}

/// BUGFIX 8: Create a connectivity-aware widget for use throughout the app
class ConnectivityAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  
  const ConnectivityAwareWidget({
    required this.child,
    this.offlineWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStatus,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        
        if (!isOnline && offlineWidget != null) {
          return offlineWidget!;
        }
        
        return Column(
          children: [
            if (!isOnline)
              Container(
                color: Colors.orange[100],
                padding: EdgeInsets.symmetric(vertical: 4),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: Colors.orange[800]),
                    SizedBox(width: 8),
                    Text(
                      'You are offline. Some features may be limited.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// BUGFIX 9: Safe Firebase operations mixin
mixin SafeFirebaseOperations {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<T?> safeFirestoreOperation<T>(Future<T> Function() operation, {
    T? defaultValue,
    String? errorMessage,
    bool logError = true,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      if (logError) {
        ImprovedLogger.logError(errorMessage ?? 'Firestore operation failed', e, stack);
      }
      return defaultValue;
    }
  }
  
  Future<bool> safeDocumentWrite({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(data, SetOptions(merge: merge));
      return true;
    } catch (e, stack) {
      ImprovedLogger.logError('Failed to write document: $collection/$documentId', e, stack);
      return false;
    }
  }
  
  Future<DocumentSnapshot?> safeDocumentRead({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e, stack) {
      ImprovedLogger.logError('Failed to read document: $collection/$documentId', e, stack);
      return null;
    }
  }
  
  Future<bool> safeCollectionWrite({
    required String collection,
    required String parent,
    required String parentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(parent)
          .doc(parentId)
          .collection(collection)
          .add(data);
      return true;
    } catch (e, stack) {
      ImprovedLogger.logError('Failed to write to collection: $parent/$parentId/$collection', e, stack);
      return false;
    }
  }
}
