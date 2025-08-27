import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _isConnected = false;

  ConnectivityResult get connectivityResult => _connectivityResult;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _initConnectivity();
    _setupConnectivityStream();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
    } catch (e) {
      _updateConnectivityStatus(ConnectivityResult.none);
    }
  }

  void _setupConnectivityStream() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _updateConnectivityStatus(result);
      },
      onError: (error) {
        _updateConnectivityStatus(ConnectivityResult.none);
      },
    );
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    _connectivityResult = result;
    _isConnected = result != ConnectivityResult.none;
    notifyListeners();
  }

  String getConnectionStatusText() {
    switch (_connectivityResult) {
      case ConnectivityResult.wifi:
        return 'WiFi Connected';
      case ConnectivityResult.mobile:
        return 'Mobile Data Connected';
      case ConnectivityResult.ethernet:
        return 'Ethernet Connected';
      case ConnectivityResult.vpn:
        return 'VPN Connected';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth Connected';
      case ConnectivityResult.other:
        return 'Other Connection';
      case ConnectivityResult.none:
      default:
        return 'No Internet Connection';
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
