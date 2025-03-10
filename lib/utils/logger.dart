import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// Log level enum
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// A utility class for logging messages
class Logger {
  static final Logger _instance = Logger._internal();
  
  // Private constructor
  Logger._internal();
  
  // Factory constructor to return the same instance
  factory Logger() {
    return _instance;
  }
  
  // Current log level
  LogLevel _currentLevel = LogLevel.info;
  
  // Set log level
  void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  // Check if a level should be logged
  bool _shouldLog(LogLevel level) {
    return level.index >= _currentLevel.index;
  }
  
  // Format the current time
  String _getCurrentTime() {
    final now = DateTime.now();
    final formatter = DateFormat('HH:mm:ss.SSS');
    return formatter.format(now);
  }
  
  // Format a log message
  String _formatLogMessage(String message, LogLevel level, [String? tag]) {
    final levelName = level.toString().split('.').last.toUpperCase();
    final time = _getCurrentTime();
    final tagString = tag != null ? '[$tag]' : '';
    return '[$time][$levelName]$tagString $message';
  }
  
  // Log a debug message
  void d(String message, [String? tag]) {
    if (_shouldLog(LogLevel.debug)) {
      final formattedMessage = _formatLogMessage(message, LogLevel.debug, tag);
      debugPrint(formattedMessage);
    }
  }
  
  // Log an info message
  void i(String message, [String? tag]) {
    if (_shouldLog(LogLevel.info)) {
      final formattedMessage = _formatLogMessage(message, LogLevel.info, tag);
      debugPrint(formattedMessage);
    }
  }
  
  // Log a warning message
  void w(String message, [String? tag]) {
    if (_shouldLog(LogLevel.warning)) {
      final formattedMessage = _formatLogMessage(message, LogLevel.warning, tag);
      debugPrint('\x1B[33m$formattedMessage\x1B[0m'); // Yellow
    }
  }
  
  // Log an error message
  void e(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.error)) {
      final formattedMessage = _formatLogMessage(message, LogLevel.error, tag);
      
      // Print the error message in red
      debugPrint('\x1B[31m$formattedMessage\x1B[0m'); // Red
      
      // If we have an error object, print it
      if (error != null) {
        debugPrint('\x1B[31mError: $error\x1B[0m');
      }
      
      // If we have a stack trace, print it
      if (stackTrace != null) {
        debugPrint('\x1B[31mStack trace: $stackTrace\x1B[0m');
      }
    }
  }
  
  // Log an exception
  void exception(Object exception, [StackTrace? stackTrace, String? tag]) {
    if (_shouldLog(LogLevel.error)) {
      final message = 'Exception: ${exception.toString()}';
      e(message, tag ?? 'Exception', exception, stackTrace);
    }
  }
}