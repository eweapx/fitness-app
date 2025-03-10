import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A class to manage network connectivity state
class ConnectivityManager {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  
  // Private constructor
  ConnectivityManager._internal();
  
  // Factory constructor to return the same instance
  factory ConnectivityManager() {
    return _instance;
  }
  
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final _connectivityController = StreamController<ConnectivityResult>.broadcast();
  
  // Getters
  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;
  ConnectivityResult get currentStatus => _connectionStatus;
  bool get isConnected => _connectionStatus != ConnectivityResult.none;
  
  /// Initialize the connectivity manager
  Future<void> initialize() async {
    // Check current connection status
    final result = await _connectivity.checkConnectivity();
    // Use the first result if there are multiple
    _connectionStatus = result.isNotEmpty ? result.first : ConnectivityResult.none;
    _connectivityController.add(_connectionStatus);
    
    // Listen for connection changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      // Use the first result if there are multiple
      final status = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _connectionStatus = status;
      _connectivityController.add(status);
      debugPrint('Connectivity changed: $status');
    });
  }
  
  /// Dispose of resources
  void dispose() {
    _subscription.cancel();
    _connectivityController.close();
  }
  
  /// Check if device is currently connected
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final status = result.isNotEmpty ? result.first : ConnectivityResult.none;
    _connectionStatus = status;
    return status != ConnectivityResult.none;
  }
  
  /// Show a snackbar to indicate no connection
  void showNoConnectionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection available'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  /// Show a snackbar to indicate connection restored
  void showConnectionRestoredSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Internet connection restored'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// Get a descriptive string for the connection type
  String getConnectionTypeString() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  /// Widget to build a connectivity status indicator
  Widget buildConnectivityStatusWidget() {
    return StreamBuilder<ConnectivityResult>(
      stream: connectivityStream,
      initialData: _connectionStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectivityResult.none;
        
        Color iconColor;
        IconData iconData;
        
        switch (status) {
          case ConnectivityResult.wifi:
            iconColor = Colors.green;
            iconData = Icons.wifi;
            break;
          case ConnectivityResult.mobile:
            iconColor = Colors.green;
            iconData = Icons.signal_cellular_4_bar;
            break;
          case ConnectivityResult.none:
            iconColor = Colors.red;
            iconData = Icons.signal_wifi_off;
            break;
          default:
            iconColor = Colors.orange;
            iconData = Icons.wifi_find;
            break;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, color: iconColor, size: 16),
              const SizedBox(width: 4),
              Text(
                getConnectionTypeString(),
                style: TextStyle(color: iconColor, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}