import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'config.dart';

typedef TokenRefresh = Future<bool> Function();

Dio buildDio({String? Function()? tokenProvider, TokenRefresh? refresh}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
          );
          return;
        }
        handler.next(response);
      },
    ),
  );
  dio.interceptors.add(_ReadRetryInterceptor(dio));
  if (refresh != null) {
    dio.interceptors.add(_RefreshInterceptor(dio, refresh));
  }
  return dio;
}

class _ReadRetryInterceptor extends Interceptor {
  _ReadRetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.requestOptions.extra['skipRetry'] == true) {
      handler.next(error);
      return;
    }
    if (error.requestOptions.method.toUpperCase() != 'GET' ||
        !_network(error)) {
      handler.next(error);
      return;
    }
    var current = error;
    var attempt = 1;
    while (attempt < 3 && _network(current)) {
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      attempt += 1;
      try {
        final options = current.requestOptions;
        options.extra['skipRetry'] = true;
        final response = await _dio.fetch<dynamic>(options);
        handler.resolve(response);
        return;
      } on DioException catch (next) {
        current = next;
      }
    }
    handler.next(current);
  }

  bool _network(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}

class _RefreshInterceptor extends Interceptor {
  _RefreshInterceptor(this._dio, this._refresh);

  final Dio _dio;
  final TokenRefresh _refresh;

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final status = error.response?.statusCode;
    final path = error.requestOptions.path;
    final already = error.requestOptions.extra['authRetried'] == true;
    final authCall =
        path.contains('auth-with-password') || path.contains('auth-refresh');
    if (status != 401 || already || authCall) {
      handler.next(error);
      return;
    }
    final refreshed = await _refresh();
    if (!refreshed) {
      handler.next(error);
      return;
    }
    try {
      final options = error.requestOptions;
      options.extra['authRetried'] = true;
      options.extra['skipRetry'] = true;
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (next) {
      handler.next(next);
    }
  }
}
