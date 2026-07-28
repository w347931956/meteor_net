import 'package:dio/dio.dart';

import '../loading/loading_observer.dart';
import 'request_config.dart';

typedef HeaderProvider = Map<String, dynamic> Function();
typedef GlobalQueryProvider = Map<String, dynamic> Function();
typedef BusinessSuccess = bool Function(int code);
typedef BusinessCodeResolver = int Function(Map<String, dynamic> json);
typedef BusinessMessageResolver = String Function(Map<String, dynamic> json);
typedef BusinessDataResolver = dynamic Function(Map<String, dynamic> json);
typedef ErrorMessageMapper = String? Function(int? code, int? statusCode);

class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.sendTimeout = const Duration(seconds: 20),
    this.defaultHeaders,
    this.globalQuery,
    this.successCode = 0,
    this.isBusinessSuccess,
    this.codeResolver,
    this.messageResolver,
    this.dataResolver,
    this.errorMessageMapper,
    this.loadingObserver,
    this.proxy,
    this.enableProxy = false,
    this.enableLog = false,
    this.enableCache = false,
    this.enableRetry = false,
    this.enableDeduplicate = false,
    this.enableTrace = true,
    this.enableSign = false,
    this.enableMock = false,
    this.defaultCachePolicy = CachePolicy.networkOnly,
    this.defaultRetryPolicy = const RetryPolicy(),
    this.extraInterceptors = const [],
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final HeaderProvider? defaultHeaders;
  final GlobalQueryProvider? globalQuery;
  final int successCode;
  final BusinessSuccess? isBusinessSuccess;
  final BusinessCodeResolver? codeResolver;
  final BusinessMessageResolver? messageResolver;
  final BusinessDataResolver? dataResolver;
  final ErrorMessageMapper? errorMessageMapper;
  final LoadingObserver? loadingObserver;

  /// Example: `127.0.0.1:8888`. Only applied on IO platforms.
  final String? proxy;
  final bool enableProxy;

  final bool enableLog;
  final bool enableCache;
  final bool enableRetry;
  final bool enableDeduplicate;
  final bool enableTrace;
  final bool enableSign;
  final bool enableMock;

  final CachePolicy defaultCachePolicy;
  final RetryPolicy defaultRetryPolicy;
  final List<Interceptor> extraInterceptors;

  BaseOptions toBaseOptions() {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      responseType: ResponseType.json,
    );
  }
}
