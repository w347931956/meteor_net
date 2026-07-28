import 'package:dio/dio.dart';

import '../config/api_config.dart';

class HeaderInterceptor extends Interceptor {
  HeaderInterceptor(this.config);

  final ApiConfig config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = config.defaultHeaders?.call();
    if (headers != null && headers.isNotEmpty) {
      options.headers.addAll(headers);
    }

    final idempotencyKey = options.extra['meteor.idempotencyKey'];
    if (idempotencyKey is String && idempotencyKey.isNotEmpty) {
      options.headers['Idempotency-Key'] = idempotencyKey;
    }

    super.onRequest(options, handler);
  }
}
