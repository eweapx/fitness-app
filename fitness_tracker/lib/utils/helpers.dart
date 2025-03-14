import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Date formatting helpers
String formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String formatTime(DateTime time) {
  return DateFormat('hh:mm a').format(time);
}

String formatDateTime(DateTime dateTime) {
  return DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
}

// Get the start and end of a given week
DateTime getStartOfWeek(DateTime date) {
  return date.subtract(Duration(days: date.weekday - 1));
}

DateTime getEndOfWeek(DateTime date) {
  return getStartOfWeek(date).add(const Duration(days: 6));
}

// Firestore timestamp conversion helpers
DateTime timestampToDateTime(Timestamp timestamp) {
  return timestamp.toDate();
}

Timestamp dateTimeToTimestamp(DateTime dateTime) {
  return Timestamp.fromDate(dateTime);
}

// UI Helpers
void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<bool> showConfirmationDialog(
  BuildContext context, 
  String title, 
  String content,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return result ?? false;
}

// Notification helpers
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  required FlutterLocalNotificationsPlugin notifications,
}) async {
  final androidDetails = AndroidNotificationDetails(
    'fitness_channel_id',
    'Fitness Tracker Notifications',
    channelDescription: 'Notifications from the Fitness Tracker app',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  final platformDetails = NotificationDetails(android: androidDetails);
  
  await notifications.schedule(
    id,
    title,
    body,
    scheduledDate,
    platformDetails,
  );
}

// Data validation helpers
bool isValidEmail(String email) {
  final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  return emailRegExp.hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}

// String capitalization helper
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

// Generate a color based on a string (useful for consistent user avatar colors)
Color generateColorFromString(String input) {
  int hash = 0;
  for (var i = 0; i < input.length; i++) {
    hash = input.codeUnitAt(i) + ((hash << 5) - hash);
  }
  
  final hue = (hash % 360).abs();
  return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.6, 0.8).toColor();
}