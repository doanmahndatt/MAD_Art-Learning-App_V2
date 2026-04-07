import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _api = ApiService();
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

  /// Gọi sau khi edit profile thành công — re-fetch từ server để đồng bộ toàn app
  Future<void> refreshUser() async {
    try {
      final res = await _api.get('/users/profile');
      if (res.statusCode == 200) {
        _user = User.fromJson(res.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('refreshUser error: $e');
    }
  }

  Future<void> loadUserFromToken() async {
    final token = await _authService.getToken();
    if (token != null) {
      await refreshUser();
    }
  }
}