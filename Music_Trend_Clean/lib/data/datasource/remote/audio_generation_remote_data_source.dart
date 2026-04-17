import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:login_flutter/app/config/audio_generation_config.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_model.dart';

class AudioGenerationRemoteDataSource {
  static const String _mockSampleAudioUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  Future<String> createGeneration({
    required String baseUrl,
    required String userId,
    required String prompt,
    required int durationSeconds,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '${_normalizeBaseUrl(baseUrl)}${AudioGenerationConfig.generatePath}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'prompt': prompt,
            'duration_sec': durationSeconds,
          }),
        )
        .timeout(Duration(seconds: AudioGenerationConfig.timeoutSeconds));

    _throwIfRequestFailed(
      response,
      defaultMessage: 'Không thể tạo generation audio',
    );

    final body = _decodeBodyAsMap(response.body);
    final generationId = body['id']?.toString() ?? '';

    if (generationId.isEmpty) {
      throw Exception('Backend không trả về generation id hợp lệ.');
    }

    return generationId;
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

  Future<List<GeneratedAudioModel>> getMySongs({
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
    final songs = (body['songs'] as List<dynamic>? ?? []);

    return songs
        .whereType<Map<String, dynamic>>()
        .map(GeneratedAudioModel.fromJson)
        .toList();
  }

  Future<GeneratedAudioModel> generateMockAudio({
    required String prompt,
    required int durationSeconds,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    return GeneratedAudioModel(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      title: _buildTitle(prompt),
      prompt: prompt,
      audioUrl: _mockSampleAudioUrl,
      imageUrl: '',
      durationSeconds: durationSeconds,
      provider: 'mock-suno-api',
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
