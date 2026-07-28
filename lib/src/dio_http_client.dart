import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_response.dart';
import 'config/api_config.dart';
import 'config/request_config.dart';
import 'http_client.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import 'interceptors/header_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/sign_interceptor.dart';
import 'interceptors/trace_interceptor.dart';
import 'platform/adapter.dart';

class DioHttpClient implements HttpClient {
  DioHttpClient({
    required this.config,
    Dio? dio,
    AuthTokenProvider? authTokenProvider,
    Signer? signer,
  }) : dio = dio ?? Dio(config.toBaseOptions()) {
    configureAdapter(this.dio, config);
    this.dio.interceptors.add(HeaderInterceptor(config));
    if (config.enableTrace) {
      this.dio.interceptors.add(TraceInterceptor());
    }
    if (config.enableSign && signer != null) {
      this.dio.interceptors.add(SignInterceptor(signer));
    }
    if (authTokenProvider != null) {
      this.dio.interceptors.add(AuthInterceptor(this.dio, authTokenProvider));
    }
    if (config.enableCache) {
      this.dio.interceptors.add(CacheInterceptor());
    }
    if (config.enableRetry) {
      this.dio.interceptors.add(RetryInterceptor(this.dio, config));
    }
    this.dio.interceptors.addAll(config.extraInterceptors);
    if (config.enableLog) {
      this.dio.interceptors.add(MeteorLogInterceptor());
    }
  }

  final ApiConfig config;
  final Dio dio;
  final Map<String, Future<dynamic>> _pending = {};

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      fromJson: fromJson,
      config: config,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _request<T>(
      'POST',
      path,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
      config: config,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'PUT',
      path,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
      config: config,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'PATCH',
      path,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
      config: config,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'DELETE',
      path,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
      config: config,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<T> upload<T>(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
      config: config,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  @override
  Future<Response<dynamic>> download(
    String urlPath,
    dynamic savePath, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    final requestConfig = config ?? const RequestConfig();
    return dio.download(
      urlPath,
      savePath,
      queryParameters: _mergeQuery(queryParameters, requestConfig),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      options: Options(extra: requestConfig.toExtra()),
    );
  }

  Future<T> _request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    RequestConfig? config,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final requestConfig = config ?? const RequestConfig();
    if (this.config.enableMock && requestConfig.mockData != null) {
      return Future.value(_parse<T>(requestConfig.mockData, fromJson));
    }

    final shouldDeduplicate =
        requestConfig.deduplicate ?? this.config.enableDeduplicate;
    final key = _deduplicateKey(method, path, queryParameters, data);
    if (shouldDeduplicate && _pending.containsKey(key)) {
      return _pending[key]!.then((value) => value as T);
    }

    final future = _execute<T>(
      method,
      path,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
      config: requestConfig,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    if (!shouldDeduplicate) {
      return future;
    }

    _pending[key] = future;
    return future.whenComplete(() => _pending.remove(key));
  }

  Future<T> _execute<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? fromJson,
    required RequestConfig config,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    _startLoading(config);
    final startedAt = DateTime.now();
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: _mergeQuery(queryParameters, config),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          method: method,
          headers: config.headers,
          extra: config.toExtra(),
        ),
      );
      response.extra['durationMs'] =
          DateTime.now().difference(startedAt).inMilliseconds;
      return _handleResponse<T>(response, fromJson);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } on FormatException catch (error) {
      throw ApiException(
        message: '数据解析失败',
        type: ApiExceptionType.parse,
        raw: error,
      );
    } catch (error) {
      throw ApiException(
        message: error.toString(),
        type: ApiExceptionType.unknown,
        raw: error,
      );
    } finally {
      _endLoading(config);
    }
  }

  T _handleResponse<T>(Response<dynamic> response, JsonParser<T>? fromJson) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final code = config.codeResolver?.call(body) ?? body['code'] as int? ?? 0;
      final message = config.messageResolver?.call(body) ??
          body['message']?.toString() ??
          '';
      final success =
          config.isBusinessSuccess?.call(code) ?? code == config.successCode;
      if (!success) {
        throw ApiException(
          message: config.errorMessageMapper?.call(code, response.statusCode) ??
              message.ifEmpty('业务请求失败'),
          type: ApiExceptionType.business,
          code: code,
          statusCode: response.statusCode,
          raw: response,
        );
      }
      final data = config.dataResolver?.call(body) ??
          (body.containsKey('data') ? body['data'] : body);
      return _parse<T>(data, fromJson);
    }

    return _parse<T>(body, fromJson);
  }

  T _parse<T>(dynamic data, JsonParser<T>? fromJson) {
    if (fromJson != null) {
      return fromJson(data);
    }
    if (data is T) {
      return data;
    }
    return data as T;
  }

  Map<String, dynamic>? _mergeQuery(
    Map<String, dynamic>? query,
    RequestConfig requestConfig,
  ) {
    final global = config.globalQuery?.call();
    final requestQuery = requestConfig.query;
    if (global == null && requestQuery == null && query == null) {
      return null;
    }
    return {...?global, ...?requestQuery, ...?query};
  }

  void _startLoading(RequestConfig config) {
    if (config.showLoading) {
      this.config.loadingObserver?.onRequestStart();
    }
  }

  void _endLoading(RequestConfig config) {
    if (config.showLoading) {
      this.config.loadingObserver?.onRequestEnd();
    }
  }

  String _deduplicateKey(
    String method,
    String path,
    Map<String, dynamic>? query,
    dynamic data,
  ) {
    return jsonEncode({
      'method': method,
      'path': path,
      'query': query,
      'data': data,
    });
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
