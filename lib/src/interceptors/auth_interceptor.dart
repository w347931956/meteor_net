import 'package:dio/dio.dart';

abstract interface class AuthTokenProvider {
  Future<String?> getAccessToken();

  Future<String?> refreshAccessToken();

  Future<void> onUnauthorized();
}

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this.dio, this.provider);

  final Dio dio;
  final AuthTokenProvider provider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await provider.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final retried = err.requestOptions.extra['meteor.authRetried'] == true;
    if (statusCode != 401 || retried) {
      return handler.next(err);
    }

    final newToken = await provider.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      await provider.onUnauthorized();
      return handler.next(err);
    }

    err.requestOptions.extra['meteor.authRetried'] = true;
    err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
    try {
      final response = await dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}
