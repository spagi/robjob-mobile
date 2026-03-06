import 'package:dio/dio.dart';
import 'storage_service.dart';

final storageService = StorageService();

Dio createApiClient({void Function()? onUnauthorized}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://test-api.robjob.cz/api/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 3600),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Auth interceptor — injects Bearer token from SecureStorage
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await storageService.deleteToken();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
