import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

typedef Signer = String Function(SignPayload payload);

class SignPayload {
  const SignPayload({
    required this.method,
    required this.path,
    required this.timestamp,
    required this.nonce,
    required this.query,
    required this.body,
  });

  final String method;
  final String path;
  final int timestamp;
  final String nonce;
  final Map<String, dynamic> query;
  final dynamic body;
}

class HmacSha256Signer {
  const HmacSha256Signer(this.secret);

  final String secret;

  String call(SignPayload payload) {
    final canonical = jsonEncode({
      'method': payload.method,
      'path': payload.path,
      'timestamp': payload.timestamp,
      'nonce': payload.nonce,
      'query': payload.query,
      'body': payload.body,
    });
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(canonical)).toString();
  }
}

class SignInterceptor extends Interceptor {
  SignInterceptor(this.signer);

  final Signer signer;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final enabled = options.extra['meteor.enableSign'] as bool? ?? true;
    if (!enabled) {
      return super.onRequest(options, handler);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = 'n$timestamp';
    final sign = signer(
      SignPayload(
        method: options.method,
        path: options.path,
        timestamp: timestamp,
        nonce: nonce,
        query: options.queryParameters,
        body: options.data,
      ),
    );
    options.headers['X-Timestamp'] = '$timestamp';
    options.headers['X-Nonce'] = nonce;
    options.headers['X-Sign'] = sign;
    super.onRequest(options, handler);
  }
}
