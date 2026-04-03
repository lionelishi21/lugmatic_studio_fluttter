import '../../../core/api/api_client.dart';

class LiveStreamService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createStream({
    required String title,
    String? description,
    String? category,
    String? coverImage,
    bool chatEnabled = true,
    bool giftsEnabled = true,
  }) async {
    try {
      final response = await _apiClient.dio.post('/live-stream', data: {
        'title': title,
        'description': description ?? '',
        'category': category ?? 'music',
        'coverImage': coverImage ?? '',
        'chatEnabled': chatEnabled,
        'giftsEnabled': giftsEnabled,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStreamToken(String streamId) async {
    try {
      final response = await _apiClient.dio.get('/live-stream/$streamId/token');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> endStream(String streamId) async {
    try {
      final response = await _apiClient.dio.put('/live-stream/$streamId/end');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getActiveStreams() async {
    try {
      final response = await _apiClient.dio.get('/live-stream/active');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}

