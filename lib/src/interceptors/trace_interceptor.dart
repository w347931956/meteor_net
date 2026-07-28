import 'package:dio/dio.dart';

class TraceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final traceId = options.extra['meteor.traceId']?.toString() ??
        'mn-${DateTime.now().microsecondsSinceEpoch}';
    options.headers['X-Trace-Id'] = traceId;
    options.extra['meteor.traceId'] = traceId;
    super.onRequest(options, handler);
  }
}
