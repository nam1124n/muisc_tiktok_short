import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/entities/feed_comment_entity.dart';
import 'package:login_flutter/domain/entities/listening_history_entry_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/domain/repositories/profile_repository.dart';
import 'package:login_flutter/domain/repositories/playlist_repository.dart';
import 'package:login_flutter/domain/usecases/get_feed_songs_page_usecase.dart';
import 'package:login_flutter/domain/usecases/get_profile_usecase.dart';
import 'package:login_flutter/domain/usecases/track_song_listen_usecase.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/feed/feed_screen.dart';
import 'package:login_flutter/ui/screen/feed/feed_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });
  late FakeSongRepository songRepository;
  late FakeInteractionRepository interactionRepository;
  late FakeProfileRepository profileRepository;
  late FakePlaylistRepository playlistRepository;
  late FakeAuthRepository authRepository;

  final testSong1 = _song('song-1', 'Song Title One', 'Artist One');
  final testSong2 = _song('song-2', 'Song Title Two', 'Artist Two');

  setUp(() {
    songRepository = FakeSongRepository();
    interactionRepository = FakeInteractionRepository();
    profileRepository = FakeProfileRepository();
    playlistRepository = FakePlaylistRepository(playlists: []);
    authRepository = FakeAuthRepository(currentUser: _user());

    // Mock platform channel for just_audio
    const channel = MethodChannel('com.ryanheise.just_audio.methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'init') {
            final id = methodCall.arguments['id'];
            final playerChannel = MethodChannel(
              'com.ryanheise.just_audio.methods.$id',
            );
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(playerChannel, (
                  MethodCall playerCall,
                ) async {
                  return {};
                });
          }
          return {};
        });
  });

  Widget buildTestApp({
    required FeedState feedState,
    VoidCallback? onRefresh,
    VoidCallback? onLoadMore,
    ValueChanged<SongEntity>? onHideSong,
    ValueChanged<FeedTabType>? onSelectTab,
    Function(SongEntity, String)? onSubmitReport,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        songRepositoryProvider.overrideWithValue(songRepository),
        interactionRepositoryProvider.overrideWithValue(interactionRepository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        playlistRepositoryProvider.overrideWithValue(playlistRepository),
        audioPlayerNotifierProvider.overrideWith((ref) {
          return MockAudioPlayerNotifier();
        }),
        feedProvider.overrideWith((ref) {
          return MockFeedNotifier(
            feedState,
            onRefreshCalled: onRefresh,
            onLoadMoreCalled: onLoadMore,
            onHideSongCalled: onHideSong,
            onSelectTabCalled: onSelectTab,
            onSubmitReportCalled: onSubmitReport,
          );
        }),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: const FeedScreen()),
      ),
    );
  }

  group('FeedScreen Widget Tests - UI States', () {
    testWidgets(
      'Shows Loading view initially when state is loading and empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            feedState: const FeedState(
              isInitialLoading: true,
              discoverSongs: [],
            ),
          ),
        );

        // Verify that _FeedLoadingView is displayed
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_FeedLoadingView',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Shows Error view when loading fails', (tester) async {
      bool isRefreshed = false;

      await tester.pumpWidget(
        buildTestApp(
          feedState: const FeedState(
            isInitialLoading: false,
            initialErrorMessage: 'Lỗi kết nối máy chủ',
            discoverSongs: [],
          ),
          onRefresh: () {
            isRefreshed = true;
          },
        ),
      );

      await tester.pumpAndSettle();

      // Verify error screen texts
      expect(find.text('Không thể tải feed'), findsOneWidget);
      expect(find.text('Lỗi kết nối máy chủ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(isRefreshed, isTrue);
    });

    testWidgets('Shows Empty view when no songs are returned', (tester) async {
      bool isRefreshed = false;

      await tester.pumpWidget(
        buildTestApp(
          feedState: const FeedState(
            isInitialLoading: false,
            discoverSongs: [],
          ),
          onRefresh: () {
            isRefreshed = true;
          },
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty screen texts
      expect(find.text('Feed đang trống'), findsOneWidget);
      expect(find.text('Làm mới'), findsOneWidget);

      // Tap refresh button
      await tester.tap(find.text('Làm mới'));
      await tester.pumpAndSettle();

      expect(isRefreshed, isTrue);
    });

    testWidgets('Renders PageView with songs correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          feedState: FeedState(
            isInitialLoading: false,
            discoverSongs: [testSong1, testSong2],
            hasMore: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify song metadata is displayed
      expect(find.text('Song Title One'), findsOneWidget);
      expect(find.text('Artist One'), findsOneWidget);
    });
  });

  group('FeedScreen Widget Tests - Interactions', () {
    testWidgets('Like action - Tapping favorite button calls toggle favorite', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          feedState: FeedState(
            isInitialLoading: false,
            discoverSongs: [testSong1],
            hasMore: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify like button icon (initially false, so it shows Icons.favorite_border)
      final likeButton = find.byIcon(Icons.favorite_border);
      expect(likeButton, findsOneWidget);

      // Tap like button
      await tester.tap(likeButton);
      await tester.pumpAndSettle();

      // Verify interaction repository registers like
      expect(interactionRepository.toggledFavorites, isNotEmpty);
      expect(interactionRepository.toggledFavorites.first.$1.id, 'song-1');
      expect(interactionRepository.toggledFavorites.first.$2, isTrue);
    });

    testWidgets('Like action - Double tapping artwork calls toggle favorite', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          feedState: FeedState(
            isInitialLoading: false,
            discoverSongs: [testSong1],
            hasMore: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the artwork gesture layer
      final gestureLayer = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_FeedArtworkGestureLayer',
      );
      expect(gestureLayer, findsOneWidget);

      // Double tap on artwork
      await tester.tap(gestureLayer);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(gestureLayer);
      await tester.pumpAndSettle();
      // Pump to clear the transient heart animation timer
      await tester.pump(const Duration(seconds: 1));

      // Verify interaction repository registers like
      expect(interactionRepository.toggledFavorites, isNotEmpty);
      expect(interactionRepository.toggledFavorites.first.$1.id, 'song-1');
      expect(interactionRepository.toggledFavorites.first.$2, isTrue);
    });

    testWidgets('Tab switching - Tapping following tab calls selectTab', (
      tester,
    ) async {
      FeedTabType? selectedTab;

      await tester.pumpWidget(
        buildTestApp(
          feedState: FeedState(
            isInitialLoading: false,
            discoverSongs: [testSong1],
            hasMore: false,
          ),
          onSelectTab: (tab) {
            selectedTab = tab;
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find Following tab by text "Đang theo dõi"
      final followingTab = find.text('Đang theo dõi');
      expect(followingTab, findsOneWidget);

      // Tap following tab
      await tester.tap(followingTab);
      await tester.pumpAndSettle();

      expect(selectedTab, FeedTabType.following);
    });

    testWidgets('Hide action - Tapping Hide calls hideSong on notifier', (
      tester,
    ) async {
      SongEntity? hiddenSong;

      await tester.pumpWidget(
        buildTestApp(
          feedState: FeedState(
            isInitialLoading: false,
            discoverSongs: [testSong1],
            hasMore: false,
          ),
          onHideSong: (song) {
            hiddenSong = song;
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap more (3 dots) button
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      // Tap "Ẩn" button
      await tester.tap(find.text('Ẩn'));
      await tester.pumpAndSettle();

      expect(hiddenSong?.id, 'song-1');
    });

    testWidgets(
      'Report action - Submitting report dialog calls submitReport on notifier',
      (tester) async {
        SongEntity? reportedSong;
        String? reportReason;

        await tester.pumpWidget(
          buildTestApp(
            feedState: FeedState(
              isInitialLoading: false,
              discoverSongs: [testSong1],
              hasMore: false,
            ),
            onSubmitReport: (song, reason) {
              reportedSong = song;
              reportReason = reason;
            },
          ),
        );

        await tester.pumpAndSettle();

        // Tap more (3 dots) button
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();

        // Tap "Báo cáo" option
        await tester.tap(find.text('Báo cáo'));
        await tester.pumpAndSettle();

        // Check that Report Dialog is shown
        expect(find.text('Báo cáo bài hát'), findsOneWidget);

        // Enter details in text field
        await tester.enterText(find.byType(TextField), 'Nội dung phản cảm');
        await tester.pumpAndSettle();

        // Tap "Gửi" button
        await tester.tap(find.text('Gửi'));
        await tester.pumpAndSettle();

        expect(reportedSong?.id, 'song-1');
        expect(reportReason, 'Nội dung phản cảm');
      },
    );

    testWidgets(
      'Add Playlist action - Creating and adding a song to a new playlist works',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            feedState: FeedState(
              isInitialLoading: false,
              discoverSongs: [testSong1],
              hasMore: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the playlist (add box) button directly
        final playlistBtn = find.byIcon(Icons.add_box_outlined);
        expect(playlistBtn, findsOneWidget);

        await tester.tap(playlistBtn);
        await tester.pumpAndSettle();

        // Check that Add To Playlist sheet is open
        expect(find.text('Danh sách phát'), findsOneWidget);
        expect(find.text('Song Title One'), findsNWidgets(2));

        // Enter new playlist name
        await tester.enterText(find.byType(TextField), 'Playlist của tôi');
        await tester.pumpAndSettle();

        // Tap the '+' (Create new playlist) button
        final createBtn = find.byTooltip('Tạo playlist mới');
        expect(createBtn, findsOneWidget);

        await tester.tap(createBtn);
        await tester.pumpAndSettle();

        // Verify playlist repository has the new playlist with the song inside
        expect(playlistRepository.playlists, isNotEmpty);
        expect(playlistRepository.playlists.first.name, 'Playlist của tôi');
        expect(playlistRepository.playlists.first.songIds, contains('song-1'));
      },
    );
  });
}

// Mock Audio Player Notifier
class MockAudioPlayerNotifier extends AudioPlayerNotifier {
  MockAudioPlayerNotifier()
    : super(
        trackSongListenUseCase: TrackSongListenUseCase(FakeSongRepository()),
        recordRecentSong: (song) async {},
        syncRecentPlayback:
            ({
              required song,
              required position,
              required duration,
              required markCompleted,
            }) async {},
      );

  @override
  Future<void> playSong(
    SongEntity song, {
    List<SongEntity>? playlist,
    Duration initialPosition = Duration.zero,
    bool loopSingle = false,
  }) async {
    state = state.copyWith(
      currentSong: song,
      playlist: playlist ?? [song],
      isPlaying: true,
      isLoading: false,
      isError: false,
      position: Duration.zero,
      duration: const Duration(seconds: 120),
    );
  }

  @override
  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  @override
  void resume() {
    state = state.copyWith(isPlaying: true);
  }

  @override
  void seek(Duration position) {
    state = state.copyWith(position: position);
  }

  @override
  Future<void> next() async {
    if (state.playlist.isEmpty) return;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.playlist.length) {
      await playSong(state.playlist[nextIndex], playlist: state.playlist);
    }
  }

  @override
  Future<void> previous() async {
    if (state.playlist.isEmpty) return;
    final prevIndex = state.currentIndex - 1;
    if (prevIndex >= 0) {
      await playSong(state.playlist[prevIndex], playlist: state.playlist);
    }
  }

  @override
  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < state.playlist.length) {
      await playSong(state.playlist[index], playlist: state.playlist);
    }
  }
}

// Mock Feed Notifier
class MockFeedNotifier extends FeedNotifier {
  MockFeedNotifier(
    FeedState stateVal, {
    this.onRefreshCalled,
    this.onLoadMoreCalled,
    this.onHideSongCalled,
    this.onSelectTabCalled,
    this.onSubmitReportCalled,
  }) : super(
         getFeedSongsPageUseCase: GetFeedSongsPageUseCase(FakeSongRepository()),
         interactionRepository: FakeInteractionRepository(),
         getProfileUseCase: GetProfileUseCase(FakeProfileRepository()),
         userId: 'user-1',
         userName: 'Tester',
         autoLoad: false,
       ) {
    state = stateVal;
  }

  final VoidCallback? onRefreshCalled;
  final VoidCallback? onLoadMoreCalled;
  final ValueChanged<SongEntity>? onHideSongCalled;
  final ValueChanged<FeedTabType>? onSelectTabCalled;
  final Function(SongEntity, String)? onSubmitReportCalled;

  @override
  Future<void> refresh() async {
    onRefreshCalled?.call();
  }

  @override
  Future<void> loadMore() async {
    onLoadMoreCalled?.call();
  }

  @override
  Future<void> hideSong(SongEntity song) async {
    onHideSongCalled?.call(song);
  }

  @override
  void selectTab(FeedTabType tab) {
    onSelectTabCalled?.call(tab);
    state = state.copyWith(selectedTab: tab);
  }

  @override
  Future<bool> submitReport({
    required SongEntity song,
    required String reason,
  }) async {
    onSubmitReportCalled?.call(song, reason);
    return true;
  }
}

// Fake Repositories
class FakeSongRepository implements SongRepository {
  @override
  Future<SongPageEntity> fetchFeedSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) async {
    return const SongPageEntity(songs: [], nextCursor: null, hasMore: false);
  }

  @override
  Future<SongPageEntity> fetchSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) async {
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
  final List<(SongEntity, bool)> toggledFavorites = [];

  @override
  Future<List<SongEntity>> getFavorites(String userId) async => [];

  @override
  Future<void> toggleFavorite(
    String userId,
    SongEntity song,
    bool isFavorite,
  ) async {
    toggledFavorites.add((song, isFavorite));
  }

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
  Future<void> hideFeedSong(String userId, SongEntity song) async {}

  @override
  Future<void> reportSong({
    required String userId,
    required SongEntity song,
    required String reason,
  }) async {}

  @override
  Stream<List<FeedCommentEntity>> watchSongComments(String songId) =>
      const Stream.empty();

  @override
  Future<void> addSongComment({
    required String userId,
    required String userName,
    required String songId,
    required String text,
  }) async {}

  @override
  Future<void> deleteSongComment({
    required String songId,
    required String commentId,
  }) async {}
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<ProfileEntity> getProfile() async {
    return const ProfileEntity(
      id: 'user-1',
      username: 'Tester',
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

class FakePlaylistRepository implements PlaylistRepository {
  FakePlaylistRepository({required List<PlaylistEntity> playlists})
    : playlists = [...playlists];

  List<PlaylistEntity> playlists;

  @override
  Future<List<PlaylistEntity>> getUserPlaylists(String userId) async {
    return playlists;
  }

  @override
  Future<PlaylistEntity> createPlaylist({
    required String userId,
    required String name,
  }) async {
    final playlist = PlaylistEntity(
      id: 'playlist-${playlists.length + 1}',
      name: name,
      description: '',
      coverUrl: '',
      songIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    playlists.add(playlist);
    return playlist;
  }

  @override
  Future<void> updatePlaylistDetails({
    required String userId,
    required String playlistId,
    required String name,
    required String description,
    required String coverUrl,
  }) async {
    playlists = [
      for (final p in playlists)
        if (p.id == playlistId)
          p.copyWith(
            name: name,
            description: description,
            coverUrl: coverUrl,
            updatedAt: DateTime.now(),
          )
        else
          p,
    ];
  }

  @override
  Future<void> updatePlaylistSongs({
    required String userId,
    required String playlistId,
    required List<String> songIds,
  }) async {
    playlists = [
      for (final p in playlists)
        if (p.id == playlistId)
          p.copyWith(songIds: songIds, updatedAt: DateTime.now())
        else
          p,
    ];
  }

  @override
  Future<void> deletePlaylist({
    required String userId,
    required String playlistId,
  }) async {
    playlists.removeWhere((p) => p.id == playlistId);
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  UserEntity? currentUser;

  @override
  Future<UserEntity?> getCurrentUser() async => currentUser;

  @override
  Stream<UserEntity?> watchCurrentUser() => Stream.value(currentUser);

  @override
  Future<UserEntity> login(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> signUp(
    String fullName,
    String email,
    String password,
    String ageGroup,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> resendEmailVerification(String email, String password) async {}

  @override
  Future<void> sendCurrentUserEmailVerification() async {}

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<void> signOut() async {
    currentUser = null;
  }
}

UserEntity _user() {
  return const UserEntity(
    id: 'user-1',
    email: 'tester@example.com',
    fullName: 'Tester',
    token: 'token',
    role: UserRoles.user,
    isEmailVerified: true,
  );
}

SongEntity _song(String id, String title, String artist) {
  return SongEntity(
    id: id,
    title: title,
    artist: artist,
    audioUrl: 'audio-$id',
    imageUrl: 'image-$id',
  );
}

// A 1x1 transparent PNG image bytes.
final List<int> _transparentImage = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _MockHttpClientHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
