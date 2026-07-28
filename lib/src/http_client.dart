import 'package:dio/dio.dart';

import 'api_response.dart';
import 'config/request_config.dart';

abstract interface class HttpClient {
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
  });

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
  });

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
  });

  Future<T> upload<T>(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  });

  Future<Response<dynamic>> download(
    String urlPath,
    dynamic savePath, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });
}
