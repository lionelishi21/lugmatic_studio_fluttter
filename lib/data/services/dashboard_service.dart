import '../../../core/api/api_client.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<ArtistDetails> getArtistDetails(String artistId) async {
    try {
      final response = await _apiClient.dio.get('/artist/details/$artistId');
      final data = response.data;
      // Depending on API structure, data could be nested under 'data'
      Map<String, dynamic> json = data.containsKey('data') ? data['data'] : data;
      return ArtistDetails.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  Future<ArtistStats> getArtistStats(String artistId) async {
    try {
      final response = await _apiClient.dio.get('/artist/$artistId/stats');
      final data = response.data;
      Map<String, dynamic> json = data.containsKey('data') ? data['data'] : data;
      return ArtistStats.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  Future<ArtistEarnings> getArtistEarnings() async {
    try {
      final response = await _apiClient.dio.get('/finance/earnings');
      final data = response.data;
      Map<String, dynamic> json = data.containsKey('data') ? data['data'] : data;
      return ArtistEarnings.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }
}
