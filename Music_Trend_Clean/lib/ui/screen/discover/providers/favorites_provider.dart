import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/data/datasource/remote/interaction_remote_data_source.dart';
import 'package:login_flutter/data/repositories/interaction_repository_impl.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';

final interactionRemoteDataSourceProvider =
    Provider<InteractionRemoteDataSource>((ref) {
      return InteractionRemoteDataSourceImpl();
    });

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepositoryImpl(
    ref.read(interactionRemoteDataSourceProvider),
  );
});

final favoriteNotifierProvider =
    StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
      final userId = ref.watch(sessionCurrentUserIdProvider) ?? 'guest';
      return FavoriteNotifier(
        userId: userId,
        repository: ref.read(interactionRepositoryProvider),
      );
    });

final favoriteSongsProvider = Provider<List<SongEntity>>((ref) {
  return ref.watch(favoriteNotifierProvider.select((state) => state.songs));
});

final isFavoriteSongProvider = Provider.family<bool, String>((ref, songId) {
  return ref.watch(
    favoriteNotifierProvider.select(
      (state) => state.favoriteSongIds.contains(songId),
    ),
  );
});

final isFavoriteSongBusyProvider = Provider.family<bool, String>((ref, songId) {
  return ref.watch(
    favoriteNotifierProvider.select(
      (state) => state.processingSongIds.contains(songId),
    ),
  );
});

const _favoriteStateNoChange = Object();

class FavoriteState extends Equatable {
  const FavoriteState({
    this.songs = const [],
    this.isLoading = false,
    this.isClearing = false,
    this.processingSongIds = const <String>{},
    this.errorMessage,
  });

  const FavoriteState.initial()
    : songs = const [],
      isLoading = false,
      isClearing = false,
      processingSongIds = const <String>{},
      errorMessage = null;

  final List<SongEntity> songs;
  final bool isLoading;
  final bool isClearing;
  final Set<String> processingSongIds;
  final String? errorMessage;

  Set<String> get favoriteSongIds => {for (final song in songs) song.id};

  FavoriteState copyWith({
    List<SongEntity>? songs,
    bool? isLoading,
    bool? isClearing,
    Set<String>? processingSongIds,
    Object? errorMessage = _favoriteStateNoChange,
    bool clearErrorMessage = false,
  }) {
    return FavoriteState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      isClearing: isClearing ?? this.isClearing,
      processingSongIds: processingSongIds ?? this.processingSongIds,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage == _favoriteStateNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    songs,
    isLoading,
    isClearing,
    processingSongIds.toList()..sort(),
    errorMessage,
  ];
}

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  FavoriteNotifier({required this.userId, required this.repository})
    : super(const FavoriteState.initial()) {
    if (userId != 'guest') {
      _loadFavorites();
    }
  }

  final String userId;
  final InteractionRepository repository;

  Future<void> _loadFavorites({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }

    try {
      final loaded = await repository.getFavorites(userId);
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        songs: _dedupeSongs(loaded),
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
      state = const FavoriteState.initial();
      return;
    }

    await _loadFavorites(showLoading: state.songs.isEmpty);
  }

  Future<void> toggleFavorite(SongEntity song) async {
    if (userId == 'guest') {
      return;
    }

    if (state.processingSongIds.contains(song.id)) {
      return;
    }

    final previousSongs = state.songs;
    final isFavorite = previousSongs.any((item) => item.id == song.id);
    final nextSongs = _dedupeSongs([
      if (!isFavorite) song,
      for (final item in previousSongs)
        if (item.id != song.id) item,
    ]);

    state = state.copyWith(
      songs: nextSongs,
      processingSongIds: {...state.processingSongIds, song.id},
      clearErrorMessage: true,
    );

    try {
      await repository.toggleFavorite(userId, song, !isFavorite);
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        songs: previousSongs,
        processingSongIds: _withoutProcessing(song.id),
        errorMessage: ErrorMessageMapper.map(error),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(processingSongIds: _withoutProcessing(song.id));
  }

  Future<void> clearFavorites() async {
    if (userId == 'guest' || state.songs.isEmpty || state.isClearing) {
      return;
    }

    final previousSongs = state.songs;
    state = state.copyWith(
      songs: const [],
      isClearing: true,
      clearErrorMessage: true,
    );

    try {
      await repository.clearFavorites(
        userId,
        previousSongs.map((song) => song.id).toList(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        songs: previousSongs,
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

  bool isFavorite(String songId) {
    return state.favoriteSongIds.contains(songId);
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  Set<String> _withoutProcessing(String songId) {
    return {
      for (final id in state.processingSongIds)
        if (id != songId) id,
    };
  }

  List<SongEntity> _dedupeSongs(List<SongEntity> songs) {
    final dedupedById = <String, SongEntity>{};
    for (final song in songs) {
      dedupedById[song.id] = song;
    }

    final deduped = dedupedById.values.toList();
    deduped.sort((left, right) {
      final rightTime = right.savedAt?.millisecondsSinceEpoch ?? 0;
      final leftTime = left.savedAt?.millisecondsSinceEpoch ?? 0;
      return rightTime.compareTo(leftTime);
    });
    return deduped;
  }
}
