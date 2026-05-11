import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/data/datasource/remote/year_song_remote_data_source.dart';
import 'package:login_flutter/data/repositories/year_song_repository_impl.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/year_song_repository.dart';
import 'package:login_flutter/domain/usecases/add_year_song_usecase.dart';
import 'package:login_flutter/domain/usecases/delete_year_song_usecase.dart';
import 'package:login_flutter/domain/usecases/get_admin_year_songs_usecase.dart';
import 'package:login_flutter/domain/usecases/get_year_songs_usecase.dart';
import 'package:login_flutter/domain/usecases/update_year_song_usecase.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';

final yearSongRemoteDataSourceProvider = Provider<YearSongRemoteDataSource>((
  ref,
) {
  return YearSongRemoteDataSource();
});

final yearSongMediaRemoteDataSourceProvider = Provider<SongRemoteDataSource>((
  ref,
) {
  return SongRemoteDataSource();
});

final yearSongRepositoryProvider = Provider<YearSongRepository>((ref) {
  return YearSongRepositoryImpl(
    ref.read(yearSongRemoteDataSourceProvider),
    ref.read(yearSongMediaRemoteDataSourceProvider),
  );
});

final getYearSongsUseCaseProvider = Provider<GetYearSongsUseCase>((ref) {
  return GetYearSongsUseCase(ref.read(yearSongRepositoryProvider));
});

final getAdminYearSongsUseCaseProvider = Provider<GetAdminYearSongsUseCase>((
  ref,
) {
  return GetAdminYearSongsUseCase(ref.read(yearSongRepositoryProvider));
});

final addYearSongUseCaseProvider = Provider<AddYearSongUseCase>((ref) {
  return AddYearSongUseCase(ref.read(yearSongRepositoryProvider));
});

final updateYearSongUseCaseProvider = Provider<UpdateYearSongUseCase>((ref) {
  return UpdateYearSongUseCase(ref.read(yearSongRepositoryProvider));
});

final deleteYearSongUseCaseProvider = Provider<DeleteYearSongUseCase>((ref) {
  return DeleteYearSongUseCase(ref.read(yearSongRepositoryProvider));
});

final yearSongNotifierProvider =
    StateNotifierProvider<YearSongNotifier, SongState>((ref) {
      return YearSongNotifier(
        watchSongs: ref.read(getAdminYearSongsUseCaseProvider).call,
        addYearSongUseCase: ref.read(addYearSongUseCaseProvider),
        updateYearSongUseCase: ref.read(updateYearSongUseCaseProvider),
        deleteYearSongUseCase: ref.read(deleteYearSongUseCaseProvider),
      );
    });

final yearSongCatalogProvider =
    StateNotifierProvider<YearSongCatalogNotifier, YearSongCatalogState>((ref) {
      return YearSongCatalogNotifier(
        getYearSongsUseCase: ref.read(getYearSongsUseCaseProvider),
      );
    });

class YearSongCatalogState extends Equatable {
  const YearSongCatalogState({
    this.songs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  const YearSongCatalogState.initial() : this(isLoading: true);

  final List<SongEntity> songs;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError =>
      errorMessage != null && errorMessage!.trim().isNotEmpty && songs.isEmpty;

  bool get isEmpty => songs.isEmpty && !isLoading && !hasError;

  YearSongCatalogState copyWith({
    List<SongEntity>? songs,
    bool? isLoading,
    Object? errorMessage = _yearSongCatalogNoChange,
  }) {
    return YearSongCatalogState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _yearSongCatalogNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [songs, isLoading, errorMessage];
}

const _yearSongCatalogNoChange = Object();

class YearSongCatalogNotifier extends StateNotifier<YearSongCatalogState> {
  YearSongCatalogNotifier({required this.getYearSongsUseCase})
    : super(const YearSongCatalogState.initial()) {
    loadSongs();
  }

  final GetYearSongsUseCase getYearSongsUseCase;
  StreamSubscription<List<SongEntity>>? _songsSubscription;

  Future<void> loadSongs() async {
    await _songsSubscription?.cancel();
    state = state.copyWith(isLoading: true, errorMessage: null);

    _songsSubscription = getYearSongsUseCase().listen(
      (songs) {
        state = state.copyWith(
          songs: songs,
          isLoading: false,
          errorMessage: null,
        );
      },
      onError: (Object error, StackTrace _) {
        state = state.copyWith(
          songs: const [],
          isLoading: false,
          errorMessage: ErrorMessageMapper.map(error),
        );
      },
    );
  }

  Future<void> reload() => loadSongs();

  @override
  void dispose() {
    _songsSubscription?.cancel();
    super.dispose();
  }
}

class YearSongNotifier extends StateNotifier<SongState> {
  final Stream<List<SongEntity>> Function() watchSongs;
  final AddYearSongUseCase addYearSongUseCase;
  final UpdateYearSongUseCase updateYearSongUseCase;
  final DeleteYearSongUseCase deleteYearSongUseCase;
  StreamSubscription<List<SongEntity>>? _songsSubscription;

  YearSongNotifier({
    required this.watchSongs,
    required this.addYearSongUseCase,
    required this.updateYearSongUseCase,
    required this.deleteYearSongUseCase,
  }) : super(SongInitial()) {
    loadSongs();
  }

  Future<void> loadSongs() async {
    await _songsSubscription?.cancel();
    state = SongLoading();
    _songsSubscription = watchSongs().listen(
      (songs) => state = SongLoaded(songs),
      onError: (Object error, StackTrace _) {
        state = SongError(ErrorMessageMapper.map(error));
      },
    );
  }

  Future<void> addSong(
    SongEntity song,
    XFile imageFile,
    XFile audioFile,
  ) async {
    state = SongLoading();

    try {
      await addYearSongUseCase(song, imageFile, audioFile);
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(ErrorMessageMapper.map(e));
    }
  }

  Future<void> updateSong(
    SongEntity song, {
    XFile? imageFile,
    XFile? audioFile,
  }) async {
    state = SongLoading();

    try {
      await updateYearSongUseCase(
        song,
        imageFile: imageFile,
        audioFile: audioFile,
      );
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(ErrorMessageMapper.map(e));
    }
  }

  Future<void> deleteSong(String id) async {
    try {
      await deleteYearSongUseCase(id);
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(ErrorMessageMapper.map(e));
    }
  }

  Future<void> updateSongModeration(
    SongEntity song, {
    required String status,
    String moderationReason = '',
    String moderatedBy = '',
  }) async {
    state = SongLoading();

    try {
      await _saveModeratedSong(
        song,
        status: status,
        moderationReason: moderationReason,
        moderatedBy: moderatedBy,
      );
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(ErrorMessageMapper.map(e));
    }
  }

  Future<void> updateSongsModerationBatch(
    List<SongEntity> songs, {
    required String status,
    String moderationReason = '',
    String moderatedBy = '',
  }) async {
    state = SongLoading();

    try {
      for (final song in songs) {
        await _saveModeratedSong(
          song,
          status: status,
          moderationReason: moderationReason,
          moderatedBy: moderatedBy,
        );
      }
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(ErrorMessageMapper.map(e));
    }
  }

  Future<void> archiveSongsById(Iterable<String> songIds) async {
    state = SongLoading();

    try {
      for (final songId in songIds) {
        await deleteYearSongUseCase(songId);
      }
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(ErrorMessageMapper.map(e));
    }
  }

  Future<void> _saveModeratedSong(
    SongEntity song, {
    required String status,
    required String moderationReason,
    required String moderatedBy,
  }) {
    final now = DateTime.now();
    return updateYearSongUseCase(
      song.copyWith(
        status: status,
        moderationReason: moderationReason,
        moderatedBy: moderatedBy,
        moderatedAt: now,
        publishedAt: status == SongStatuses.published ? now : song.publishedAt,
        updatedAt: now,
        deletedAt: status == SongStatuses.archived ? now : null,
      ),
    );
  }

  @override
  void dispose() {
    _songsSubscription?.cancel();
    super.dispose();
  }
}
