import '../../../core/api/api_client.dart';

class CommentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getArtistComments() async {
    try {
      final response = await _apiClient.dio.get('/artist/comments');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> replyToComment(String commentId, String content) async {
    try {
      await _apiClient.dio.post('/artist/comments/$commentId/reply', data: {
        'content': content,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _apiClient.dio.delete('/artist/comments/$commentId');
    } catch (e) {
      rethrow;
    }
  }
}
