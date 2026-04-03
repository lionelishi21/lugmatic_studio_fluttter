import '../../../core/api/api_client.dart';

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

  Future<List<dynamic>> getGifts() async {
    try {
      final response = await _apiClient.dio.get('/gifts');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendGift({
    required String streamId,
    required String giftId,
    required String giftName,
    required int giftValue,
  }) async {
    try {
      final response = await _apiClient.dio.post('/live-stream/$streamId/gift', data: {
        'giftId': giftId,
        'giftName': giftName,
        'giftValue': giftValue,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}

