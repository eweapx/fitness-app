import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Using environment variables for Firebase configuration
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: '000000000000',
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: '${const String.fromEnvironment('FIREBASE_PROJECT_ID')}.firebaseapp.com',
    storageBucket: '${const String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
    measurementId: 'G-00000000',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: '000000000000',
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: '${const String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: '000000000000',
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: '${const String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
    iosClientId: 'ios-client-id',
    iosBundleId: 'com.example.fitnessTracker',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: '000000000000',
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: '${const String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
    iosClientId: 'ios-client-id',
    iosBundleId: 'com.example.fitnessTracker',
  );
}