import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final userData = await _authService.login(email, password);
    _isLoading = false;
    if (userData != null) {
      _user = User.fromJson(userData);
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password, String fullName, {String? avatarUrl, String? bio}) async {
    _isLoading = true;
    notifyListeners();
    final userData = await _authService.register(email, password, fullName, avatarUrl: avatarUrl, bio: bio);
    _isLoading = false;
    if (userData != null) {
      _user = User.fromJson(userData);
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> loadUserFromToken() async {
    final token = await _authService.getToken();
    if (token != null) {
      // Optionally fetch user profile from /users/profile
    }
  }
}