import '../../core/api/api_client.dart';

class GiftService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getMyGifts() async {
    try {
      final response = await _apiClient.dio.get('/artist/gifts');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGiftStats() async {
    try {
      final response = await _apiClient.dio.get('/artist/gifts/stats');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}
