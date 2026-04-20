import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/search_text_normalizer.dart';
import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/search/providers/search_state.dart';

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
      return SearchNotifier();
    });

class SearchNotifier extends StateNotifier<SearchState> {
  final _SearchPlanBuilder _planBuilder;
  final _SongSearchRanker _ranker;

  SearchNotifier()
    : _planBuilder = const _SearchPlanBuilder(),
      _ranker = const _SongSearchRanker(),
      super(const SearchInitial());

  Future<void> search({
    required String query,
    required List<SongEntity> songs,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      state = const SearchInitial();
      return Future.value();
    }

    final plan = _planBuilder.build(trimmedQuery);
    final results = _ranker.rank(songs: songs, plan: plan);
    state = SearchLoaded(results: results, plan: plan);
    return Future.value();
  }
}

class _SearchPlanBuilder {
  const _SearchPlanBuilder();

  SearchPlanEntity build(String query) {
    final keywords = tokenizeSearchInputs([query]);

    return SearchPlanEntity(
      originalQuery: query,
      keywords: keywords.isEmpty ? normalizeSearchPhrases([query]) : keywords,
      artistHints: const [],
      titleHints: const [],
      tagHints: const [],
      provider: 'normal',
      reason: 'Tim theo ten bai hat va nghe si.',
    );
  }
}

class _SongSearchRanker {
  const _SongSearchRanker();

  List<SongEntity> rank({
    required List<SongEntity> songs,
    required SearchPlanEntity plan,
  }) {
    final normalizedQuery = normalizeSearchText(plan.originalQuery);
    final keywords = plan.keywords;
    final scoredSongs = <_ScoredSong>[];

    for (final song in songs) {
      final index = _SongSearchIndex.fromSong(song);
      final score = _scoreSong(
        index,
        normalizedQuery: normalizedQuery,
        keywords: keywords,
      );

      if (score > 0) {
        scoredSongs.add(_ScoredSong(song: song, score: score));
      }
    }

    scoredSongs.sort((left, right) => right.score.compareTo(left.score));
    return scoredSongs.map((item) => item.song).toList();
  }

  int _scoreSong(
    _SongSearchIndex index, {
    required String normalizedQuery,
    required List<String> keywords,
  }) {
    var score = 0;

    score += _scoreTextMatch(
      index.title,
      normalizedQuery,
      exactWeight: 120,
      containsWeight: 80,
    );
    score += _scoreTextMatch(
      index.artist,
      normalizedQuery,
      exactWeight: 100,
      containsWeight: 70,
    );

    score += _scoreTokenMatch(index.title, keywords, weight: 22);
    score += _scoreTokenMatch(index.artist, keywords, weight: 18);

    if (keywords.isNotEmpty &&
        _containsAllKeywords(index.searchDocument, keywords)) {
      score += 30;
    }

    return score;
  }

  int _scoreTextMatch(
    String value,
    String query, {
    required int exactWeight,
    required int containsWeight,
  }) {
    if (query.isEmpty) {
      return 0;
    }

    if (value == query) {
      return exactWeight;
    }

    if (value.contains(query)) {
      return containsWeight;
    }

    return 0;
  }

  int _scoreTokenMatch(
    String value,
    List<String> keywords, {
    required int weight,
  }) {
    var score = 0;

    for (final keyword in keywords) {
      if (value.contains(keyword)) {
        score += weight;
      }
    }

    return score;
  }

  bool _containsAllKeywords(String value, List<String> keywords) {
    for (final keyword in keywords) {
      if (!value.contains(keyword)) {
        return false;
      }
    }

    return true;
  }
}

class _SongSearchIndex {
  final String title;
  final String artist;
  final String searchDocument;

  const _SongSearchIndex({
    required this.title,
    required this.artist,
    required this.searchDocument,
  });

  factory _SongSearchIndex.fromSong(SongEntity song) {
    final title = normalizeSearchText(song.title);
    final artist = normalizeSearchText(song.artist);

    return _SongSearchIndex(
      title: title,
      artist: artist,
      searchDocument: [
        title,
        artist,
      ].where((value) => value.isNotEmpty).join(' '),
    );
  }
}

class _ScoredSong {
  final SongEntity song;
  final int score;

  const _ScoredSong({required this.song, required this.score});
}
