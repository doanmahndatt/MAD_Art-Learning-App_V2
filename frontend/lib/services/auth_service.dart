import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _api.post('/auth/login', {'email': email, 'password': password});
      if (res.statusCode == 200) {
        await _storage.write(key: 'access_token', value: res.data['token']);
        return res.data['user'];
      }
    } catch (e) {
      print('Login error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> register(String email, String password, String fullName, {String? avatarUrl, String? bio}) async {
    try {
      final res = await _api.post('/auth/register', {
        'email': email,
        'password': password,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'bio': bio,
      });
      if (res.statusCode == 201) {
        await _storage.write(key: 'access_token', value: res.data['token']);
        return res.data['user'];
      }
    } catch (e) {
      print('Register error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}