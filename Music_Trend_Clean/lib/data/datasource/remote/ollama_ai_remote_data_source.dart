import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:login_flutter/app/config/ai_config.dart';

class OllamaAiRemoteDataSource {
  Future<Map<String, dynamic>> analyzeQuery({
    required String baseUrl,
    required String query,
    required String model,
  }) async {
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final client = http.Client();

    try {
      final request =
          http.Request('POST', Uri.parse('$normalizedBaseUrl/generate'))
            ..headers['Content-Type'] = 'application/json'
            ..body = jsonEncode({
              'model': model,
              'stream': true,
              'format': 'json',
              'keep_alive': AiConfig.keepAlive,
              'options': {
                'temperature': 0,
                'num_predict': AiConfig.maxPredictTokens,
              },
              'prompt':
                  'Phan tich truy van tim nhac va tra ve duy nhat mot JSON hop le '
                  'voi 5 truong: keywords, artistHints, titleHints, tagHints, reason. '
                  'tagHints dung cho mood, vibe, genre, boi canh nghe nhac hoac trend ngan '
                  'nhu buon, chill, that tinh, tiktok, study, remix. '
                  'Loai bo tu dem khong can thiet. Moi mang chi chua cum tu ngan, viet thuong. '
                  'Khong them van ban khac. Query: "$query".',
            });

      final response = await client
          .send(request)
          .timeout(Duration(seconds: AiConfig.timeoutSeconds));

      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString();
        throw Exception(
          'Ollama request failed (${response.statusCode}): $body',
        );
      }

      final rawContent = await _collectStreamedContent(response);
      if (rawContent.isEmpty) {
        throw Exception('AI tra ve rong');
      }

      final content = _extractJsonObject(rawContent);
      final data = jsonDecode(content) as Map<String, dynamic>;

      return {
        'keywords': _readList(data['keywords']),
        'artistHints': _readList(data['artistHints']),
        'titleHints': _readList(data['titleHints']),
        'tagHints': _readList(data['tagHints']),
        'reason': data['reason']?.toString().trim() ?? '',
      };
    } finally {
      client.close();
    }
  }

  Future<String> _collectStreamedContent(http.StreamedResponse response) async {
    final buffer = StringBuffer();

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(Duration(seconds: AiConfig.timeoutSeconds))) {
      if (line.trim().isEmpty) {
        continue;
      }

      final chunk = jsonDecode(line) as Map<String, dynamic>;
      final apiError = chunk['error']?.toString();
      if (apiError != null && apiError.isNotEmpty) {
        throw Exception('Ollama error: $apiError');
      }

      buffer.write(chunk['response']?.toString() ?? '');
    }

    return buffer.toString().trim();
  }

  String _extractJsonObject(String rawContent) {
    final cleaned = rawContent
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw Exception('AI khong tra ve JSON hop le');
    }

    return cleaned.substring(start, end + 1);
  }

  List<String> _readList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value.map((item) => item.toString().trim()).toList();
  }
}
