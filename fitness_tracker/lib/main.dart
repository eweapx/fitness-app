import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import Firebase options
import 'firebase_options.dart';

// Import screens
import 'screens/dashboard.dart';
import 'screens/activity_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/login.dart';
import 'screens/activity_tab_screen.dart';
import 'screens/nutrition_tab_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/meal_planner_screen.dart';
import 'screens/water_tracking_screen.dart';
import 'screens/progress_screen.dart';

// Import services and utils
import 'services/firebase_service.dart';
import 'services/step_tracking_service.dart';
import 'utils/constants.dart';
import 'widgets/common_widgets.dart';

// Initialize local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initialize Firebase & Local Notifications
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      // Handle notification tap
    },
  );
  
  // Initialize Firebase with configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // We'll continue without Firebase for now, but features requiring Firebase will not work
  }
  
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health & Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColors.background,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(elevation: 2),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(elevation: 2),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/activity': (context) => const ActivityScreen(),
        '/nutrition': (context) => const NutritionScreen(),
        '/workout': (context) => const WorkoutScreen(),
        '/meal_planner': (context) => const MealPlannerScreen(),
        '/water_tracker': (context) => const WaterTrackingScreen(),
        '/progress': (context) => const ProgressScreen(),
      },
    );
  }
}

/// Authentication Flow
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingIndicator(message: 'Loading your fitness data...'),
          );
        }
        
        // In a production app, we would uncomment this line to implement real authentication
        // return snapshot.hasData ? const HomeScreen() : const LoginScreen();
        
        // For development and testing, we'll bypass authentication
        return const HomeScreen();
      },
    );
  }
}

/// Home Screen with Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isConnected = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  // Import our new screens
  final List<Widget> _pages = [
    const DashboardScreen(),
    const ActivityTabScreen(),
    const NutritionTabScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() => _isConnected = result != ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isConnected = result != ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      // Show connectivity indicator
      bottomSheet: !_isConnected
          ? Container(
              color: Colors.red,
              height: 24,
              child: const Center(
                child: Text(
                  'You are offline. Some features may be unavailable.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          : null,
      // Add a floating action button for quick access to workout tracking
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WorkoutScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.fitness_center),
      ),
    );
  }
}
