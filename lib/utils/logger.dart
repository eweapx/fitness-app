import 'dart:convert';
import 'dart:developer' as developer;

/// A simple logging utility for the app
class Logger {
  // Logging levels
  static const int _levelVerbose = 0;
  static const int _levelDebug = 1;
  static const int _levelInfo = 2;
  static const int _levelWarning = 3;
  static const int _levelError = 4;
  
  // Current logging level
  static int _currentLevel = _levelDebug;
  
  /// Set the minimum logging level
  static void setLogLevel(int level) {
    _currentLevel = level;
  }
  
  /// Log an event with optional data
  static void logEvent(String message, [Map<String, dynamic>? data]) {
    if (_currentLevel <= _levelInfo) {
      _log('EVENT', message, data);
    }
  }
  
  /// Log an error with optional stack trace
  static void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (_currentLevel <= _levelError) {
      _log('ERROR', message, {
        'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      });
    }
  }
  
  /// Log a warning
  static void logWarning(String message, [Map<String, dynamic>? data]) {
    if (_currentLevel <= _levelWarning) {
      _log('WARNING', message, data);
    }
  }
  
  /// Log debug information
  static void logDebug(String message, [Map<String, dynamic>? data]) {
    if (_currentLevel <= _levelDebug) {
      _log('DEBUG', message, data);
    }
  }
  
  /// Internal logging method
  static void _log(String level, String message, [Map<String, dynamic>? data]) {
    final timestamp = DateTime.now().toIso8601String();
    
    String logMessage = '[$timestamp] $level: $message';
    if (data != null) {
      final dataString = const JsonEncoder.withIndent('  ').convert(data);
      logMessage += '\n$dataString';
    }
    
    developer.log(logMessage);
  }
}