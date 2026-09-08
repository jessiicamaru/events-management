import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_constants.dart';
class DioClient {
  final Dio dio;

  DioClient() : dio = Dio(
    BaseOptions(
      baseUrl: kIsWeb 
          ? AppConstants.webBaseUrl 
          : Platform.isAndroid 
              ? AppConstants.androidEmulatorBaseUrl 
              : AppConstants.webBaseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
    ),
  )..interceptors.add(LogInterceptor(responseBody: true));
}
