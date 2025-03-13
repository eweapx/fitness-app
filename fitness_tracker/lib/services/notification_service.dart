import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:math';
import 'dart:io' show Platform;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Notification channel IDs for different types of reminders
  static const String _channelId = 'fitness_reminders';
  static const String _channelName = 'Fitness Reminders';
  static const String _channelDescription = 'Reminders for fitness activities, water intake, and more';
  
  // Notification IDs for different types of reminders
  final Map<String, int> _notificationIds = {
    'Water Intake': 1001,
    'Workouts': 1002,
    'Meal Tracking': 1003,
    'Sleep Tracking': 1004,
    'Step Goals': 1005,
    'Weight Tracking': 1006,
  };
  
  // Initialize notifications
  Future<void> init() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          onDidReceiveLocalNotification:
              (int id, String? title, String? body, String? payload) async {
            // Handle iOS notification when app is in foreground
          },
        );
    
    // Initialization settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // This can be used to navigate to specific screens when notifications are tapped
    print("Notification tapped: ${response.payload}");
  }
  
  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? result = await androidImplementation?.requestPermission();
      return result ?? true; // Default to true for older Android versions
    }
    return true;
  }
  
  // Schedule a reminder notification
  Future<void> scheduleReminderNotification(String reminderType, String message) async {
    // Get notification ID for this reminder type
    final int notificationId = _notificationIds[reminderType] ?? 
                               (1000 + Random().nextInt(1000)); // Fallback to random ID
    
    // Notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Fitness Reminder',
          icon: '@mipmap/ic_launcher',
        );
    
    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Calculate notification time based on reminder type
    // For real use case, these would be customized based on user preferences
    DateTime scheduledTime = _getScheduledTimeFor(reminderType);
    
    // Schedule notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Fitness Reminder',
      message,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderType, // Used to identify notification when tapped
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
    );
  }
  
  // Cancel specific reminder notifications
  Future<void> cancelReminderNotification(String reminderType) async {
    final int? notificationId = _notificationIds[reminderType];
    if (notificationId != null) {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Calculate scheduled time for different reminder types
  DateTime _getScheduledTimeFor(String reminderType) {
    final now = DateTime.now();
    
    switch (reminderType) {
      case 'Water Intake':
        // Remind every 2 hours from 8 AM to 8 PM
        final currentHour = now.hour;
        final nextReminderHour = (currentHour ~/ 2 * 2) + 2; // Round to nearest 2 hour and add 2
        return DateTime(
          now.year, 
          now.month, 
          now.day, 
          nextReminderHour > 20 ? 8 : nextReminderHour, // Reset to 8 AM next day if after 8 PM
          0,
        );
        
      case 'Workouts':
        // Remind at 6 AM for morning workouts
        return DateTime(now.year, now.month, now.day, 6, 0);
        
      case 'Meal Tracking':
        // Remind at meal times: breakfast (7 AM), lunch (12 PM), dinner (7 PM)
        final currentHour = now.hour;
        int reminderHour;
        
        if (currentHour < 7) {
          reminderHour = 7; // Breakfast
        } else if (currentHour < 12) {
          reminderHour = 12; // Lunch
        } else if (currentHour < 19) {
          reminderHour = 19; // Dinner
        } else {
          reminderHour = 7; // Breakfast next day
        }
        
        return DateTime(now.year, now.month, now.day, reminderHour, 0);
        
      case 'Sleep Tracking':
        // Remind at 9 PM for sleep tracking
        return DateTime(now.year, now.month, now.day, 21, 0);
        
      case 'Step Goals':
        // Remind at noon to check step progress
        return DateTime(now.year, now.month, now.day, 12, 0);
        
      case 'Weight Tracking':
        // Remind at 7 AM for consistent weight tracking
        return DateTime(now.year, now.month, now.day, 7, 0);
        
      default:
        // Default to noon
        return DateTime(now.year, now.month, now.day, 12, 0);
    }
  }
  
  // Show immediate notification
  Future<void> showImmediateNotification(String title, String body) async {
    // Notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Fitness Alert',
          icon: '@mipmap/ic_launcher',
        );
    
    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Show notification
    await _flutterLocalNotificationsPlugin.show(
      Random().nextInt(100000), // Random ID to avoid conflicts
      title,
      body,
      platformChannelSpecifics,
      payload: 'immediate',
    );
  }
  
  // Check if notifications are enabled at the system level
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS) {
      // For iOS, we can check authorization status
      final settings = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.getNotificationAppLaunchDetails();
      return settings?.didNotificationLaunchApp ?? false;
    } else if (Platform.isAndroid) {
      // For Android, we can check if the channel is enabled
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      final areEnabled = await androidImplementation?.areNotificationsEnabled();
      return areEnabled ?? false;
    }
    return false;
  }
  
  // Show goal achievement notification
  Future<void> showGoalAchievementNotification(String goalType, String achievement) async {
    await showImmediateNotification(
      'Goal Achieved! 🎉',
      'You reached your $goalType goal: $achievement',
    );
  }
  
  // Show streak notification (for habit tracking)
  Future<void> showStreakNotification(String habitName, int days) async {
    await showImmediateNotification(
      'Streak Milestone! 🔥',
      'You maintained your $habitName habit for $days days in a row!',
    );
  }
  
  // AI insight notification
  Future<void> showAIInsightNotification(String insight) async {
    await showImmediateNotification(
      'AI Health Insight 🧠',
      insight,
    );
  }
}