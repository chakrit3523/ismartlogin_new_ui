import 'package:dio/dio.dart';

class NetworkClient {
  NetworkClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<Response<dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<dynamic>(
      url,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<dynamic>> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<dynamic>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
