import '../../core/api/api_client.dart';

class LiveStreamService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createStream({
    required String title,
    String? description,
    String? coverImage,
  }) async {
    try {
      final response = await _apiClient.dio.post('/live/create', data: {
        'title': title,
        'description': description ?? '',
        'coverImage': coverImage ?? '',
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> endStream(String roomId) async {
    try {
      final response = await _apiClient.dio.post('/live/$roomId/end');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getActiveStreams() async {
    try {
      final response = await _apiClient.dio.get('/live/active');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}
