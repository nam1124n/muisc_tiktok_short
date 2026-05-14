import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_task_model.dart';

class AudioGenerationRemoteDataSource {
  AudioGenerationRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<GeneratedAudioTaskModel> generateAudioTask({
    required String userId,
    required String prompt,
  }) async {
    final response = await _runRequest(() {
      return _dio.post<dynamic>(
        '/api/generate',
        data: {'userId': userId, 'user_id': userId, 'prompt': prompt},
      );
    });

    final body = _decodeBodyAsMap(
      response.data,
      fallbackBody: response.data is String ? response.data as String : null,
    );
    _throwIfRequestFailed(
      response,
      body,
      defaultMessage: 'Không thể tạo audio AI.',
    );

    final task = GeneratedAudioTaskModel.fromJson(body);
    if (task.id.isEmpty) {
      throw Exception('Worker không trả về taskId hợp lệ.');
    }

    return task;
  }

  Future<GeneratedAudioTaskModel> getGenerationStatus(String taskId) async {
    final response = await _runRequest(() {
      return _dio.get<dynamic>(
        '/api/generations/${Uri.encodeComponent(taskId)}',
      );
    });

    final body = _decodeBodyAsMap(
      response.data,
      fallbackBody: response.data is String ? response.data as String : null,
    );
    _throwIfRequestFailed(
      response,
      body,
      defaultMessage: 'Không thể lấy trạng thái tạo audio.',
    );

    final task = GeneratedAudioTaskModel.fromJson(body);
    if (task.id.isEmpty) {
      throw Exception('Worker không trả về taskId hợp lệ.');
    }

    return task;
  }

  Future<Response<dynamic>> _runRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      final baseUrl = _normalizeBaseUrl(_dio.options.baseUrl);
      if (_isTimeout(error)) {
        throw Exception(AppConfig.buildAudioGenerationTimeoutMessage(baseUrl));
      }

      if (_isConnectionError(error)) {
        throw Exception(
          AppConfig.buildAudioGenerationConnectionErrorMessage(
            baseUrl,
            details: error.message,
          ),
        );
      }

      final body = _decodeBodyAsMap(
        error.response?.data,
        fallbackBody: error.response?.data is String
            ? error.response?.data as String
            : null,
      );
      final statusCode = error.response?.statusCode ?? 500;
      final message =
          body['error']?.toString() ??
          body['message']?.toString() ??
          'Worker request failed ($statusCode)';

      throw Exception(message);
    }
  }

  Map<String, dynamic> _decodeBodyAsMap(Object? data, {String? fallbackBody}) {
    if (data == null) {
      return <String, dynamic>{};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    final body = fallbackBody ?? data.toString();
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    throw Exception('Worker trả về dữ liệu không đúng định dạng JSON object.');
  }

  void _throwIfRequestFailed(
    Response<dynamic> response,
    Map<String, dynamic> body, {
    required String defaultMessage,
  }) {
    final statusCode = response.statusCode ?? 200;
    if (statusCode < 400) {
      return;
    }

    final message =
        body['error']?.toString() ??
        body['message']?.toString() ??
        '$defaultMessage ($statusCode)';

    throw Exception(message);
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  bool _isConnectionError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
