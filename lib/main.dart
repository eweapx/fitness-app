import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/logger.dart';
import 'utils/connectivity_manager.dart';

// Web Firebase configuration
final FirebaseOptions? defaultFirebaseOptions = kIsWeb 
    ? FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
        authDomain: "fuel-fitness-app.firebaseapp.com",
        projectId: "fuel-fitness-app",
        storageBucket: "fuel-fitness-app.appspot.com",
        messagingSenderId: "123456789012",
        appId: "1:123456789012:web:abc123def456ghi789jkl",
      ) 
    : null;

// Initialize a global FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Create a Completer to track Firebase initialization for safe access
final Completer<FirebaseApp> _firebaseInitCompleter = Completer<FirebaseApp>();
Future<FirebaseApp> get firebaseInitialized => _firebaseInitCompleter.future;

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications early
  try {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        Logger.logEvent("Notification tapped", {"id": response.id});
      },
    );
  } catch (e, stack) {
    Logger.logError('Notifications initialization failed', e, stack);
  }

  // Start Firebase initialization and track it with completer
  try {
    // For development/testing when Firebase initialization might fail
    if (const bool.fromEnvironment('DISABLE_FIREBASE', defaultValue: false)) {
      Logger.logEvent('Firebase initialization skipped in debug mode');
      _firebaseInitCompleter.complete(null);
    } else {
      // Special handling for web platform
      final FirebaseOptions? options = defaultFirebaseOptions;
      if (options != null) {
        Firebase.initializeApp(options: options).then((app) {
          // Configure Firestore offline persistence with safety
          try {
            FirebaseFirestore.instance.settings = 
                const Settings(persistenceEnabled: true, cacheSizeBytes: 10485760); // 10MB cache
            _firebaseInitCompleter.complete(app);
          } catch (e, stack) {
            Logger.logError('Firestore configuration failed', e, stack);
            _firebaseInitCompleter.complete(app); // Still complete to avoid blocking app
          }
        }).catchError((e, stack) {
          Logger.logError('Firebase initialization failed', e, stack);
          // Complete with null instead of error to allow app to run
          _firebaseInitCompleter.complete(null);
        });
      } else {
        // Fallback to auto-detection if no options provided
        Firebase.initializeApp().then((app) {
          _firebaseInitCompleter.complete(app);
        }).catchError((e, stack) {
          Logger.logError('Firebase auto-init failed', e, stack);
          _firebaseInitCompleter.complete(null);
        });
      }
    }
  } catch (e, stack) {
    Logger.logError('Firebase setup error', e, stack);
    _firebaseInitCompleter.complete(null); // Complete with null to avoid blocking app
  }

  // Initialize ConnectivityManager for network status monitoring
  await ConnectivityManager().initialize();
  
  runApp(Fuel());
}

class Fuel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(elevation: 2),
      ),
      home: FutureBuilder<FirebaseApp?>(
        future: firebaseInitialized,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Fuel...'),
                  ],
                ),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('Failed to initialize app'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Firebase.initializeApp().then((app) {
                          _firebaseInitCompleter.complete(app);
                        }).catchError((e, stack) {
                          Logger.logError('Firebase retry failed', e, stack);
                          _firebaseInitCompleter.complete(null);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Even if Firebase is null, we should still show AuthGate,
          // which will handle the authentication state appropriately
          return AuthGate();
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Handle auth error state
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('Authentication Error'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                        } catch (e) {
                          Logger.logError('Sign out error', e);
                        }
                      },
                      child: const Text('Return to Login'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Route to appropriate screen based on auth state
          return snapshot.hasData ? HomeScreen() : LoginScreen();
        },
      );
    } catch (e, stack) {
      // Handle Firebase auth errors
      Logger.logError('Firebase auth error', e, stack);
      
      // Fallback to directly show login screen if Firebase auth fails
      return LoginScreen();
    }
  }
}
