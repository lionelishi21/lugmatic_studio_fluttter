import '../../core/api/api_client.dart';

class ClashService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getActiveClashes() async {
    try {
      final response = await _apiClient.dio.get('/clash/active');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> enterClash(String clashId) async {
    try {
      final response = await _apiClient.dio.post('/clash/$clashId/enter');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> vote(String clashId, String artistId) async {
    try {
      final response = await _apiClient.dio.post('/clash/$clashId/vote', data: {
        'artistId': artistId,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}
