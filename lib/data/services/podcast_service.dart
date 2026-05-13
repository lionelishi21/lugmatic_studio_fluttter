import '../../../core/api/api_client.dart';
import 'dart:developer' as developer;

class PodcastService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getArtistPodcasts(String artistId) async {
    try {
      final response = await _apiClient.dio.get('/podcasts/artist/$artistId');
      final data = response.data;
      return data['data'] ?? [];
    } catch (e) {
      developer.log('Error fetching podcasts: $e');
      rethrow;
    }
  }

  Future<bool> deletePodcast(String id) async {
    try {
      final response = await _apiClient.dio.delete('/podcasts/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      developer.log('Error deleting podcast: $e');
      rethrow;
    }
  }

  Future<bool> togglePublishStatus(String id, bool isPublished) async {
    try {
      final response = await _apiClient.dio.put('/podcasts/$id/publish', data: {
        'isPublished': isPublished,
      });
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error toggling publish status: $e');
      rethrow;
    }
  }
}
