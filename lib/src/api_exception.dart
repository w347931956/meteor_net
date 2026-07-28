import 'package:dio/dio.dart';

enum ApiExceptionType {
  network,
  timeout,
  cancelled,
  server,
  business,
  parse,
  ssl,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.type,
    this.code,
    this.statusCode,
    this.raw,
  });

  final String message;
  final ApiExceptionType type;
  final int? code;
  final int? statusCode;
  final Object? raw;

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    switch (error.type) {
      case DioExceptionType.cancel:
        return ApiException(
          message: '请求已取消',
          type: ApiExceptionType.cancelled,
          statusCode: statusCode,
          raw: error,
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          message: '网络超时，请稍后重试',
          type: ApiExceptionType.timeout,
          statusCode: statusCode,
          raw: error,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          message: '证书校验失败',
          type: ApiExceptionType.ssl,
          statusCode: statusCode,
          raw: error,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: _serverMessage(statusCode),
          type: ApiExceptionType.server,
          statusCode: statusCode,
          raw: error,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: '网络不可用，请检查网络连接',
          type: ApiExceptionType.network,
          statusCode: statusCode,
          raw: error,
        );
      case DioExceptionType.unknown:
        return ApiException(
          message: error.message ?? '未知网络错误',
          type: ApiExceptionType.unknown,
          statusCode: statusCode,
          raw: error,
        );
    }
  }

  static String _serverMessage(int? statusCode) {
    return switch (statusCode) {
      400 => '请求参数错误',
      401 => '登录已过期',
      403 => '没有访问权限',
      404 => '接口不存在',
      429 => '请求过于频繁',
      int value when value >= 500 => '服务器异常，请稍后重试',
      _ => '请求失败',
    };
  }

  @override
  String toString() => 'ApiException($type, $code, $statusCode, $message)';
}
