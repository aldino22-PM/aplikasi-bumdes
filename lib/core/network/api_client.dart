import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());

class ApiClient {
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.timeout,
            receiveTimeout: AppConfig.timeout,
            headers: {'Accept': 'application/json'},
          ),
        );

  final Dio _dio;

  Dio get client => _dio;
}
