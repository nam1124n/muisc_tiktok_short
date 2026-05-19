import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/usecases/get_songs_usecase.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';

final librarySongCatalogProvider =
    StateNotifierProvider<LibrarySongCatalogNotifier, LibrarySongCatalogState>((
      ref,
    ) {
      return LibrarySongCatalogNotifier(
        getSongsUseCase: ref.read(getSongsUseCaseProvider),
      );
    });

class LibrarySongCatalogState extends Equatable {
  const LibrarySongCatalogState({
    this.songs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  const LibrarySongCatalogState.initial() : this(isLoading: true);

  final List<SongEntity> songs;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError =>
      errorMessage != null && errorMessage!.trim().isNotEmpty && songs.isEmpty;

  bool get isEmpty => songs.isEmpty && !isLoading && !hasError;

  LibrarySongCatalogState copyWith({
    List<SongEntity>? songs,
    bool? isLoading,
    Object? errorMessage = _librarySongCatalogNoChange,
  }) {
    return LibrarySongCatalogState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _librarySongCatalogNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [songs, isLoading, errorMessage];
}

class LibrarySongCatalogNotifier
    extends StateNotifier<LibrarySongCatalogState> {
  LibrarySongCatalogNotifier({required this.getSongsUseCase})
    : super(const LibrarySongCatalogState.initial()) {
    loadSongs();
  }

  final GetSongsUseCase getSongsUseCase;
  StreamSubscription<List<SongEntity>>? _songsSubscription;

  Future<void> loadSongs() async {
    await _songsSubscription?.cancel();
    state = state.copyWith(isLoading: true, errorMessage: null);

    _songsSubscription = getSongsUseCase().listen(
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

const _librarySongCatalogNoChange = Object();
