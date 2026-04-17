import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/ai_search_repository.dart';
import 'package:login_flutter/domain/usecases/analyze_search_query_usecase.dart';
import 'package:login_flutter/ui/screen/search/providers/search_provider.dart';
import 'package:login_flutter/ui/screen/search/providers/search_state.dart';

void main() {
  group('SearchNotifier', () {
    const songs = [
      SongEntity(
        id: '1',
        title: 'Chay Ngay Di',
        artist: 'Son Tung M-TP',
        audioUrl: 'audio-1',
        imageUrl: 'image-1',
        searchAliases: ['son tung chay ngay di'],
        semanticTags: ['pop', 'tiktok'],
      ),
      SongEntity(
        id: '2',
        title: 'Loi Nho',
        artist: 'Da LAB',
        audioUrl: 'audio-2',
        imageUrl: 'image-2',
        searchAliases: ['chill da lab'],
        semanticTags: ['chill', 'study'],
      ),
    ];

    test('shows keyword preview results immediately', () {
      final notifier = SearchNotifier(
        analyzeSearchQueryUseCase: AnalyzeSearchQueryUseCase(
          _FakeAiSearchRepository(
            onAnalyzeQuery: (_) async => throw UnimplementedError(),
          ),
        ),
      );

      notifier.preview(query: 'son tung', songs: songs);

      final state = notifier.state;
      expect(state, isA<SearchLoading>());
      expect((state as SearchLoading).previewResults.map((song) => song.id), [
        '1',
      ]);
    });

    test('reuses cached AI plan for repeated normalized queries', () async {
      var callCount = 0;
      final notifier = SearchNotifier(
        analyzeSearchQueryUseCase: AnalyzeSearchQueryUseCase(
          _FakeAiSearchRepository(
            onAnalyzeQuery: (query) async {
              callCount++;
              return const SearchPlanEntity(
                originalQuery: 'Son Tung',
                keywords: ['son tung'],
                artistHints: ['son tung m tp'],
                titleHints: [],
                tagHints: [],
                provider: 'local',
                reason: 'Matched artist',
              );
            },
          ),
        ),
      );

      notifier.preview(query: 'Son Tung', songs: songs);
      await notifier.search(query: 'Son Tung', songs: songs);
      notifier.preview(query: '  sơn tùng  ', songs: songs);
      await notifier.search(query: '  sơn tùng  ', songs: songs);

      expect(callCount, 1);
      expect(notifier.state, isA<SearchLoaded>());
    });

    test('ignores stale AI results from older queries', () async {
      final firstQueryCompleter = Completer<SearchPlanEntity>();
      final notifier = SearchNotifier(
        analyzeSearchQueryUseCase: AnalyzeSearchQueryUseCase(
          _FakeAiSearchRepository(
            onAnalyzeQuery: (query) {
              if (query == 'son tung') {
                return firstQueryCompleter.future;
              }

              return Future.value(
                const SearchPlanEntity(
                  originalQuery: 'chill',
                  keywords: ['chill'],
                  artistHints: [],
                  titleHints: [],
                  tagHints: ['study'],
                  provider: 'local',
                  reason: 'Matched chill vibe',
                ),
              );
            },
          ),
        ),
      );

      notifier.preview(query: 'son tung', songs: songs);
      final firstSearch = notifier.search(query: 'son tung', songs: songs);

      notifier.preview(query: 'chill', songs: songs);
      await notifier.search(query: 'chill', songs: songs);

      expect(notifier.state, isA<SearchLoaded>());
      final loadedState = notifier.state as SearchLoaded;
      expect(loadedState.plan.originalQuery, 'chill');
      expect(loadedState.results.map((song) => song.id), ['2']);

      firstQueryCompleter.complete(
        const SearchPlanEntity(
          originalQuery: 'son tung',
          keywords: ['son tung'],
          artistHints: ['son tung m tp'],
          titleHints: [],
          tagHints: [],
          provider: 'local',
          reason: 'Matched artist',
        ),
      );

      await firstSearch;

      expect(notifier.state, isA<SearchLoaded>());
      final finalState = notifier.state as SearchLoaded;
      expect(finalState.plan.originalQuery, 'chill');
      expect(finalState.results.map((song) => song.id), ['2']);
    });
  });
}

class _FakeAiSearchRepository implements AiSearchRepository {
  final Future<SearchPlanEntity> Function(String query) onAnalyzeQuery;

  _FakeAiSearchRepository({required this.onAnalyzeQuery});

  @override
  Future<SearchPlanEntity> analyzeQuery(String query) {
    return onAnalyzeQuery(query);
  }
}
