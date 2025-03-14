import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase configuration for the application
class FirebaseConfig {
  // Firebase options for Web platform
  static FirebaseOptions get webOptions => FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
        appId: const String.fromEnvironment('FIREBASE_APP_ID'),
        messagingSenderId: '', // Not required for basic functionality
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        authDomain: '${const String.fromEnvironment('FIREBASE_PROJECT_ID')}.firebaseapp.com',
        storageBucket: '${const String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
        measurementId: '', // Not required for basic functionality
      );

  // Get the appropriate Firebase options based on platform
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return webOptions;
    }
    
    // For future mobile platform support
    // We'll implement these when needed
    throw UnsupportedError(
      'FirebaseConfig has not been configured for this platform',
    );
  }
}