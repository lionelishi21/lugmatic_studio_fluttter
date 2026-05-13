import '../../../core/api/api_client.dart';
import 'dart:developer' as developer;

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getNotifications({int page = 1, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get('/notifications?page=$page&limit=$limit');
      final data = response.data;
      // Handle different response structures
      if (data['data'] is List) return data['data'];
      if (data['data'] != null && data['data']['data'] is List) return data['data']['data'];
      return [];
    } catch (e) {
      developer.log('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread/count');
      return response.data['data']?['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiClient.dio.put('/notifications/$id/read');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.put('/notifications/read/all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _apiClient.dio.delete('/notifications/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
