import '../../../core/api/api_client.dart';
import '../models/track_model.dart';
import 'dart:developer' as developer;

class TrackService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Track>> getArtistTracks(String artistId) async {
    try {
      // Point to unified dashboard endpoint that includes primary songs and collaborations
      final response = await _apiClient.dio.get('/users/contributor/dashboard');
      final data = response.data;
      
      // Extraction of unified song list from the data.songs object
      final resultData = data['data'];
      List<dynamic> list = resultData != null ? (resultData['songs'] ?? []) : [];
      
      return list.map((i) => Track.fromJson(i)).toList();
    } catch (e) {
      developer.log('Error fetching tracks: $e');
      rethrow;
    }
  }

  Future<TrackAnalytics> getTrackAnalytics(String trackId, {int days = 30}) async {
    try {
      final response = await _apiClient.dio.get('/song/analytics/$trackId?days=$days');
      final data = response.data;
      
      Map<String, dynamic> json = data.containsKey('data') ? data['data'] : data;
      return TrackAnalytics.fromJson(json);
    } catch (e) {
      developer.log('Error fetching track analytics: $e');
      rethrow;
    }
  }

  Future<bool> deleteTrack(String trackId) async {
    try {
      final response = await _apiClient.dio.delete('/song/delete/$trackId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      developer.log('Error deleting track: $e');
      rethrow;
    }
  }
}
