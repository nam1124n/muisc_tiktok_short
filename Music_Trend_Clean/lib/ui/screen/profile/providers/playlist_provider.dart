import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/data/datasource/remote/playlist_remote_data_source.dart';
import 'package:login_flutter/data/repositories/playlist_repository_impl.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/repositories/playlist_repository.dart';
import 'package:login_flutter/domain/usecases/create_playlist_usecase.dart';
import 'package:login_flutter/domain/usecases/delete_playlist_usecase.dart';
import 'package:login_flutter/domain/usecases/get_user_playlists_usecase.dart';
import 'package:login_flutter/domain/usecases/update_playlist_name_usecase.dart';
import 'package:login_flutter/domain/usecases/update_playlist_songs_usecase.dart';

final playlistRemoteDataSourceProvider = Provider<PlaylistRemoteDataSource>((
  ref,
) {
  return PlaylistRemoteDataSourceImpl();
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(
    remoteDataSource: ref.read(playlistRemoteDataSourceProvider),
  );
});

final getUserPlaylistsUseCaseProvider = Provider<GetUserPlaylistsUseCase>((
  ref,
) {
  return GetUserPlaylistsUseCase(ref.read(playlistRepositoryProvider));
});

final createPlaylistUseCaseProvider = Provider<CreatePlaylistUseCase>((ref) {
  return CreatePlaylistUseCase(ref.read(playlistRepositoryProvider));
});

final updatePlaylistNameUseCaseProvider = Provider<UpdatePlaylistNameUseCase>((
  ref,
) {
  return UpdatePlaylistNameUseCase(ref.read(playlistRepositoryProvider));
});

final updatePlaylistSongsUseCaseProvider = Provider<UpdatePlaylistSongsUseCase>(
  (ref) {
    return UpdatePlaylistSongsUseCase(ref.read(playlistRepositoryProvider));
  },
);

final deletePlaylistUseCaseProvider = Provider<DeletePlaylistUseCase>((ref) {
  return DeletePlaylistUseCase(ref.read(playlistRepositoryProvider));
});

final playlistNotifierProvider =
    StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
      final userId = ref.watch(sessionCurrentUserIdProvider) ?? 'guest';

      return PlaylistNotifier(
        userId: userId,
        getUserPlaylistsUseCase: ref.read(getUserPlaylistsUseCaseProvider),
        createPlaylistUseCase: ref.read(createPlaylistUseCaseProvider),
        updatePlaylistNameUseCase: ref.read(updatePlaylistNameUseCaseProvider),
        updatePlaylistSongsUseCase: ref.read(
          updatePlaylistSongsUseCaseProvider,
        ),
        deletePlaylistUseCase: ref.read(deletePlaylistUseCaseProvider),
      );
    });

const _playlistStateNoChange = Object();

enum PlaylistErrorType {
  emptyName,
  playlistNotFound,
  authenticationRequiredForCreate,
  authenticationRequiredForUpdate,
  authenticationRequiredForDelete,
}

class PlaylistState extends Equatable {
  final List<PlaylistEntity> playlists;
  final bool isLoading;
  final bool isCreating;
  final bool isSaving;
  final PlaylistErrorType? errorType;
  final String? errorMessage;

  const PlaylistState({
    this.playlists = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isSaving = false,
    this.errorType,
    this.errorMessage,
  });

  const PlaylistState.initial()
    : playlists = const [],
      isLoading = false,
      isCreating = false,
      isSaving = false,
      errorType = null,
      errorMessage = null;

  PlaylistState copyWith({
    List<PlaylistEntity>? playlists,
    bool? isLoading,
    bool? isCreating,
    bool? isSaving,
    Object? errorType = _playlistStateNoChange,
    Object? errorMessage = _playlistStateNoChange,
    bool clearErrorMessage = false,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isSaving: isSaving ?? this.isSaving,
      errorType: clearErrorMessage
          ? null
          : errorType == _playlistStateNoChange
          ? this.errorType
          : errorType as PlaylistErrorType?,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage == _playlistStateNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    playlists,
    isLoading,
    isCreating,
    isSaving,
    errorType,
    errorMessage,
  ];
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final String userId;
  final GetUserPlaylistsUseCase getUserPlaylistsUseCase;
  final CreatePlaylistUseCase createPlaylistUseCase;
  final UpdatePlaylistNameUseCase updatePlaylistNameUseCase;
  final UpdatePlaylistSongsUseCase updatePlaylistSongsUseCase;
  final DeletePlaylistUseCase deletePlaylistUseCase;

  PlaylistNotifier({
    required this.userId,
    required this.getUserPlaylistsUseCase,
    required this.createPlaylistUseCase,
    required this.updatePlaylistNameUseCase,
    required this.updatePlaylistSongsUseCase,
    required this.deletePlaylistUseCase,
  }) : super(const PlaylistState.initial()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    if (userId == 'guest') {
      state = const PlaylistState.initial();
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final playlists = await getUserPlaylistsUseCase(userId);
      if (!mounted) return;
      state = state.copyWith(
        playlists: _sortPlaylists(playlists),
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageMapper.map(e),
      );
    }
  }

  Future<bool> createPlaylist(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      state = state.copyWith(errorType: PlaylistErrorType.emptyName);
      return false;
    }

    if (userId == 'guest') {
      state = state.copyWith(
        errorType: PlaylistErrorType.authenticationRequiredForCreate,
      );
      return false;
    }

    state = state.copyWith(isCreating: true, clearErrorMessage: true);

    try {
      final playlist = await createPlaylistUseCase(
        userId: userId,
        name: trimmedName,
      );
      if (!mounted) return false;

      state = state.copyWith(
        playlists: _sortPlaylists([playlist, ...state.playlists]),
        isCreating: false,
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isCreating: false,
        errorType: null,
        errorMessage: ErrorMessageMapper.map(e),
      );
      return false;
    }
  }

  Future<bool> renamePlaylist({
    required String playlistId,
    required String name,
  }) async {
    final currentPlaylist = findById(playlistId);
    final trimmedName = name.trim();

    if (currentPlaylist == null) {
      state = state.copyWith(errorType: PlaylistErrorType.playlistNotFound);
      return false;
    }

    if (trimmedName.isEmpty) {
      state = state.copyWith(errorType: PlaylistErrorType.emptyName);
      return false;
    }

    if (trimmedName == currentPlaylist.name) {
      return true;
    }

    if (userId == 'guest') {
      state = state.copyWith(
        errorType: PlaylistErrorType.authenticationRequiredForUpdate,
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      await updatePlaylistNameUseCase(
        userId: userId,
        playlistId: playlistId,
        name: trimmedName,
      );
      if (!mounted) return false;

      final updatedPlaylist = currentPlaylist.copyWith(
        name: trimmedName,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        playlists: _sortPlaylists([
          for (final playlist in state.playlists)
            if (playlist.id == playlistId) updatedPlaylist else playlist,
        ]),
        isSaving: false,
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorType: null,
        errorMessage: ErrorMessageMapper.map(e),
      );
      return false;
    }
  }

  PlaylistEntity? findById(String playlistId) {
    for (final playlist in state.playlists) {
      if (playlist.id == playlistId) {
        return playlist;
      }
    }

    return null;
  }

  Future<bool> savePlaylistSongs({
    required String playlistId,
    required List<String> songIds,
  }) async {
    final currentPlaylist = findById(playlistId);

    if (currentPlaylist == null) {
      state = state.copyWith(errorType: PlaylistErrorType.playlistNotFound);
      return false;
    }

    if (userId == 'guest') {
      state = state.copyWith(
        errorType: PlaylistErrorType.authenticationRequiredForUpdate,
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      await updatePlaylistSongsUseCase(
        userId: userId,
        playlistId: playlistId,
        songIds: songIds,
      );
      if (!mounted) return false;

      final updatedPlaylist = currentPlaylist.copyWith(
        songIds: songIds,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        playlists: _sortPlaylists([
          for (final playlist in state.playlists)
            if (playlist.id == playlistId) updatedPlaylist else playlist,
        ]),
        isSaving: false,
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorType: null,
        errorMessage: ErrorMessageMapper.map(e),
      );
      return false;
    }
  }

  Future<bool> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    final currentPlaylist = findById(playlistId);
    if (currentPlaylist == null) {
      state = state.copyWith(errorType: PlaylistErrorType.playlistNotFound);
      return false;
    }

    if (!currentPlaylist.songIds.contains(songId)) {
      return true;
    }

    final updatedSongIds = [
      for (final id in currentPlaylist.songIds)
        if (id != songId) id,
    ];

    return savePlaylistSongs(playlistId: playlistId, songIds: updatedSongIds);
  }

  Future<bool> deletePlaylist(String playlistId) async {
    if (userId == 'guest') {
      state = state.copyWith(
        errorType: PlaylistErrorType.authenticationRequiredForDelete,
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      await deletePlaylistUseCase(userId: userId, playlistId: playlistId);
      if (!mounted) return false;
      state = state.copyWith(
        playlists: [
          for (final playlist in state.playlists)
            if (playlist.id != playlistId) playlist,
        ],
        isSaving: false,
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorType: null,
        errorMessage: ErrorMessageMapper.map(e),
      );
      return false;
    }
  }

  List<PlaylistEntity> _sortPlaylists(List<PlaylistEntity> playlists) {
    final sorted = [...playlists];
    sorted.sort((left, right) {
      final rightTime =
          right.updatedAt?.millisecondsSinceEpoch ??
          right.createdAt?.millisecondsSinceEpoch ??
          0;
      final leftTime =
          left.updatedAt?.millisecondsSinceEpoch ??
          left.createdAt?.millisecondsSinceEpoch ??
          0;
      return rightTime.compareTo(leftTime);
    });
    return sorted;
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }
}
