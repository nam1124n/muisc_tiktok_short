import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/feed_comment_entity.dart';
import 'package:login_flutter/domain/entities/listening_history_entry_entity.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/domain/repositories/profile_repository.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/domain/usecases/get_feed_songs_page_usecase.dart';
import 'package:login_flutter/domain/usecases/get_profile_usecase.dart';
import 'package:login_flutter/ui/screen/feed/feed_provider.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('FeedNotifier Unit Tests', () {
    late FakeSongRepository songRepository;
    late FakeInteractionRepository interactionRepository;
    late FakeProfileRepository profileRepository;
    late GetFeedSongsPageUseCase getFeedSongsPageUseCase;
    late GetProfileUseCase getProfileUseCase;

    final testSong1 = _song('song-1', 'Title 1');
    final testSong2 = _song('song-2', 'Title 2');
    final testSong3 = _song('song-3', 'Title 3');

    setUp(() {
      songRepository = FakeSongRepository();
      interactionRepository = FakeInteractionRepository();
      profileRepository = FakeProfileRepository();
      getFeedSongsPageUseCase = GetFeedSongsPageUseCase(songRepository);
      getProfileUseCase = GetProfileUseCase(profileRepository);
    });

    test('Initial State is initial loading', () {
      final notifier = FeedNotifier(
        getFeedSongsPageUseCase: getFeedSongsPageUseCase,
        interactionRepository: interactionRepository,
        getProfileUseCase: getProfileUseCase,
        userId: 'user-1',
        userName: 'User One',
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      expect(notifier.state.isInitialLoading, isTrue);
      expect(notifier.state.songs, isEmpty);
      expect(notifier.state.discoverSongs, isEmpty);
      expect(notifier.state.hasMore, isTrue);
    });

    test('Initial load success', () async {
      songRepository.feedSongsPage = SongPageEntity(
        songs: [testSong1, testSong2],
        nextCursor: const SongPageCursor(title: 'Title 2', id: 'song-2'),
        hasMore: true,
      );

      final notifier = FeedNotifier(
        getFeedSongsPageUseCase: getFeedSongsPageUseCase,
        interactionRepository: interactionRepository,
        getProfileUseCase: getProfileUseCase,
        userId: 'user-1',
        userName: 'User One',
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();

      expect(notifier.state.isInitialLoading, isFalse);
      expect(notifier.state.songs, [testSong1, testSong2]);
      expect(notifier.state.hasMore, isTrue);
    });

    test('Refresh keeps old data in state while loading, then updates', () async {
      songRepository.feedSongsPage = SongPageEntity(
        songs: [testSong1],
        nextCursor: const SongPageCursor(title: 'Title 1', id: 'song-1'),
        hasMore: true,
      );

      final notifier = FeedNotifier(
        getFeedSongsPageUseCase: getFeedSongsPageUseCase,
        interactionRepository: interactionRepository,
        getProfileUseCase: getProfileUseCase,
        userId: 'user-1',
        userName: 'User One',
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();
      expect(notifier.state.songs, [testSong1]);

      // Set new page for refresh
      songRepository.feedSongsPage = SongPageEntity(
        songs: [testSong2, testSong3],
        nextCursor: null,
        hasMore: false,
      );

      final future = notifier.refresh();

      // While refreshing, isRefreshing should be true, but discoverSongs is NOT cleared
      expect(notifier.state.isRefreshing, isTrue);
      expect(notifier.state.songs, [testSong1]);

      await future;

      expect(notifier.state.isRefreshing, isFalse);
      expect(notifier.state.songs, [testSong2, testSong3]);
      expect(notifier.state.hasMore, isFalse);
    });

    test('Load more merges duplicate songs by ID', () async {
      songRepository.feedSongsPage = SongPageEntity(
        songs: [testSong1, testSong2],
        nextCursor: const SongPageCursor(title: 'Title 2', id: 'song-2'),
        hasMore: true,
      );

      final notifier = FeedNotifier(
        getFeedSongsPageUseCase: getFeedSongsPageUseCase,
        interactionRepository: interactionRepository,
        getProfileUseCase: getProfileUseCase,
        userId: 'user-1',
        userName: 'User One',
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();

      // Now set next page which has a duplicate testSong2 and a new testSong3
      songRepository.feedSongsPage = SongPageEntity(
        songs: [testSong2, testSong3],
        nextCursor: null,
        hasMore: false,
      );

      await notifier.loadMore();

      // After merge, list of songs should contain song-1, song-2, and song-3 without duplicates
      expect(notifier.state.songs.map((s) => s.id).toList(), [
        'song-1',
        'song-2',
        'song-3',
      ]);
      expect(notifier.state.hasMore, isFalse);
    });

    test('Hide song updates hiddenSongIds and notifies repository', () async {
      songRepository.feedSongsPage = SongPageEntity(
        songs: [testSong1, testSong2],
        nextCursor: null,
        hasMore: false,
      );

      final notifier = FeedNotifier(
        getFeedSongsPageUseCase: getFeedSongsPageUseCase,
        interactionRepository: interactionRepository,
        getProfileUseCase: getProfileUseCase,
        userId: 'user-1',
        userName: 'User One',
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();
      expect(notifier.state.songs, [testSong1, testSong2]);

      await notifier.hideSong(testSong1);

      // The song-1 should be hidden from state.songs (via get songs logic filtering out hiddenSongIds)
      expect(notifier.state.hiddenSongIds, contains('song-1'));
      expect(notifier.state.songs, [testSong2]);
      expect(interactionRepository.hiddenSongs, [testSong1]);
    });

    test('Load more handles error and sets loadMoreErrorMessage', () async {
      songRepository.feedSongsPage = SongPageEntity(
        songs: [testSong1],
        nextCursor: const SongPageCursor(title: 'Title 1', id: 'song-1'),
        hasMore: true,
      );

      final notifier = FeedNotifier(
        getFeedSongsPageUseCase: getFeedSongsPageUseCase,
        interactionRepository: interactionRepository,
        getProfileUseCase: getProfileUseCase,
        userId: 'user-1',
        userName: 'User One',
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();
      expect(notifier.state.songs, [testSong1]);

      // Set repository to throw error
      songRepository.shouldThrow = true;

      await notifier.loadMore();

      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.loadMoreErrorMessage, isNotNull);
      // Songs should still be present
      expect(notifier.state.songs, [testSong1]);
    });
  });
}

// Fake Implementations
class FakeSongRepository implements SongRepository {
  SongPageEntity? feedSongsPage;
  bool shouldThrow = false;

  @override
  Future<SongPageEntity> fetchFeedSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) async {
    if (shouldThrow) {
      throw Exception('Fake repository error');
    }
    return feedSongsPage ??
        const SongPageEntity(songs: [], nextCursor: null, hasMore: false);
  }

  @override
  Future<SongPageEntity> fetchSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<SongEntity>> getSongs() => const Stream.empty();

  @override
  Stream<List<SongEntity>> getAdminSongs() => const Stream.empty();

  @override
  Stream<List<TrendingSongEntity>> getWeeklyTrendingSongs({int limit = 4}) =>
      const Stream.empty();

  @override
  Future<void> addSong(
    SongEntity song,
    XFile imageFile,
    XFile audioFile,
  ) async {}

  @override
  Future<void> updateSong(
    SongEntity song, {
    XFile? imageFile,
    XFile? audioFile,
  }) async {}

  @override
  Future<void> deleteSong(String id) async {}

  @override
  Future<void> trackSongListen(SongEntity song) async {}
}

class FakeInteractionRepository implements InteractionRepository {
  final List<SongEntity> hiddenSongs = [];
  final List<(SongEntity, String)> reportedSongs = [];
  final List<FeedCommentEntity> comments = [];

  @override
  Future<List<SongEntity>> getFavorites(String userId) async => [];

  @override
  Future<void> toggleFavorite(
    String userId,
    SongEntity song,
    bool isFavorite,
  ) async {}

  @override
  Future<void> clearFavorites(String userId, List<String> songIds) async {}

  @override
  Future<List<ListeningHistoryEntryEntity>> getHistoryEntries(
    String userId,
  ) async => [];

  @override
  Future<void> addRecent(String userId, SongEntity song) async {}

  @override
  Future<void> updateRecentProgress(
    String userId,
    SongEntity song, {
    required Duration position,
    required Duration duration,
    bool markCompleted = false,
  }) async {}

  @override
  Future<void> clearRecents(String userId, List<String> songIds) async {}

  @override
  Future<Set<String>> getHiddenFeedSongIds(String userId) async => {};

  @override
  Future<void> hideFeedSong(String userId, SongEntity song) async {
    hiddenSongs.add(song);
  }

  @override
  Future<void> reportSong({
    required String userId,
    required SongEntity song,
    required String reason,
  }) async {
    reportedSongs.add((song, reason));
  }

  @override
  Stream<List<FeedCommentEntity>> watchSongComments(String songId) {
    return Stream.value(comments.where((c) => c.songId == songId).toList());
  }

  @override
  Future<void> addSongComment({
    required String userId,
    required String userName,
    required String songId,
    required String text,
  }) async {
    comments.add(
      FeedCommentEntity(
        id: 'comment-${comments.length + 1}',
        userId: userId,
        userName: userName,
        songId: songId,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteSongComment({
    required String songId,
    required String commentId,
  }) async {
    comments.removeWhere((c) => c.id == commentId);
  }
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<ProfileEntity> getProfile() async {
    return const ProfileEntity(
      id: 'user-1',
      username: 'User One',
      avatarUrl: '',
      followers: 0,
      following: 0,
      likes: 0,
      ageGroup: ProfileAgeGroups.adults,
    );
  }

  @override
  Future<ProfileEntity> getProfileById(String userId) async {
    return getProfile();
  }

  @override
  Future<void> updateAvatarUrl(String url) async {}

  @override
  Future<void> updateProfile({
    required String username,
    required String ageGroup,
  }) async {}
}

SongEntity _song(String id, String title) {
  return SongEntity(
    id: id,
    title: title,
    artist: 'Artist $id',
    audioUrl: 'audio-$id',
    imageUrl: 'image-$id',
  );
}
