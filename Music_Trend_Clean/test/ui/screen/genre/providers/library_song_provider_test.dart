import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/domain/usecases/get_songs_usecase.dart';
import 'package:login_flutter/ui/screen/genre/providers/library_song_provider.dart';

void main() {
  group('LibrarySongCatalogNotifier', () {
    test('loads songs from the songs use case stream', () async {
      final songs = [
        _song('1', 'Short song'),
        _song('2', 'Full song', audioType: SongAudioTypes.full, year: 2024),
      ];
      final notifier = LibrarySongCatalogNotifier(
        getSongsUseCase: GetSongsUseCase(
          FakeSongRepository(songsStream: Stream.value(songs)),
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.songs.map((song) => song.id), ['1', '2']);
      expect(notifier.state.songs.last.audioType, SongAudioTypes.full);
      expect(notifier.state.songs.last.releaseYear, 2024);
    });
  });
}

class FakeSongRepository implements SongRepository {
  const FakeSongRepository({required this.songsStream});

  final Stream<List<SongEntity>> songsStream;

  @override
  Stream<List<SongEntity>> getSongs() => songsStream;

  @override
  Stream<List<SongEntity>> getAdminSongs() => const Stream.empty();

  @override
  Future<SongPageEntity> fetchSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<TrendingSongEntity>> getWeeklyTrendingSongs({int limit = 4}) {
    return const Stream.empty();
  }

  @override
  Future<void> addSong(SongEntity song, XFile imageFile, XFile audioFile) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSong(
    SongEntity song, {
    XFile? imageFile,
    XFile? audioFile,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSong(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> trackSongListen(SongEntity song) {
    throw UnimplementedError();
  }
}

SongEntity _song(
  String id,
  String title, {
  String audioType = SongAudioTypes.short,
  int year = 2026,
}) {
  return SongEntity(
    id: id,
    title: title,
    artist: 'Artist $id',
    audioUrl: 'audio-$id',
    imageUrl: 'image-$id',
    audioType: audioType,
    releaseYear: year,
  );
}
