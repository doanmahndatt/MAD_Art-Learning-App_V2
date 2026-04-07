import 'package:flutter/material.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void _show(String message, Color color, {int seconds = 2}) {
    messengerKey.currentState?.hideCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  static void showSuccess(String message) => _show(message, Colors.green);
  static void showError(String message) => _show(message, Colors.red, seconds: 3);
  static void showInfo(String message) => _show(message, Colors.blue);

  static String readableError(Object error) {
    final raw = error.toString();
    if (raw.contains('DioException')) {
      final idx = raw.indexOf(':');
      return idx != -1 ? raw.substring(idx + 1).trim() : 'Request failed';
    }
    return raw;
  }
}
