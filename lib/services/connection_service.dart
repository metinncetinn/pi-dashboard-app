import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

class ConnectionService extends ChangeNotifier {
  static final ConnectionService _instance = ConnectionService._();
  static ConnectionService get instance => _instance;
  ConnectionService._();

  bool _connected = false;
  bool _checking = false;
  Timer? _timer;

  bool get connected => _connected;
  bool get checking => _checking;

  void startMonitoring() {
    _check();
    // 10 saniyede bir kontrol et
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    notifyListeners();
    try {
      final api = await ApiService.getInstance();
      final dio = api.createQuickDio(); // 3 saniyelik timeout
      await dio.get('/api/weather');
      if (!_connected) {
        _connected = true;
        notifyListeners();
      }
    } catch (_) {
      if (_connected) {
        _connected = false;
        notifyListeners();
      }
    }
    _checking = false;
    notifyListeners();
  }

  Future<void> checkNow() => _check();
}