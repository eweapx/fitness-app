import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_constants.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue with the app even if Firebase fails to initialize
    // This allows local development without Firebase credentials
  }
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create auth service first
    final authService = AuthService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: authService)),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: AppConstants.appName,
      theme: themeProvider.themeData,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      // Add responsive settings for web platform
      builder: (context, child) {
        // Apply font sizes and responsive adjustments when on web
        if (kIsWeb) {
          return MediaQuery(
            // Adjust for comfortable viewing on web
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
            ),
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}