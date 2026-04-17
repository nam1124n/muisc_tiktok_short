import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/data/repositories/song_repository_impl.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/domain/usecases/add_song_usecase.dart';
import 'package:login_flutter/domain/usecases/delete_song_usecase.dart';
import 'package:login_flutter/domain/usecases/get_songs_usecase.dart';
import 'package:login_flutter/domain/usecases/get_weekly_trending_songs_usecase.dart';
import 'package:login_flutter/domain/usecases/track_song_listen_usecase.dart';
import 'package:login_flutter/domain/usecases/update_song_usecase.dart';
import 'package:image_picker/image_picker.dart';
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

final songNotifierProvider = StateNotifierProvider<SongNotifier, SongState>((
  ref,
) {
  return SongNotifier(
    getSongsUseCase: ref.read(getSongsUseCaseProvider),
    addSongUseCase: ref.read(addSongUseCaseProvider),
    updateSongUseCase: ref.read(updateSongUseCaseProvider),
    deleteSongUseCase: ref.read(deleteSongUseCaseProvider),
  );
});

class SongNotifier extends StateNotifier<SongState> {
  final GetSongsUseCase getSongsUseCase;
  final AddSongUseCase addSongUseCase;
  final UpdateSongUseCase updateSongUseCase;
  final DeleteSongUseCase deleteSongUseCase;
  StreamSubscription<List<SongEntity>>? _songsSubscription;

  SongNotifier({
    required this.getSongsUseCase,
    required this.addSongUseCase,
    required this.updateSongUseCase,
    required this.deleteSongUseCase,
  }) : super(SongInitial()) {
    loadSongs();
  }

  Future<void> loadSongs() async {
    await _songsSubscription?.cancel();
    state = SongLoading();
    _songsSubscription = getSongsUseCase().listen(
      (songs) => state = SongLoaded(songs),
      onError: (Object error, StackTrace _) {
        state = SongError(error.toString());
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
      state = SongError(e.toString());
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
      state = SongError(e.toString());
    }
  }

  Future<void> deleteSong(String id) async {
    try {
      await deleteSongUseCase(id);
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(e.toString());
    }
  }

  @override
  void dispose() {
    _songsSubscription?.cancel();
    super.dispose();
  }
}
