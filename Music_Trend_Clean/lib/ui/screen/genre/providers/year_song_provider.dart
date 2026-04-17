import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/data/datasource/remote/year_song_remote_data_source.dart';
import 'package:login_flutter/data/repositories/year_song_repository_impl.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/year_song_repository.dart';
import 'package:login_flutter/domain/usecases/add_year_song_usecase.dart';
import 'package:login_flutter/domain/usecases/delete_year_song_usecase.dart';
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
        getYearSongsUseCase: ref.read(getYearSongsUseCaseProvider),
        addYearSongUseCase: ref.read(addYearSongUseCaseProvider),
        updateYearSongUseCase: ref.read(updateYearSongUseCaseProvider),
        deleteYearSongUseCase: ref.read(deleteYearSongUseCaseProvider),
      );
    });

class YearSongNotifier extends StateNotifier<SongState> {
  final GetYearSongsUseCase getYearSongsUseCase;
  final AddYearSongUseCase addYearSongUseCase;
  final UpdateYearSongUseCase updateYearSongUseCase;
  final DeleteYearSongUseCase deleteYearSongUseCase;
  StreamSubscription<List<SongEntity>>? _songsSubscription;

  YearSongNotifier({
    required this.getYearSongsUseCase,
    required this.addYearSongUseCase,
    required this.updateYearSongUseCase,
    required this.deleteYearSongUseCase,
  }) : super(SongInitial()) {
    loadSongs();
  }

  Future<void> loadSongs() async {
    await _songsSubscription?.cancel();
    state = SongLoading();
    _songsSubscription = getYearSongsUseCase().listen(
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
      await addYearSongUseCase(song, imageFile, audioFile);
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
      await updateYearSongUseCase(
        song,
        imageFile: imageFile,
        audioFile: audioFile,
      );
      state = SongActionSuccess();
    } catch (e) {
      state = SongError(e.toString());
    }
  }

  Future<void> deleteSong(String id) async {
    try {
      await deleteYearSongUseCase(id);
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
