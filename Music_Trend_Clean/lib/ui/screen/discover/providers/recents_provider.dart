import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/listening_history_entry_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';

const _recentStateNoChange = Object();

final recentNotifierProvider =
    StateNotifierProvider<RecentNotifier, RecentState>((ref) {
      final userId = ref.watch(sessionCurrentUserIdProvider) ?? 'guest';
      return RecentNotifier(
        userId: userId,
        repository: ref.read(interactionRepositoryProvider),
      );
    });

final recentSongsProvider = Provider<List<SongEntity>>((ref) {
  return ref.watch(recentNotifierProvider.select((state) => state.songs));
});

class RecentState extends Equatable {
  const RecentState({
    this.entries = const [],
    this.isLoading = false,
    this.isClearing = false,
    this.errorMessage,
  });

  const RecentState.initial()
    : entries = const [],
      isLoading = false,
      isClearing = false,
      errorMessage = null;

  final List<ListeningHistoryEntryEntity> entries;
  final bool isLoading;
  final bool isClearing;
  final String? errorMessage;

  List<SongEntity> get songs => [
    for (final entry in recentlyPlayed) entry.song,
  ];

  List<ListeningHistoryEntryEntity> get recentlyPlayed {
    final sorted = [...entries];
    sorted.sort((left, right) {
      final rightTime = right.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      final leftTime = left.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      return rightTime.compareTo(leftTime);
    });
    return sorted;
  }

  List<ListeningHistoryEntryEntity> get continueListening {
    final filtered = [
      for (final entry in recentlyPlayed)
        if (entry.canContinueListening) entry,
    ];
    return filtered.take(6).toList(growable: false);
  }

  List<ListeningHistoryEntryEntity> get mostPlayed {
    final sorted = [...entries];
    sorted.sort((left, right) {
      final playCountComparison = right.playCount.compareTo(left.playCount);
      if (playCountComparison != 0) {
        return playCountComparison;
      }

      final rightTime = right.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      final leftTime = left.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      return rightTime.compareTo(leftTime);
    });
    return sorted.take(6).toList(growable: false);
  }

  RecentState copyWith({
    List<ListeningHistoryEntryEntity>? entries,
    bool? isLoading,
    bool? isClearing,
    Object? errorMessage = _recentStateNoChange,
    bool clearErrorMessage = false,
  }) {
    return RecentState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isClearing: isClearing ?? this.isClearing,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage == _recentStateNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [entries, isLoading, isClearing, errorMessage];
}

class RecentNotifier extends StateNotifier<RecentState> {
  RecentNotifier({required this.userId, required this.repository})
    : super(const RecentState.initial()) {
    if (userId != 'guest') {
      _loadRecents();
    }
  }

  final String userId;
  final InteractionRepository repository;

  Future<void> _loadRecents({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }

    try {
      final loaded = await repository.getHistoryEntries(userId);
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        entries: _dedupeEntries(loaded),
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageMapper.map(error),
      );
    }
  }

  Future<void> refresh() async {
    if (userId == 'guest') {
      state = const RecentState.initial();
      return;
    }

    await _loadRecents(showLoading: state.entries.isEmpty);
  }

  Future<void> addRecent(SongEntity song) async {
    if (userId == 'guest') {
      return;
    }

    final stampedSong = _stampSong(song);
    final now = stampedSong.savedAt ?? DateTime.now();
    final updatedEntries = _upsertEntry(
      ListeningHistoryEntryEntity(
        song: stampedSong,
        lastPlayedAt: now,
        playCount: 1,
      ),
      incrementPlayCount: true,
      preserveProgress: true,
    );

    state = state.copyWith(entries: updatedEntries, clearErrorMessage: true);

    try {
      await repository.addRecent(userId, stampedSong);
    } catch (_) {
      // Ignore background save errors to avoid interrupting playback UX.
    }
  }

  Future<void> syncPlaybackProgress(
    SongEntity song, {
    required Duration position,
    required Duration duration,
    bool markCompleted = false,
  }) async {
    if (userId == 'guest') {
      return;
    }

    final now = DateTime.now();
    final updatedSong = SongEntity(
      id: song.id,
      title: song.title,
      artist: song.artist,
      audioUrl: song.audioUrl,
      imageUrl: song.imageUrl,
      savedAt: now,
      audioType: song.audioType,
      releaseYear: song.releaseYear,
      trackInWeeklyStats: song.trackInWeeklyStats,
    );

    state = state.copyWith(
      entries: _upsertEntry(
        ListeningHistoryEntryEntity(
          song: updatedSong,
          lastPlayedAt: now,
          playCount: 1,
          completedCount: markCompleted ? 1 : 0,
          lastPosition: markCompleted ? Duration.zero : position,
          duration: duration,
        ),
        incrementCompletedCount: markCompleted,
      ),
      clearErrorMessage: true,
    );

    try {
      await repository.updateRecentProgress(
        userId,
        updatedSong,
        position: position,
        duration: duration,
        markCompleted: markCompleted,
      );
    } catch (_) {
      // Ignore background save errors to avoid interrupting playback UX.
    }
  }

  Future<void> clearRecents() async {
    if (userId == 'guest' || state.entries.isEmpty || state.isClearing) {
      return;
    }

    final previousEntries = state.entries;
    state = state.copyWith(
      entries: const [],
      isClearing: true,
      clearErrorMessage: true,
    );

    try {
      await repository.clearRecents(
        userId,
        previousEntries.map((entry) => entry.song.id).toList(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        entries: previousEntries,
        isClearing: false,
        errorMessage: ErrorMessageMapper.map(error),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(isClearing: false);
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  SongEntity _stampSong(SongEntity song) {
    return SongEntity(
      id: song.id,
      title: song.title,
      artist: song.artist,
      audioUrl: song.audioUrl,
      imageUrl: song.imageUrl,
      savedAt: DateTime.now(),
      audioType: song.audioType,
      releaseYear: song.releaseYear,
      trackInWeeklyStats: song.trackInWeeklyStats,
    );
  }

  List<ListeningHistoryEntryEntity> _upsertEntry(
    ListeningHistoryEntryEntity nextEntry, {
    bool incrementPlayCount = false,
    bool incrementCompletedCount = false,
    bool preserveProgress = false,
  }) {
    final entriesBySongId = <String, ListeningHistoryEntryEntity>{
      for (final entry in state.entries) entry.song.id: entry,
    };

    final current = entriesBySongId[nextEntry.song.id];
    if (current == null) {
      entriesBySongId[nextEntry.song.id] = nextEntry;
      return _dedupeEntries(entriesBySongId.values.toList());
    }

    entriesBySongId[nextEntry.song.id] = current.copyWith(
      song: nextEntry.song,
      lastPlayedAt: nextEntry.lastPlayedAt,
      playCount: incrementPlayCount ? current.playCount + 1 : current.playCount,
      completedCount: incrementCompletedCount
          ? current.completedCount + 1
          : current.completedCount,
      lastPosition: preserveProgress
          ? current.lastPosition
          : nextEntry.lastPosition,
      duration: preserveProgress
          ? (current.duration == Duration.zero
                ? nextEntry.duration
                : current.duration)
          : (nextEntry.duration == Duration.zero
                ? current.duration
                : nextEntry.duration),
      clearLastPosition:
          !preserveProgress && nextEntry.lastPosition == Duration.zero,
    );

    return _dedupeEntries(entriesBySongId.values.toList());
  }

  List<ListeningHistoryEntryEntity> _dedupeEntries(
    List<ListeningHistoryEntryEntity> entries,
  ) {
    final dedupedById = <String, ListeningHistoryEntryEntity>{};
    for (final entry in entries) {
      dedupedById[entry.song.id] = entry;
    }

    final deduped = dedupedById.values.toList();
    deduped.sort((left, right) {
      final rightTime = right.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      final leftTime = left.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      return rightTime.compareTo(leftTime);
    });

    if (deduped.length <= 50) {
      return deduped;
    }

    return deduped.take(50).toList(growable: false);
  }
}
