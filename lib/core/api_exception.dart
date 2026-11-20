import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message, {this.fields = const {}});

  final String message;
  final Map<String, String> fields;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

class TimeoutException extends ApiException {
  const TimeoutException([super.message = 'Сервер не ответил вовремя.']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message, {super.fields});
}

class ValidationException extends ApiException {
  const ValidationException(super.message, {super.fields});
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

Map<String, String> fieldErrors(dynamic body) {
  if (body is! Map) {
    return const {};
  }
  final raw = body['data'] ?? body['errors'];
  if (raw is! Map) {
    return const {};
  }
  final result = <String, String>{};
  raw.forEach((key, value) {
    if (value is Map && value['message'] is String) {
      result['$key'] = value['message'] as String;
    } else if (value != null) {
      result['$key'] = '$value';
    }
  });
  return result;
}

String bodyMessage(dynamic body, String fallback) {
  if (body is Map &&
      body['message'] is String &&
      (body['message'] as String).isNotEmpty) {
    return body['message'] as String;
  }
  return fallback;
}

ApiException mapHttpError(int status, dynamic body) {
  final fields = fieldErrors(body);
  return switch (status) {
    400 || 422 => ValidationException(
      bodyMessage(body, 'Проверьте поля формы.'),
      fields: fields,
    ),
    401 => UnauthorizedException(
      bodyMessage(body, 'Требуется вход в систему.'),
    ),
    403 => ForbiddenException(
      bodyMessage(body, 'Недостаточно прав для этого действия.'),
    ),
    404 => NotFoundException(bodyMessage(body, 'Запись не найдена.')),
    409 => ConflictException(
      bodyMessage(body, 'Операция невозможна.'),
      fields: fields,
    ),
    _ => ServerException(
      bodyMessage(body, 'Неизвестная ошибка (код $status).'),
    ),
  };
}

ApiException mapDioError(DioException error) {
  final existing = error.error;
  if (existing is ApiException) {
    return existing;
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const TimeoutException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    DioExceptionType.badResponse => mapHttpError(
      error.response?.statusCode ?? 0,
      error.response?.data,
    ),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  } on ApiException {
    rethrow;
  }
}
