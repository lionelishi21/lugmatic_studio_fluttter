import '../../../core/api/api_client.dart';

class ArtistService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> updateProfile(String artistId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/artist/update/$artistId', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    try {
      final response = await _apiClient.dio.get('/artist/details/$artistId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
