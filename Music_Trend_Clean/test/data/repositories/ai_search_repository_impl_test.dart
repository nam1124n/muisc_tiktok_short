import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/data/datasource/remote/ollama_ai_remote_data_source.dart';
import 'package:login_flutter/data/repositories/ai_search_repository_impl.dart';

void main() {
  group('AiSearchRepositoryImpl', () {
    test('returns local plan when local Ollama succeeds', () async {
      final repository = AiSearchRepositoryImpl(
        _FakeOllamaAiRemoteDataSource(
          onAnalyzeQuery: ({required baseUrl, required query, required model}) {
            expect(baseUrl, 'http://127.0.0.1:11434/api');
            expect(query, 'Son Tung Chay Ngay Di');
            expect(model, 'llama3:latest');

            return Future.value({
              'keywords': ['Son Tung', 'Chay Ngay Di'],
              'artistHints': ['Son Tung M-TP'],
              'titleHints': ['Chay Ngay Di'],
              'reason': 'Matched artist and title',
            });
          },
        ),
        localBaseUrl: 'http://127.0.0.1:11434/api',
        localModel: 'llama3:latest',
      );

      final plan = await repository.analyzeQuery('Son Tung Chay Ngay Di');

      expect(plan.provider, 'local');
      expect(plan.keywords, ['son tung', 'chay ngay di']);
      expect(plan.artistHints, ['son tung m-tp']);
      expect(plan.titleHints, ['chay ngay di']);
      expect(plan.reason, 'Matched artist and title');
    });

    test('falls back to cloud when local Ollama fails', () async {
      final repository = AiSearchRepositoryImpl(
        _FakeOllamaAiRemoteDataSource(
          onAnalyzeQuery: ({required baseUrl, required query, required model}) {
            if (baseUrl == 'http://local') {
              throw Exception("Ollama error: model 'gemma3' not found");
            }

            expect(baseUrl, 'http://cloud');
            expect(model, 'llama3:latest');
            return Future.value({
              'keywords': ['son tung'],
              'artistHints': ['son tung m-tp'],
              'titleHints': const <String>[],
              'reason': 'Cloud fallback matched artist',
            });
          },
        ),
        localBaseUrl: 'http://local',
        localModel: 'gemma3',
        cloudBaseUrl: 'http://cloud',
        cloudModel: 'llama3:latest',
      );

      final plan = await repository.analyzeQuery('son tung');

      expect(plan.provider, 'cloud');
      expect(plan.artistHints, ['son tung m-tp']);
      expect(plan.reason, 'Cloud fallback matched artist');
    });

    test('tries the next local Android endpoint before using cloud', () async {
      final repository = AiSearchRepositoryImpl(
        _FakeOllamaAiRemoteDataSource(
          onAnalyzeQuery: ({required baseUrl, required query, required model}) {
            if (baseUrl == 'http://10.0.2.2:11434/api') {
              throw Exception('Connection refused');
            }

            expect(baseUrl, 'http://127.0.0.1:11434/api');
            expect(model, 'llama3:latest');
            return Future.value({
              'keywords': ['son tung'],
              'artistHints': ['son tung m-tp'],
              'titleHints': const <String>[],
              'reason': 'Android local fallback matched artist',
            });
          },
        ),
        localBaseUrls: const [
          'http://10.0.2.2:11434/api',
          'http://127.0.0.1:11434/api',
        ],
        localModel: 'llama3:latest',
      );

      final plan = await repository.analyzeQuery('son tung');

      expect(plan.provider, 'local');
      expect(plan.artistHints, ['son tung m-tp']);
      expect(plan.reason, 'Android local fallback matched artist');
    });

    test(
      'returns rule fallback with error details when all AI providers fail',
      () async {
        final repository = AiSearchRepositoryImpl(
          _FakeOllamaAiRemoteDataSource(
            onAnalyzeQuery:
                ({required baseUrl, required query, required model}) {
                  if (baseUrl == 'http://local') {
                    throw Exception("Ollama error: model 'gemma3' not found");
                  }

                  throw Exception('Connection timeout');
                },
          ),
          localBaseUrl: 'http://local',
          localModel: 'gemma3',
          cloudBaseUrl: 'http://cloud',
          cloudModel: 'llama3:latest',
        );

        final plan = await repository.analyzeQuery('son tung');

        expect(plan.provider, 'rule');
        expect(plan.keywords, ['son', 'tung']);
        expect(
          plan.reason,
          contains(
            "Local AI loi: http://local -> Ollama error: model 'gemma3' not found",
          ),
        );
        expect(plan.reason, contains('Cloud AI loi: Connection timeout'));
      },
    );
  });
}

typedef _AnalyzeQueryCallback =
    Future<Map<String, dynamic>> Function({
      required String baseUrl,
      required String query,
      required String model,
    });

class _FakeOllamaAiRemoteDataSource extends OllamaAiRemoteDataSource {
  final _AnalyzeQueryCallback onAnalyzeQuery;

  _FakeOllamaAiRemoteDataSource({required this.onAnalyzeQuery});

  @override
  Future<Map<String, dynamic>> analyzeQuery({
    required String baseUrl,
    required String query,
    required String model,
  }) {
    return onAnalyzeQuery(baseUrl: baseUrl, query: query, model: model);
  }
}
