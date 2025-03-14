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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '${String.fromEnvironment('FIREBASE_API_KEY')}',
    appId: '${String.fromEnvironment('FIREBASE_APP_ID')}',
    messagingSenderId: '000000000000',
    projectId: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}',
    authDomain: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}.firebaseapp.com',
    storageBucket: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
    measurementId: 'G-00000000',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${String.fromEnvironment('FIREBASE_API_KEY')}',
    appId: '${String.fromEnvironment('FIREBASE_APP_ID')}',
    messagingSenderId: '000000000000',
    projectId: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}',
    storageBucket: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '${String.fromEnvironment('FIREBASE_API_KEY')}',
    appId: '${String.fromEnvironment('FIREBASE_APP_ID')}',
    messagingSenderId: '000000000000',
    projectId: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}',
    storageBucket: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
    iosClientId: 'ios-client-id',
    iosBundleId: 'com.example.fitnessTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '${String.fromEnvironment('FIREBASE_API_KEY')}',
    appId: '${String.fromEnvironment('FIREBASE_APP_ID')}',
    messagingSenderId: '000000000000',
    projectId: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}',
    storageBucket: '${String.fromEnvironment('FIREBASE_PROJECT_ID')}.appspot.com',
    iosClientId: 'ios-client-id',
    iosBundleId: 'com.example.fitnessTracker',
  );
}