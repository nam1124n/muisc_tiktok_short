import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/search/providers/search_provider.dart';
import 'package:login_flutter/ui/screen/search/providers/search_state.dart';

void main() {
  group('SearchNotifier', () {
    const songs = [
      SongEntity(
        id: '1',
        title: 'Chay Ngay Di',
        artist: 'Son Tung M-TP',
        audioUrl: 'audio-1',
        imageUrl: 'image-1',
      ),
      SongEntity(
        id: '2',
        title: 'Loi Nho',
        artist: 'Da LAB',
        audioUrl: 'audio-2',
        imageUrl: 'image-2',
      ),
      SongEntity(
        id: '3',
        title: 'Thu Cuoi',
        artist: 'Yanbi',
        audioUrl: 'audio-3',
        imageUrl: 'image-3',
      ),
    ];

    test('returns initial state when query is empty', () async {
      final notifier = SearchNotifier();

      await notifier.search(query: '   ', songs: songs);

      expect(notifier.state, isA<SearchInitial>());
    });

    test('matches artist names after normalizing accents and spaces', () async {
      final notifier = SearchNotifier();

      await notifier.search(query: '  sơn tùng  ', songs: songs);

      final state = notifier.state as SearchLoaded;
      expect(state.results.first.id, '1');
      expect(state.plan.keywords, ['son', 'tung']);
    });

    test('matches artist name with local search', () async {
      final notifier = SearchNotifier();

      await notifier.search(query: 'da lab', songs: songs);

      final state = notifier.state as SearchLoaded;
      expect(state.results.first.id, '2');
      expect(state.plan.provider, 'normal');
    });

    test('keeps exact title matches first', () async {
      final notifier = SearchNotifier();

      await notifier.search(query: 'thu cuoi', songs: songs);

      final state = notifier.state as SearchLoaded;
      expect(state.results.first.id, '3');
    });

    test('does not match removed tag or alias metadata anymore', () async {
      final notifier = SearchNotifier();

      await notifier.search(query: 'tiktok', songs: songs);

      final state = notifier.state as SearchLoaded;
      expect(state.results, isEmpty);
    });

    test(
      'returns loaded state with empty results when nothing matches',
      () async {
        final notifier = SearchNotifier();

        await notifier.search(query: 'bolero khong ton tai', songs: songs);

        final state = notifier.state as SearchLoaded;
        expect(state.results, isEmpty);
      },
    );
  });
}
