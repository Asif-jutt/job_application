import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../utils/app_logger.dart';

class DioClient {
  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.network('REQUEST', '${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.network('RESPONSE', '${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error('Dio error', error, error.stackTrace);
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  Dio get instance => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters);
}
