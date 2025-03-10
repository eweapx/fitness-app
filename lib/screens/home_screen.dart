import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import '../services/auth_service.dart';
import '../services/health_service.dart';
import '../services/voice_service.dart';
import '../utils/logger.dart';
import '../utils/connectivity_manager.dart';
import '../widgets/log_dialog.dart';
import '../widgets/activity_chart.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final HealthService _healthService = HealthService();
  final VoiceService _voiceService = VoiceService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  
  bool _isLoading = true;
  bool _isListening = false;
  bool _isHealthPermissionGranted = false;
  String _userDisplayName = '';
  Map<String, dynamic>? _userProfile;
  String _recognizedSpeech = '';
  String _errorMessage = '';
  bool _isConnected = true;
  
  // Track today's activities
  int _todayCalories = 0;
  int _todayMinutes = 0;
  
  // Subscription for connectivity monitoring
  late StreamSubscription<bool> _connectivitySubscription;
  
  // Timer for auto-refresh
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize voice service
    _voiceService.initialize();
    
    // Monitor connectivity
    _isConnected = _connectivityManager.isConnected;
    _connectivitySubscription = _connectivityManager.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() => _isConnected = isConnected);
        if (isConnected) {
          _refreshData(); // Refresh data when connection is restored
        }
      }
    });
    
    // Initial data load
    _loadData();
    
    // Set up auto-refresh timer (every 15 minutes)
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _refreshData();
    });
    
    // Start auto-tracking health data
    _healthService.startAutoTracking();
    
    // Request notification permissions
    _healthService.requestNotificationPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _refreshTimer?.cancel();
    _healthService.stopAutoTracking();
    _voiceService.dispose();
    super.dispose();
  }
  
  /// Load all necessary data for the home screen
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not logged in';
        });
        return;
      }
      
      // Set user display name
      String displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
      setState(() {
        _userDisplayName = displayName;
      });
      
      // Load user profile
      await _loadUserProfile();
      
      // Check health permissions
      _isHealthPermissionGranted = await _healthService.requestPermissions(context);
      
      // Load today's stats
      await _loadTodayStats();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stack) {
      Logger.logError('Failed to load home screen data', e, stack);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }
  
  /// Reload data (for refresh)
  Future<void> _refreshData() async {
    if (_isLoading) return; // Prevent multiple loads
    
    await _loadUserProfile();
    await _loadTodayStats();
    
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Load the current user's profile
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
    } catch (e) {
      Logger.logError('Failed to load user profile', e);
    }
  }
  
  /// Calculate today's total calories and minutes
  Future<void> _loadTodayStats() async {
    if (!mounted) return;
    
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      // Calculate today's range
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime tomorrow = today.add(const Duration(days: 1));
      
      // Get activities from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activities')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('timestamp', isLessThan: Timestamp.fromDate(tomorrow))
          .get();
      
      int calories = 0;
      int minutes = 0;
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        calories += (data['calories'] as num?)?.toInt() ?? 0;
        minutes += (data['duration'] as num?)?.toInt() ?? 0;
      }
      
      if (mounted) {
        setState(() {
          _todayCalories = calories;
          _todayMinutes = minutes;
        });
      }
    } catch (e, stack) {
      Logger.logError('Failed to load today stats', e, stack);
    }
  }
  
  /// Start voice recognition for activity logging
  Future<void> _startVoiceRecognition() async {
    try {
      // Check microphone permission first
      PermissionStatus status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showPermissionDialog();
        return;
      }
      
      setState(() {
        _isListening = true;
        _recognizedSpeech = 'Listening...';
      });
      
      await _voiceService.startListening((result) {
        if (mounted) {
          setState(() {
            _recognizedSpeech = result;
            _isListening = false;
          });
          
          // Process the voice command
          _voiceService.processActivityCommand(result, context);
        }
      });
    } catch (e, stack) {
      Logger.logError('Failed to start voice recognition', e, stack);
      if (mounted) {
        setState(() {
          _isListening = false;
          _recognizedSpeech = 'Error: $e';
        });
      }
    }
  }
  
  /// Show dialog explaining permission requirements
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to record voice commands. '
          'Please grant this permission to use the voice feature.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Sign out the current user
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e'))
      );
    }
  }
  
  /// Open activity logging dialog
  void _showLogDialog() {
    showDialog(
      context: context,
      builder: (context) => LogDialog(
        onActivityLogged: () {
          _loadTodayStats();
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel'),
        actions: [
          // Profile button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              ).then((_) => _refreshData());
            },
          ),
          // Sign out button
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildHomeContent(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Voice command button
          FloatingActionButton(
            heroTag: 'voice',
            onPressed: _isListening ? null : _startVoiceRecognition,
            backgroundColor: _isListening ? Colors.red : null,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
          const SizedBox(height: 16),
          // Manual log button
          FloatingActionButton(
            heroTag: 'log',
            onPressed: _showLogDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
  
  /// Build error state view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  /// Build main home screen content
  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline warning
            if (!_isConnected)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are currently offline. Some features may be limited.',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Welcome message
            Text(
              'Welcome, $_userDisplayName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Today's date
            Text(
              'Today: ${DateTime.now().toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            
            // Health permissions warning
            if (!_isHealthPermissionGranted)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Health Tracking Limited',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Auto-tracking is disabled because health permissions are not granted.',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        bool granted = await _healthService.requestPermissions(context);
                        if (mounted) {
                          setState(() {
                            _isHealthPermissionGranted = granted;
                          });
                        }
                      },
                      child: const Text('Grant Permissions'),
                    ),
                  ],
                ),
              ),
            
            // Today's stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Calories Burned',
                    '$_todayCalories',
                    'kcal',
                    Colors.orange,
                    Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Time',
                    '$_todayMinutes',
                    'min',
                    Colors.green,
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Activity graph
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Week',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ActivityChart(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Voice recognition status
            if (_recognizedSpeech.isNotEmpty && _recognizedSpeech != 'Listening...')
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Voice Command:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_recognizedSpeech),
                    ],
                  ),
                ),
              ),
            
            // Tips
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Tips',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildTipItem(
                      'Try voice commands like "Running for 30 minutes"',
                      Icons.record_voice_over,
                    ),
                    const Divider(),
                    _buildTipItem(
                      'Track your progress daily for best results',
                      Icons.trending_up,
                    ),
                    if (_userProfile != null && 
                        (_userProfile!['fitness_goals'] == null || 
                         _userProfile!['fitness_goals'].toString().isEmpty))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          _buildTipItem(
                            'Set your fitness goals in your profile',
                            Icons.flag,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Add bottom padding for better scrolling
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
  
  /// Build a stat card widget
  Widget _buildStatCard(String title, String value, String unit, MaterialColor color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a tip item with icon
  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
