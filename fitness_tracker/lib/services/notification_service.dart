import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Initialize notification settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
    
    _isInitialized = true;
  }
  
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();
    
    // Request permission (for iOS)
    final result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
    return result ?? false;
  }
  
  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fitness_tracker_channel',
      'Fitness Tracker',
      channelDescription: 'Channel for Fitness Tracker notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  // Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    final androidDetails = const AndroidNotificationDetails(
      'fitness_tracker_scheduled',
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Convert to TZ
    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }
  
  // Schedule a daily notification at a specific time
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Create a DateTime for today with the specified time
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // If the scheduled time is before now, set it for tomorrow
    final effectiveDate = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;
    
    final tzDate = tz.TZDateTime.from(effectiveDate, tz.local);
    
    const androidDetails = AndroidNotificationDetails(
      'fitness_tracker_daily',
      'Daily Reminders',
      channelDescription: 'Channel for daily reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }
  
  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
  
  // Schedule a habit reminder
  Future<void> scheduleHabitReminderNotification(
    String habitId,
    String habitName,
    String message,
    TimeOfDay reminderTime,
  ) async {
    // Generate a unique ID based on the habit ID
    final id = habitId.hashCode;
    
    await scheduleDailyNotification(
      id: id,
      title: 'Habit Reminder: $habitName',
      body: message,
      time: reminderTime,
      payload: 'habit:$habitId',
    );
  }
  
  // Cancel a habit reminder
  Future<void> cancelHabitReminderNotification(String habitId) async {
    final id = habitId.hashCode;
    await cancelNotification(id);
  }
  
  // Show a streak milestone notification
  Future<void> showStreakNotification(String habitName, int streak) async {
    await showNotification(
      title: 'Streak Milestone! 🔥',
      body: 'You\'ve maintained "$habitName" for $streak days in a row! Keep it up!',
      payload: 'streak:$habitName:$streak',
    );
  }
  
  // Show a sleep reminder notification
  Future<void> scheduleSleepReminder(TimeOfDay bedtime) async {
    // Schedule for 30 minutes before bedtime
    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      bedtime.hour,
      bedtime.minute,
    ).subtract(const Duration(minutes: 30));
    
    // If the reminder time is in the past, schedule for tomorrow
    final effectiveDate = reminderTime.isBefore(now)
        ? reminderTime.add(const Duration(days: 1))
        : reminderTime;
    
    await scheduleNotification(
      id: 'sleep_reminder'.hashCode,
      title: 'Bedtime Reminder',
      body: 'Your bedtime is in 30 minutes. Start winding down now for better sleep quality.',
      scheduledTime: effectiveDate,
      payload: 'sleep_reminder',
    );
  }
  
  // Show a water reminder notification
  Future<void> scheduleWaterReminders() async {
    // Schedule reminders throughout the day
    final reminderTimes = [
      const TimeOfDay(hour: 9, minute: 0),   // 9:00 AM
      const TimeOfDay(hour: 11, minute: 30), // 11:30 AM
      const TimeOfDay(hour: 14, minute: 0),  // 2:00 PM
      const TimeOfDay(hour: 16, minute: 30), // 4:30 PM
      const TimeOfDay(hour: 19, minute: 0),  // 7:00 PM
    ];
    
    for (int i = 0; i < reminderTimes.length; i++) {
      await scheduleDailyNotification(
        id: 'water_reminder_$i'.hashCode,
        title: 'Hydration Reminder',
        body: 'Time to drink some water! Stay hydrated for better health.',
        time: reminderTimes[i],
        payload: 'water_reminder:$i',
      );
    }
  }
  
  // Show a meal planning reminder
  Future<void> scheduleMealPlanningReminder() async {
    await scheduleDailyNotification(
      id: 'meal_planning'.hashCode,
      title: 'Meal Planning',
      body: 'Have you planned your meals for tomorrow? A little planning helps maintain healthy eating habits.',
      time: const TimeOfDay(hour: 19, minute: 30), // 7:30 PM
      payload: 'meal_planning',
    );
  }
}