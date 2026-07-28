import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../config/request_config.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor(this.dio, this.config);

  final Dio dio;
  final ApiConfig config;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final policy =
        err.requestOptions.extra['meteor.retryPolicy'] as RetryPolicy? ??
            config.defaultRetryPolicy;
    if (!policy.enabled) {
      return super.onError(err, handler);
    }

    final retryCount =
        err.requestOptions.extra['meteor.retryCount'] as int? ?? 0;
    final method = err.requestOptions.method.toUpperCase();
    final statusCode = err.response?.statusCode;
    final retryByStatus =
        statusCode != null && policy.retryStatusCodes.contains(statusCode);
    final retryByNetwork = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    if (retryCount >= policy.retries ||
        !policy.retryMethods.contains(method) ||
        (!retryByStatus && !retryByNetwork)) {
      return super.onError(err, handler);
    }

    err.requestOptions.extra['meteor.retryCount'] = retryCount + 1;
    await Future<void>.delayed(policy.delay * (retryCount + 1));
    try {
      final response = await dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      super.onError(error, handler);
    }
  }
}
