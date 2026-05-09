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
        updatePlaylistSongsUseCase: ref.read(
          updatePlaylistSongsUseCaseProvider,
        ),
        deletePlaylistUseCase: ref.read(deletePlaylistUseCaseProvider),
      );
    });

class PlaylistState extends Equatable {
  final List<PlaylistEntity> playlists;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;

  const PlaylistState({
    this.playlists = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
  });

  const PlaylistState.initial()
    : playlists = const [],
      isLoading = false,
      isCreating = false,
      errorMessage = null;

  PlaylistState copyWith({
    List<PlaylistEntity>? playlists,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [playlists, isLoading, isCreating, errorMessage];
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final String userId;
  final GetUserPlaylistsUseCase getUserPlaylistsUseCase;
  final CreatePlaylistUseCase createPlaylistUseCase;
  final UpdatePlaylistSongsUseCase updatePlaylistSongsUseCase;
  final DeletePlaylistUseCase deletePlaylistUseCase;

  PlaylistNotifier({
    required this.userId,
    required this.getUserPlaylistsUseCase,
    required this.createPlaylistUseCase,
    required this.updatePlaylistSongsUseCase,
    required this.deletePlaylistUseCase,
  }) : super(const PlaylistState.initial()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    if (userId == 'guest') {
      state = const PlaylistState(playlists: []);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final playlists = await getUserPlaylistsUseCase(userId);
      if (!mounted) return;
      state = state.copyWith(playlists: playlists, isLoading: false);
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
      state = state.copyWith(errorMessage: 'Vui lòng nhập tên playlist.');
      return false;
    }

    if (userId == 'guest') {
      state = state.copyWith(
        errorMessage: 'Vui lòng đăng nhập trước khi tạo playlist.',
      );
      return false;
    }

    state = state.copyWith(isCreating: true);

    try {
      final playlist = await createPlaylistUseCase(
        userId: userId,
        name: trimmedName,
      );
      if (!mounted) return false;

      state = state.copyWith(
        playlists: [playlist, ...state.playlists],
        isCreating: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isCreating: false,
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
      state = state.copyWith(errorMessage: 'Không tìm thấy playlist.');
      return false;
    }

    if (userId == 'guest') {
      state = state.copyWith(
        errorMessage: 'Vui lòng đăng nhập trước khi cập nhật playlist.',
      );
      return false;
    }

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
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: ErrorMessageMapper.map(e));
      return false;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    if (userId == 'guest') {
      state = state.copyWith(
        errorMessage: 'Vui lòng đăng nhập trước khi xóa playlist.',
      );
      return false;
    }

    try {
      await deletePlaylistUseCase(userId: userId, playlistId: playlistId);
      if (!mounted) return false;
      state = state.copyWith(
        playlists: [
          for (final playlist in state.playlists)
            if (playlist.id != playlistId) playlist,
        ],
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: ErrorMessageMapper.map(e));
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
    state = state.copyWith(
      playlists: state.playlists,
      isLoading: state.isLoading,
      isCreating: state.isCreating,
    );
  }
}
