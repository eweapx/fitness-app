import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Utility class for monitoring device connectivity
class ConnectivityManager {
  // Singleton instance
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();
  
  // Instance variables
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  // Getter for the connection status stream
  Stream<bool> get connectivityStream => _connectionStatusController.stream;
  
  // Getter for the current connection status
  bool get isConnected => _isConnected;
  
  /// Initialize the connectivity monitor
  Future<void> initialize() async {
    // Get initial connection status
    await checkConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
      final hasConnection = result != ConnectivityResult.none;
      
      // Only push to stream if there's a change
      if (_isConnected != hasConnection) {
        _isConnected = hasConnection;
        _connectionStatusController.add(hasConnection);
      }
    });
  }
  
  /// Check the current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectionStatusController.close();
  }
}