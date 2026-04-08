import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Timer? _timer;
  bool _started = false;

  Future<void> fetchUnreadCount() async {
    try {
      final res = await _api.get('/notifications/unread-count');
      if (res.statusCode == 200) {
        final count = (res.data['count'] ?? 0) as int;
        if (count != _unreadCount) {
          _unreadCount = count;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void startPolling() {
    if (_started) return;
    _started = true;

    fetchUnreadCount();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchUnreadCount();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    _unreadCount = 0;
    notifyListeners();
  }

  void decrementUnreadIfNeeded() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }
}