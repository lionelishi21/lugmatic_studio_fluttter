import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class UploadService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> uploadContent({
    required File file,
    required File coverArt,
    required String title,
    required String type, // 'song' or 'podcast'
    required String genreId,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      String coverName = coverArt.path.split('/').last;

      FormData formData = FormData.fromMap({
        'title': title,
        'type': type,
        'genreId': genreId,
        'description': description ?? '',
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'coverArt': await MultipartFile.fromFile(coverArt.path, filename: coverName),
      });

      final response = await _apiClient.dio.post(
        '/artist/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getGenres() async {
    try {
      final response = await _apiClient.dio.get('/genres');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPresignedUrl({
    required String type, // 'music-video', 'song-audio', 'cover-art'
    required String filename,
    required String contentType,
  }) async {
    final response = await _apiClient.dio.post('/upload/presign/$type', data: {
      'filename': filename,
      'contentType': contentType,
    });
    return (response.data['data'] ?? response.data) as Map<String, dynamic>;
  }

  Future<void> uploadToS3({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    // Use a separate Dio instance WITHOUT auth headers for S3 PUT
    final s3Dio = Dio();
    await s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable(fileBytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length,
        },
      ),
      onSendProgress: onProgress != null
          ? (sent, total) => onProgress(total > 0 ? sent / total : 0)
          : null,
    );
  }

  Future<String> generateLyrics(String songId) async {
    final response = await _apiClient.dio.post('/song/$songId/generate-lyrics');
    final data = (response.data['data'] ?? response.data) as Map<String, dynamic>;
    return data['lyrics'] as String? ?? '';
  }

  Future<void> updateSongLyrics(String songId, String lyrics) async {
    await _apiClient.dio.put('/song/update/$songId', data: {'lyrics': lyrics});
  }
}
