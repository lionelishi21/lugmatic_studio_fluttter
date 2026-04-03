import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://api.lugmaticmusic.com/api';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await _storage.read(key: 'refreshToken');
            if (refreshToken != null) {
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final res = await refreshDio.post('/auth/refresh-token', data: {
                'refreshToken': refreshToken,
              });
              final newAccessToken = res.data['data']['accessToken'];
              final newRefreshToken = res.data['data']['refreshToken'];
              await _storage.write(key: 'accessToken', value: newAccessToken);
              if (newRefreshToken != null) {
                await _storage.write(key: 'refreshToken', value: newRefreshToken);
              }
              // Retry the original request with new token
              final opts = e.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(opts);
              _isRefreshing = false;
              return handler.resolve(retryResponse);
            }
          } catch (_) {
            // Refresh failed — clear tokens so app redirects to login
            await _storage.delete(key: 'accessToken');
            await _storage.delete(key: 'refreshToken');
          }
          _isRefreshing = false;
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
