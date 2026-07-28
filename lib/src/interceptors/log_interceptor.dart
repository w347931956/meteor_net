import 'package:dio/dio.dart';

class MeteorLogInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'authorization',
    'token',
    'access-token',
    'refresh-token',
    'password',
    'phone',
    'email',
    'idcard',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['meteor.startedAt'] = DateTime.now();
    print(
      '[MeteorNet] --> ${options.method} ${options.uri}\n'
      'headers=${_maskMap(options.headers)}\n'
      'query=${_maskMap(options.queryParameters)}\n'
      'body=${_maskValue(options.data)}',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final duration = _duration(response.requestOptions);
    print(
      '[MeteorNet] <-- ${response.statusCode} '
      '${response.requestOptions.method} ${response.requestOptions.uri} '
      '${duration}ms\n'
      'response=${_maskValue(response.data)}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final duration = _duration(err.requestOptions);
    print(
      '[MeteorNet] xx> ${err.response?.statusCode} '
      '${err.requestOptions.method} ${err.requestOptions.uri} '
      '${duration}ms\n'
      'error=${err.message}\n'
      'response=${_maskValue(err.response?.data)}',
    );
    super.onError(err, handler);
  }

  int _duration(RequestOptions options) {
    final startedAt = options.extra['meteor.startedAt'];
    if (startedAt is DateTime) {
      return DateTime.now().difference(startedAt).inMilliseconds;
    }
    return 0;
  }

  dynamic _maskValue(dynamic value) {
    if (value is Map) {
      return _maskMap(value);
    }
    if (value is List) {
      return value.map(_maskValue).toList();
    }
    return value;
  }

  Map<dynamic, dynamic> _maskMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      final lowerKey = key.toString().toLowerCase();
      final shouldMask = _sensitiveKeys.any(lowerKey.contains);
      return MapEntry(key, shouldMask ? '******' : _maskValue(value));
    });
  }
}
