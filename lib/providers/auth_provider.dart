import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/services/auth_service.dart';
import '../data/services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _token;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    _token = await _storage.read(key: 'accessToken');
    if (_token != null) {
      try {
        _user = await _authService.getMe();
        SocketService().connect();
      } catch (e) {
        // Token might be invalid or expired
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      _token = data['accessToken'];
      _user = data['user'];

      await _storage.write(key: 'accessToken', value: _token);
      await _storage.write(key: 'refreshToken', value: data['refreshToken']);

      SocketService().connect();
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    SocketService().disconnect();
    notifyListeners();
  }
  
  Future<void> getMe() async {
    try {
      _user = await _authService.getMe();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
