import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:workupdate/data/network_client_exception.dart';

/// {@template network_client}
/// A wrapper around [Dio] for network requests.
///
/// A [NetworkClientException] is thrown when a request fails.
/// {@endtemplate}
class NetworkClient {
  /// {@macro network_client}
  NetworkClient({
    required Dio dio,
  }) : _dio = dio {
    _configureDio();
    _setupInterceptors();
  }

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw NetworkClientException(_handledDioException(e));
    }
  }

  String _handledDioException(DioException e) {
    late final String message;
    switch (e.type) {
      case DioExceptionType.connectionError:
        message = 'An error occurred connecting to the server';
      case DioExceptionType.connectionTimeout:
        message = 'The connection timed out.';
      case DioExceptionType.cancel:
        message = 'The request was cancelled.';
      case DioExceptionType.badResponse:
        message = _handleBadResponse(e.response!);
      case DioExceptionType.badCertificate:
        message = 'Invalid certificate.';
      case DioExceptionType.sendTimeout:
        message = 'The request took longer than the server was prepared to wait.';
      case DioExceptionType.receiveTimeout:
        message = 'The request took longer than the '
            'server was prepared to wait to receive data.';
      case DioExceptionType.unknown:
        message = 'An unknown error occurred.';
    }
    return message;
  }

  String _handleBadResponse(Response<dynamic> res) {
    if (res.data == null) {
      return switch (res.statusCode) {
        400 => 'Bad request',
        404 => 'The requested resource was not found',
        500 => 'Internal server error',
        _ => 'Something went wrong'
      };
    }

    if (res.data case final Map<String, dynamic> errorResponse) {
      return (errorResponse['message'] as String?) ?? 'Unknown bad response';
    } else {
      return 'Something went wrong';
    }
  }

  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  void _setupInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(
        TalkerDioLogger(
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
          ),
        ),
      );
    }
  }
}
