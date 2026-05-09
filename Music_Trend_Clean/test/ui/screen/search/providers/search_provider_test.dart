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
      SongEntity(
        id: '4',
        title: 'Thu Cuoi Remix',
        artist: 'DJ Example',
        audioUrl: 'audio-4',
        imageUrl: 'image-4',
      ),
    ];

    testWidgets('returns idle state immediately when query is empty', (
      tester,
    ) async {
      final notifier = SearchNotifier();

      notifier.search(query: '   ', songs: songs);

      expect(notifier.state.status, SearchStatus.idle);
      expect(notifier.state.query, isEmpty);
      expect(notifier.state.results, isEmpty);
      expect(notifier.state.plan, isNull);

      notifier.dispose();
    });

    testWidgets(
      'stays searching until debounce completes then returns results',
      (tester) async {
        final notifier = SearchNotifier();

        notifier.search(query: 'son tung', songs: songs);

        expect(notifier.state.status, SearchStatus.searching);
        expect(notifier.state.query, 'son tung');
        expect(notifier.state.results, isEmpty);

        await tester.pump(const Duration(milliseconds: 279));
        expect(notifier.state.status, SearchStatus.searching);

        await tester.pump(const Duration(milliseconds: 1));
        expect(notifier.state.status, SearchStatus.loaded);
        expect(notifier.state.results.first.id, '1');

        notifier.dispose();
      },
    );

    testWidgets(
      'cancels the previous debounce and keeps only the latest query',
      (tester) async {
        final notifier = SearchNotifier();

        notifier.search(query: 'son tung', songs: songs);
        await tester.pump(const Duration(milliseconds: 120));

        notifier.search(query: 'da lab', songs: songs);
        expect(notifier.state.status, SearchStatus.searching);
        expect(notifier.state.query, 'da lab');

        await tester.pump(const Duration(milliseconds: 280));
        expect(notifier.state.status, SearchStatus.loaded);
        expect(notifier.state.results.first.id, '2');

        notifier.dispose();
      },
    );

    testWidgets('matches artist names after normalizing accents and spaces', (
      tester,
    ) async {
      final notifier = SearchNotifier();

      notifier.search(query: '  sơn tùng  ', songs: songs);
      await tester.pump(const Duration(milliseconds: 280));

      expect(notifier.state.status, SearchStatus.loaded);
      expect(notifier.state.results.first.id, '1');
      expect(notifier.state.plan?.keywords, ['son', 'tung']);

      notifier.dispose();
    });

    testWidgets('keeps exact title matches ahead of partial matches', (
      tester,
    ) async {
      final notifier = SearchNotifier();

      notifier.search(query: 'thu cuoi', songs: songs);
      await tester.pump(const Duration(milliseconds: 280));

      expect(notifier.state.status, SearchStatus.loaded);
      expect(notifier.state.results.map((song) => song.id).take(2), ['3', '4']);

      notifier.dispose();
    });

    testWidgets('returns empty state with search plan when nothing matches', (
      tester,
    ) async {
      final notifier = SearchNotifier();

      notifier.search(query: 'bolero khong ton tai', songs: songs);
      await tester.pump(const Duration(milliseconds: 280));

      expect(notifier.state.status, SearchStatus.empty);
      expect(notifier.state.results, isEmpty);
      expect(notifier.state.plan, isNotNull);
      expect(notifier.state.errorMessage, isNull);

      notifier.dispose();
    });
  });
}
