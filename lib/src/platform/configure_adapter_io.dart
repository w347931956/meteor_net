import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/api_config.dart';

void configureAdapter(Dio dio, ApiConfig config) {
  if (!config.enableProxy || config.proxy == null || config.proxy!.isEmpty) {
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (_) => 'PROXY ${config.proxy}';
      client.badCertificateCallback = (_, __, ___) => true;
      return client;
    },
  );
}
