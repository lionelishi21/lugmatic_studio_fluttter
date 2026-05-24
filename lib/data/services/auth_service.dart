import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _apiClient.dio.post('/auth/google', data: {
        'idToken': idToken,
        'deviceType': 'mobile',
        'role': 'artist',
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}
