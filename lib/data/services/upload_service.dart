import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

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
}
