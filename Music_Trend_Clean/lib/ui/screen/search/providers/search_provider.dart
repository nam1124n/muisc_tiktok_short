import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/search_text_normalizer.dart';
import 'package:login_flutter/data/datasource/remote/ollama_ai_remote_data_source.dart';
import 'package:login_flutter/data/repositories/ai_search_repository_impl.dart';
import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/ai_search_repository.dart';
import 'package:login_flutter/domain/usecases/analyze_search_query_usecase.dart';
import 'package:login_flutter/ui/screen/search/providers/search_state.dart';

final ollamaAiRemoteDataSourceProvider = Provider<OllamaAiRemoteDataSource>((
  ref,
) {
  return OllamaAiRemoteDataSource();
});

final aiSearchRepositoryProvider = Provider<AiSearchRepository>((ref) {
  return AiSearchRepositoryImpl(ref.read(ollamaAiRemoteDataSourceProvider));
});

final analyzeSearchQueryUseCaseProvider = Provider<AnalyzeSearchQueryUseCase>((
  ref,
) {
  return AnalyzeSearchQueryUseCase(ref.read(aiSearchRepositoryProvider));
});

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
      return SearchNotifier(
        analyzeSearchQueryUseCase: ref.read(analyzeSearchQueryUseCaseProvider),
      );
    });

class SearchNotifier extends StateNotifier<SearchState> {
  final AnalyzeSearchQueryUseCase analyzeSearchQueryUseCase;
  final Map<String, SearchPlanEntity> _planCache = {};
  String _activeQueryKey = '';
  int _requestVersion = 0;

  SearchNotifier({required this.analyzeSearchQueryUseCase})
    : super(const SearchInitial());

  void preview({required String query, required List<SongEntity> songs}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _activeQueryKey = '';
      _requestVersion++;
      state = const SearchInitial();
      return;
    }

    final cacheKey = _cacheKey(trimmed);
    if (cacheKey != _activeQueryKey) {
      _activeQueryKey = cacheKey;
      _requestVersion++;
    }

    final cachedPlan = _planCache[cacheKey];
    if (cachedPlan != null) {
      state = SearchLoaded(
        results: _buildResultsFromPlan(
          songs: songs,
          query: trimmed,
          plan: cachedPlan,
        ),
        plan: cachedPlan,
      );
      return;
    }

    state = SearchLoading(
      previewResults: _buildResultsFromPlan(
        songs: songs,
        query: trimmed,
        plan: _buildKeywordPlan(trimmed),
      ),
    );
  }

  Future<void> search({
    required String query,
    required List<SongEntity> songs,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _activeQueryKey = '';
      _requestVersion++;
      state = const SearchInitial();
      return;
    }

    final cacheKey = _cacheKey(trimmed);
    if (cacheKey != _activeQueryKey) {
      preview(query: trimmed, songs: songs);
    }

    final requestVersion = _requestVersion;
    final cachedPlan = _planCache[cacheKey];
    if (cachedPlan != null) {
      state = SearchLoaded(
        results: _buildResultsFromPlan(
          songs: songs,
          query: trimmed,
          plan: cachedPlan,
        ),
        plan: cachedPlan,
      );
      return;
    }

    try {
      final plan = await analyzeSearchQueryUseCase(trimmed);
      if (!_isLatestRequest(cacheKey, requestVersion)) {
        return;
      }

      _planCache[cacheKey] = plan;
      final results = _buildResultsFromPlan(
        songs: songs,
        query: trimmed,
        plan: plan,
      );

      state = SearchLoaded(results: results, plan: plan);
    } catch (e) {
      if (!_isLatestRequest(cacheKey, requestVersion)) {
        return;
      }

      final fallbackPlan = _buildKeywordPlan(
        trimmed,
        reason: _cleanError(e),
        provider: 'rule',
      );
      state = SearchLoaded(
        results: _buildResultsFromPlan(
          songs: songs,
          query: trimmed,
          plan: fallbackPlan,
        ),
        plan: fallbackPlan,
      );
    }
  }

  String _cacheKey(String query) => normalizeSearchText(query);

  bool _isLatestRequest(String cacheKey, int requestVersion) {
    return cacheKey == _activeQueryKey && requestVersion == _requestVersion;
  }

  List<SongEntity> _buildResultsFromPlan({
    required List<SongEntity> songs,
    required String query,
    required SearchPlanEntity plan,
  }) {
    return _rankSongs(
      songs: songs,
      query: query,
      keywords: plan.keywords,
      artistHints: plan.artistHints,
      titleHints: plan.titleHints,
      tagHints: plan.tagHints,
    );
  }

  SearchPlanEntity _buildKeywordPlan(
    String query, {
    String reason = '',
    String provider = 'keyword',
  }) {
    final keywords = tokenizeSearchInputs([query]);

    return SearchPlanEntity(
      originalQuery: query,
      keywords: keywords.isEmpty ? normalizeSearchPhrases([query]) : keywords,
      artistHints: const [],
      titleHints: const [],
      tagHints: const [],
      provider: provider,
      reason: reason,
    );
  }

  String _cleanError(Object error) {
    const prefix = 'Exception: ';
    final message = error.toString();
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }
    return message;
  }

  List<SongEntity> _rankSongs({
    required List<SongEntity> songs,
    required String query,
    required List<String> keywords,
    required List<String> artistHints,
    required List<String> titleHints,
    required List<String> tagHints,
  }) {
    final normalizedQuery = normalizeSearchText(query);
    final keywordTokens = tokenizeSearchInputs([query, ...keywords]);
    final artistPhrases = normalizeSearchPhrases(artistHints);
    final titlePhrases = normalizeSearchPhrases(titleHints);
    final tagPhrases = normalizeSearchPhrases(tagHints);
    final tagTokens = tokenizeSearchInputs(tagHints);
    final targetEnergy = _inferTargetEnergy(
      normalizedQuery: normalizedQuery,
      keywordPhrases: normalizeSearchPhrases(keywords),
      tagPhrases: tagPhrases,
    );

    final scored = <MapEntry<SongEntity, int>>[];

    for (final song in songs) {
      final title = normalizeSearchText(song.title);
      final artist = normalizeSearchText(song.artist);
      final aliases = normalizeSearchPhrases(song.searchAliases);
      final tags = normalizeSearchPhrases(song.semanticTags);
      var score = 0;

      score += _scoreTextQuery(
        title,
        normalizedQuery,
        exactWeight: 30,
        containsWeight: 18,
      );
      score += _scoreTextQuery(
        artist,
        normalizedQuery,
        exactWeight: 32,
        containsWeight: 20,
      );
      score += _scorePhraseListQuery(
        aliases,
        normalizedQuery,
        exactWeight: 24,
        containsWeight: 16,
      );
      score += _scorePhraseListQuery(
        tags,
        normalizedQuery,
        exactWeight: 22,
        containsWeight: 14,
      );

      score += _scoreTextTokens(title, keywordTokens, weight: 4);
      score += _scoreTextTokens(artist, keywordTokens, weight: 5);
      score += _scorePhraseTokens(
        aliases,
        keywordTokens,
        exactWeight: 7,
        containsWeight: 5,
      );
      score += _scorePhraseTokens(
        tags,
        keywordTokens,
        exactWeight: 8,
        containsWeight: 6,
      );

      score += _scoreTextHints(
        title,
        titlePhrases,
        exactWeight: 14,
        containsWeight: 10,
      );
      score += _scorePhraseHints(
        aliases,
        titlePhrases,
        exactWeight: 12,
        containsWeight: 9,
      );
      score += _scoreTextHints(
        artist,
        artistPhrases,
        exactWeight: 16,
        containsWeight: 12,
      );
      score += _scorePhraseHints(
        tags,
        tagPhrases,
        exactWeight: 16,
        containsWeight: 12,
      );
      score += _scorePhraseTokens(
        tags,
        tagTokens,
        exactWeight: 10,
        containsWeight: 8,
      );

      if (targetEnergy != null && score > 0) {
        score += _scoreEnergy(song.energyLevel, targetEnergy);
      }

      if (score > 0) {
        scored.add(MapEntry(song, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((entry) => entry.key).toList();
  }

  int _scoreEnergy(int songEnergy, int targetEnergy) {
    final difference = (songEnergy - targetEnergy).abs();
    return switch (difference) {
      0 => 8,
      1 => 5,
      2 => 2,
      _ => 0,
    };
  }

  int _scorePhraseHints(
    List<String> haystacks,
    List<String> phrases, {
    required int exactWeight,
    required int containsWeight,
  }) {
    var score = 0;
    for (final phrase in phrases) {
      score += _scorePhraseListQuery(
        haystacks,
        phrase,
        exactWeight: exactWeight,
        containsWeight: containsWeight,
      );
    }
    return score;
  }

  int _scorePhraseListQuery(
    List<String> haystacks,
    String query, {
    required int exactWeight,
    required int containsWeight,
  }) {
    if (query.isEmpty) {
      return 0;
    }

    var score = 0;
    for (final haystack in haystacks) {
      if (haystack == query) {
        score += exactWeight;
      } else if (haystack.contains(query)) {
        score += containsWeight;
      }
    }
    return score;
  }

  int _scorePhraseTokens(
    List<String> haystacks,
    List<String> tokens, {
    required int exactWeight,
    required int containsWeight,
  }) {
    var score = 0;
    for (final token in tokens) {
      for (final haystack in haystacks) {
        if (haystack == token) {
          score += exactWeight;
        } else if (haystack.contains(token)) {
          score += containsWeight;
        }
      }
    }
    return score;
  }

  int _scoreTextHints(
    String haystack,
    List<String> phrases, {
    required int exactWeight,
    required int containsWeight,
  }) {
    var score = 0;
    for (final phrase in phrases) {
      score += _scoreTextQuery(
        haystack,
        phrase,
        exactWeight: exactWeight,
        containsWeight: containsWeight,
      );
    }
    return score;
  }

  int _scoreTextQuery(
    String haystack,
    String query, {
    required int exactWeight,
    required int containsWeight,
  }) {
    if (query.isEmpty) {
      return 0;
    }

    if (haystack == query) {
      return exactWeight;
    }

    if (haystack.contains(query)) {
      return containsWeight;
    }

    return 0;
  }

  int _scoreTextTokens(
    String haystack,
    List<String> tokens, {
    required int weight,
  }) {
    var score = 0;
    for (final token in tokens) {
      if (haystack.contains(token)) {
        score += weight;
      }
    }
    return score;
  }

  int? _inferTargetEnergy({
    required String normalizedQuery,
    required List<String> keywordPhrases,
    required List<String> tagPhrases,
  }) {
    final combined = [
      normalizedQuery,
      ...keywordPhrases,
      ...tagPhrases,
    ].where((value) => value.isNotEmpty).join(' ');

    if (combined.isEmpty) {
      return null;
    }

    if (_containsAnyPhrase(combined, const {
      'ballad',
      'buon',
      'chill',
      'deep',
      'focus',
      'healing',
      'lofi',
      'mua dem',
      'ngu',
      'relax',
      'sad',
      'sleep',
      'study',
      'tam trang',
      'that tinh',
      'thu gian',
    })) {
      return 1;
    }

    if (_containsAnyPhrase(combined, const {
      'acoustic',
      'cafe',
      'drive',
      'feel good',
      'happy',
      'nhac nhe',
      'pop',
      'vui',
    })) {
      return 3;
    }

    if (_containsAnyPhrase(combined, const {
      'dance',
      'edm',
      'gym',
      'party',
      'quay',
      'rap',
      'remix',
      'rock',
      'tiktok',
      'trend',
      'workout',
    })) {
      return 5;
    }

    return null;
  }

  bool _containsAnyPhrase(String value, Set<String> phrases) {
    for (final phrase in phrases) {
      if (value.contains(phrase)) {
        return true;
      }
    }
    return false;
  }
}
