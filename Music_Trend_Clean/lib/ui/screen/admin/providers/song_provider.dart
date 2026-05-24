import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/data/repositories/song_repository_impl.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/domain/usecases/add_song_usecase.dart';
import 'package:login_flutter/domain/usecases/delete_song_usecase.dart';
import 'package:login_flutter/domain/usecases/get_admin_songs_usecase.dart';
import 'package:login_flutter/domain/usecases/get_feed_songs_page_usecase.dart';
import 'package:login_flutter/domain/usecases/get_songs_page_usecase.dart';
import 'package:login_flutter/domain/usecases/get_songs_usecase.dart';
import 'package:login_flutter/domain/usecases/get_weekly_trending_songs_usecase.dart';
import 'package:login_flutter/domain/usecases/track_song_listen_usecase.dart';
import 'package:login_flutter/domain/usecases/update_song_usecase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';

final songRemoteDataSourceProvider = Provider<SongRemoteDataSource>((ref) {
  return SongRemoteDataSource();
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(ref.read(songRemoteDataSourceProvider));
});

final getSongsUseCaseProvider = Provider<GetSongsUseCase>((ref) {
  return GetSongsUseCase(ref.read(songRepositoryProvider));
});

final getAdminSongsUseCaseProvider = Provider<GetAdminSongsUseCase>((ref) {
  return GetAdminSongsUseCase(ref.read(songRepositoryProvider));
});

final getSongsPageUseCaseProvider = Provider<GetSongsPageUseCase>((ref) {
  return GetSongsPageUseCase(ref.read(songRepositoryProvider));
});

final getFeedSongsPageUseCaseProvider = Provider<GetFeedSongsPageUseCase>((
  ref,
) {
  return GetFeedSongsPageUseCase(ref.read(songRepositoryProvider));
});

final addSongUseCaseProvider = Provider<AddSongUseCase>((ref) {
  return AddSongUseCase(ref.read(songRepositoryProvider));
});

final updateSongUseCaseProvider = Provider<UpdateSongUseCase>((ref) {
  return UpdateSongUseCase(ref.read(songRepositoryProvider));
});

final deleteSongUseCaseProvider = Provider<DeleteSongUseCase>((ref) {
  return DeleteSongUseCase(ref.read(songRepositoryProvider));
});

final getWeeklyTrendingSongsUseCaseProvider =
    Provider<GetWeeklyTrendingSongsUseCase>((ref) {
      return GetWeeklyTrendingSongsUseCase(ref.read(songRepositoryProvider));
    });

final trackSongListenUseCaseProvider = Provider<TrackSongListenUseCase>((ref) {
  return TrackSongListenUseCase(ref.read(songRepositoryProvider));
});

final adminWeeklyTrendingProvider =
    StreamProvider.autoDispose<List<TrendingSongEntity>>((ref) {
      return ref.read(getWeeklyTrendingSongsUseCaseProvider)(limit: 5);
    });

final songNotifierProvider = StateNotifierProvider<SongNotifier, SongState>((
  ref,
) {
  return SongNotifier(
    watchSongs: ref.read(getSongsUseCaseProvider).call,
    addSongUseCase: ref.read(addSongUseCaseProvider),
    updateSongUseCase: ref.read(updateSongUseCaseProvider),
    deleteSongUseCase: ref.read(deleteSongUseCaseProvider),
  );
});

final adminSongNotifierProvider =
    StateNotifierProvider<SongNotifier, SongState>((ref) {
      return SongNotifier(
        watchSongs: ref.read(getAdminSongsUseCaseProvider).call,
        addSongUseCase: ref.read(addSongUseCaseProvider),
        updateSongUseCase: ref.read(updateSongUseCaseProvider),
        deleteSongUseCase: ref.read(deleteSongUseCaseProvider),
      );
    });

class SongNotifier extends StateNotifier<SongState> {
  final Stream<List<SongEntity>> Function() watchSongs;
  final AddSongUseCase addSongUseCase;
  final UpdateSongUseCase updateSongUseCase;
  final DeleteSongUseCase deleteSongUseCase;
  StreamSubscription<List<SongEntity>>? _songsSubscription;

  SongNotifier({
    required this.watchSongs,
    required this.addSongUseCase,
    required this.updateSongUseCase,
    required this.deleteSongUseCase,
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
      await addSongUseCase(song, imageFile, audioFile);
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
      await updateSongUseCase(song, imageFile: imageFile, audioFile: audioFile);
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
        await deleteSongUseCase(songId);
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
    return updateSongUseCase(
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

  Future<void> deleteSong(String id) async {
    try {
      await deleteSongUseCase(id);
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(ErrorMessageMapper.map(e));
    }
  }

  @override
  void dispose() {
    _songsSubscription?.cancel();
    super.dispose();
  }
}
