import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:login_flutter/app/config/audio_generation_config.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_model.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_task_model.dart';

class AudioGenerationRemoteDataSource {
  static const String _mockSampleAudioUrlA =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  static const String _mockSampleAudioUrlB =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';

  Future<Map<String, dynamic>> createGeneration({
    required String baseUrl,
    required String userId,
    required String prompt,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '${_normalizeBaseUrl(baseUrl)}${AudioGenerationConfig.generatePath}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'prompt': prompt}),
        )
        .timeout(Duration(seconds: AudioGenerationConfig.timeoutSeconds));

    _throwIfRequestFailed(
      response,
      defaultMessage: 'Không thể tạo generation audio',
    );

    final body = _decodeBodyAsMap(response.body);
    final generationId =
        body['taskId']?.toString() ?? body['task_id']?.toString() ?? '';

    if (generationId.isEmpty) {
      throw Exception('Backend không trả về generation id hợp lệ.');
    }

    return body;
  }

  Future<Map<String, dynamic>> getGeneration({
    required String baseUrl,
    required String generationId,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '${_normalizeBaseUrl(baseUrl)}${AudioGenerationConfig.generationsPath}/$generationId',
          ),
        )
        .timeout(Duration(seconds: AudioGenerationConfig.timeoutSeconds));

    _throwIfRequestFailed(
      response,
      defaultMessage: 'Không thể lấy thông tin generation',
    );

    return _decodeBodyAsMap(response.body);
  }

  Future<List<GeneratedAudioTaskModel>> getMySongs({
    required String baseUrl,
    required String userId,
  }) async {
    final uri = Uri.parse(
      '${_normalizeBaseUrl(baseUrl)}${AudioGenerationConfig.mySongsPath}',
    ).replace(queryParameters: {'user_id': userId});

    final response = await http
        .get(uri)
        .timeout(Duration(seconds: AudioGenerationConfig.timeoutSeconds));

    _throwIfRequestFailed(
      response,
      defaultMessage: 'Không thể tải danh sách audio của user',
    );

    final body = _decodeBodyAsMap(response.body);
    final tasks =
        (body['tasks'] as List<dynamic>? ??
        body['songs'] as List<dynamic>? ??
        []);

    return tasks
        .whereType<Map<String, dynamic>>()
        .map(GeneratedAudioTaskModel.fromJson)
        .toList();
  }

  Future<GeneratedAudioTaskModel> generateMockAudioTask({
    required String userId,
    required String prompt,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final now = DateTime.now().toUtc();
    final taskId = 'mock_${now.millisecondsSinceEpoch}';
    final baseTitle = _buildTitle(prompt);

    final tracks = [
      GeneratedAudioModel(
        id: '${taskId}_a',
        taskId: taskId,
        variantIndex: 0,
        title: '$baseTitle A',
        prompt: prompt,
        audioUrl: _mockSampleAudioUrlA,
        streamAudioUrl: _mockSampleAudioUrlA,
        imageUrl: 'https://picsum.photos/seed/${taskId}_a/640/640',
        durationSeconds: 135,
        provider: 'mock-suno-api',
        modelName: 'V5',
        tags: _buildTags(prompt),
        createdAt: now,
      ),
      GeneratedAudioModel(
        id: '${taskId}_b',
        taskId: taskId,
        variantIndex: 1,
        title: '$baseTitle B',
        prompt: prompt,
        audioUrl: _mockSampleAudioUrlB,
        streamAudioUrl: _mockSampleAudioUrlB,
        imageUrl: 'https://picsum.photos/seed/${taskId}_b/640/640',
        durationSeconds: 136,
        provider: 'mock-suno-api',
        modelName: 'V5',
        tags: _buildTags(prompt),
        createdAt: now,
      ),
    ];

    return GeneratedAudioTaskModel(
      id: taskId,
      userId: userId,
      prompt: prompt,
      status: 'success',
      provider: 'mock-suno-api',
      outputCount: tracks.length,
      tracks: tracks,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _buildTitle(String prompt) {
    final words = prompt
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(4)
        .map(_capitalize)
        .toList();

    if (words.isEmpty) {
      return 'AI Audio Demo';
    }

    return words.join(' ');
  }

  List<String> _buildTags(String prompt) {
    return prompt
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(6)
        .toList();
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.replaceFirst(RegExp(r'/+$'), '');
  }

  Map<String, dynamic> _decodeBodyAsMap(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Backend trả về dữ liệu không đúng định dạng JSON object.');
  }

  void _throwIfRequestFailed(
    http.Response response, {
    required String defaultMessage,
  }) {
    if (response.statusCode < 400) {
      return;
    }

    final message =
        _tryReadErrorMessage(response.body) ??
        '$defaultMessage (${response.statusCode})';

    throw Exception(message);
  }

  String? _tryReadErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded['error']?.toString();
      }
    } catch (_) {}

    return null;
  }
}
