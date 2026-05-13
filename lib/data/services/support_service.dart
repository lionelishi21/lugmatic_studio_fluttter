import '../../../core/api/api_client.dart';
import 'dart:developer' as developer;

class SupportService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> createSupportTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    try {
      final response = await _apiClient.dio.post('/support/tickets', data: {
        'subject': subject,
        'category': category,
        'message': message,
      });
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      developer.log('Error creating support ticket: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getTicketHistory() async {
    try {
      final response = await _apiClient.dio.get('/support/tickets');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}
