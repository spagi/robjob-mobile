import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/storage_service.dart';

class AuthService {
  final Dio _dio;
  final StorageService _storage;

  AuthService({Dio? dio, StorageService? storage})
      : _dio = dio ?? createApiClient(),
        _storage = storage ?? StorageService();

  Future<void> login(String email, String password) async {
    final response = await _dio.post(
      'v1/auth/mobile/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token not returned from server');
    }

    await _storage.saveToken(token);
  }

  Future<void> logout() async {
    try {
      await _dio.post('v1/auth/logout');
    } finally {
      await _storage.deleteToken();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }
}
