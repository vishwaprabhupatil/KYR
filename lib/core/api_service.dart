import 'dart:io';

import 'package:dio/dio.dart';

import 'constants.dart';

class ApiService {
  ApiService._()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {'Accept': 'application/json'},
          ),
        );

  static final ApiService instance = ApiService._();

  final Dio _dio;

  Future<Response<T>> postJson<T>(
    String path, {
    required Map<String, dynamic> body,
    Options? options,
  }) {
    return _dio.post<T>(path, data: body, options: options);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<dynamic>> postMultipart(
    String path, {
    required File file,
    required String fileField,
    Map<String, dynamic>? fields,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      ...?fields,
      fileField: await MultipartFile.fromFile(file.path, filename: fileName),
    });
    return _dio.post(path, data: formData);
  }

  Future<Response<List<int>>> postBytes(
    String path, {
    required Map<String, dynamic> body,
  }) {
    return _dio.post<List<int>>(
      path,
      data: body,
      options: Options(responseType: ResponseType.bytes),
    );
  }
}
