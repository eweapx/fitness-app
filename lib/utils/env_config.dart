import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Class to manage environment variables and configuration
class EnvConfig {
  // Private constructor
  EnvConfig._();
  
  /// Get the Firebase API key from environment variables
  static String? getFirebaseApiKey() {
    try {
      // For web environment
      if (kIsWeb) {
        // Web environment configuration would go here
        return const String.fromEnvironment('FIREBASE_API_KEY');
      } 
      // For mobile environment
      else {
        // Try to get from platform environment variables
        return Platform.environment['FIREBASE_API_KEY'];
      }
    } catch (e) {
      debugPrint('Error retrieving Firebase API key: $e');
      return null;
    }
  }
  
  /// Check if all required environment variables are set
  static bool checkRequiredEnvVars() {
    final apiKey = getFirebaseApiKey();
    
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('FIREBASE_API_KEY environment variable is not set');
      return false;
    }
    
    return true;
  }
}