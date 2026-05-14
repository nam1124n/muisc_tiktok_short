import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_task_model.dart';

class AudioGenerationRemoteDataSource {
  AudioGenerationRemoteDataSource({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(
        baseUrl ?? AppConfig.audioGenerationWorkerBaseUrl,
      );

  final http.Client _client;
  final String _baseUrl;

  Future<GeneratedAudioTaskModel> generateAudioTask({
    required String userId,
    required String prompt,
  }) async {
    final response = await _runRequest(
      () => _client.post(
        _uri('/api/generate'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'user_id': userId,
          'prompt': prompt,
        }),
      ),
    );

    final body = _decodeBodyAsMap(response.body);
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
    final response = await _runRequest(
      () => _client.get(
        _uri('/api/generations/${Uri.encodeComponent(taskId)}'),
        headers: const {'Accept': 'application/json'},
      ),
    );

    final body = _decodeBodyAsMap(response.body);
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

  Uri _uri(String path) {
    return Uri.parse('$_baseUrl$path');
  }

  Future<http.Response> _runRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(
        const Duration(seconds: AppConfig.audioGenerationRequestTimeoutSeconds),
      );
    } on TimeoutException {
      throw Exception(AppConfig.buildAudioGenerationTimeoutMessage(_baseUrl));
    } on http.ClientException catch (error) {
      throw Exception(
        AppConfig.buildAudioGenerationConnectionErrorMessage(
          _baseUrl,
          details: error.message,
        ),
      );
    }
  }

  Map<String, dynamic> _decodeBodyAsMap(String body) {
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
    http.Response response,
    Map<String, dynamic> body, {
    required String defaultMessage,
  }) {
    if (response.statusCode < 400) {
      return;
    }

    final message =
        body['error']?.toString() ??
        body['message']?.toString() ??
        '$defaultMessage (${response.statusCode})';

    throw Exception(message);
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
