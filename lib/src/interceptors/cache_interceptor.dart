import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/request_config.dart';

class CacheEntry {
  const CacheEntry({
    required this.data,
    required this.createdAt,
    required this.duration,
  });

  final dynamic data;
  final DateTime createdAt;
  final Duration duration;

  bool get isValid => DateTime.now().difference(createdAt) <= duration;
}

class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final policy = options.extra['meteor.cachePolicy'] as CachePolicy? ??
        CachePolicy.networkOnly;
    if (options.method.toUpperCase() != 'GET' ||
        policy == CachePolicy.networkOnly) {
      return super.onRequest(options, handler);
    }

    final key = _key(options);
    final entry = _cache[key];
    if (entry != null && entry.isValid) {
      if (policy == CachePolicy.cacheOnly ||
          policy == CachePolicy.cacheFirst ||
          policy == CachePolicy.staleWhileRevalidate) {
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: entry.data,
            statusCode: 200,
            extra: {'fromCache': true},
          ),
        );
      }
    }

    if (policy == CachePolicy.cacheOnly) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          message: '缓存不存在或已过期',
        ),
      );
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    final policy = options.extra['meteor.cachePolicy'] as CachePolicy? ??
        CachePolicy.networkOnly;
    if (options.method.toUpperCase() == 'GET' &&
        policy != CachePolicy.networkOnly &&
        response.extra['fromCache'] != true) {
      final duration = options.extra['meteor.cacheDuration'] as Duration? ??
          const Duration(minutes: 5);
      _cache[_key(options)] = CacheEntry(
        data: response.data,
        createdAt: DateTime.now(),
        duration: duration,
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final policy = options.extra['meteor.cachePolicy'] as CachePolicy? ??
        CachePolicy.networkOnly;
    if (options.method.toUpperCase() == 'GET' &&
        policy == CachePolicy.networkFirst) {
      final entry = _cache[_key(options)];
      if (entry != null && entry.isValid) {
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: entry.data,
            statusCode: 200,
            extra: {'fromCache': true},
          ),
        );
      }
    }
    super.onError(err, handler);
  }

  String _key(RequestOptions options) {
    return jsonEncode({
      'method': options.method,
      'uri': options.uri.toString(),
    });
  }
}
