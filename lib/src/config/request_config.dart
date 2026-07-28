enum CachePolicy {
  networkOnly,
  cacheOnly,
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
}

class RetryPolicy {
  const RetryPolicy({
    this.enabled = false,
    this.retries = 2,
    this.delay = const Duration(milliseconds: 500),
    this.retryMethods = const {'GET'},
    this.retryStatusCodes = const {502, 503, 504},
  });

  final bool enabled;
  final int retries;
  final Duration delay;
  final Set<String> retryMethods;
  final Set<int> retryStatusCodes;
}

class RequestConfig {
  const RequestConfig({
    this.headers,
    this.query,
    this.showLoading = false,
    this.silent = false,
    this.deduplicate,
    this.cachePolicy,
    this.cacheDuration = const Duration(minutes: 5),
    this.retryPolicy,
    this.mockData,
    this.idempotencyKey,
    this.enableSign,
    this.traceId,
    this.extra = const {},
  });

  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? query;
  final bool showLoading;
  final bool silent;
  final bool? deduplicate;
  final CachePolicy? cachePolicy;
  final Duration cacheDuration;
  final RetryPolicy? retryPolicy;
  final dynamic mockData;
  final String? idempotencyKey;
  final bool? enableSign;
  final String? traceId;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toExtra() {
    return {
      ...extra,
      'meteor.showLoading': showLoading,
      'meteor.silent': silent,
      'meteor.cachePolicy': cachePolicy,
      'meteor.cacheDuration': cacheDuration,
      'meteor.retryPolicy': retryPolicy,
      'meteor.idempotencyKey': idempotencyKey,
      'meteor.enableSign': enableSign,
      'meteor.traceId': traceId,
    };
  }
}
