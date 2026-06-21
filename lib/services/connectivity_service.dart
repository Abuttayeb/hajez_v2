import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  void init() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      _controller.add(_isConnected);
    });
  }

  void dispose() => _controller.close();
}