import '../../../core/api/api_client.dart';

class ClashService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getActiveClashes() async {
    try {
      final response = await _apiClient.dio.get('/clash/list', queryParameters: {'status': 'active'});
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getSchedule() async {
    try {
      final response = await _apiClient.dio.get('/clash/schedule');
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> scheduleClash({
    required String opponentArtistId,
    required DateTime scheduledAt,
    int duration = 1800,
  }) async {
    try {
      final response = await _apiClient.dio.post('/clash/schedule', data: {
        'opponentArtistId': opponentArtistId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'duration': duration,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinScheduledClash(String clashId) async {
    try {
      final response = await _apiClient.dio.post('/clash/schedule/$clashId/join');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> inviteToClash(String opponentArtistId, {int duration = 300}) async {
    try {
      final response = await _apiClient.dio.post('/clash/invite', data: {
        'opponentArtistId': opponentArtistId,
        'duration': duration,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptClash(String clashId) async {
    try {
      final response = await _apiClient.dio.post('/clash/$clashId/accept');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectClash(String clashId) async {
    try {
      final response = await _apiClient.dio.post('/clash/$clashId/reject');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await _apiClient.dio.get('/clash/history');
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
