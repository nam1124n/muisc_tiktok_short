import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/feed_comment_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/domain/usecases/get_feed_songs_page_usecase.dart';
import 'package:login_flutter/domain/usecases/get_profile_usecase.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(
    getFeedSongsPageUseCase: ref.read(getFeedSongsPageUseCaseProvider),
    interactionRepository: ref.read(interactionRepositoryProvider),
    getProfileUseCase: ref.read(getProfileUseCaseProvider),
    userId: ref.watch(sessionCurrentUserIdProvider) ?? 'guest',
    userName: ref.watch(sessionProvider).currentUser?.fullName ?? '',
  );
});

final feedCommentsProvider = StreamProvider.autoDispose
    .family<List<FeedCommentEntity>, String>((ref, songId) {
      return ref.read(interactionRepositoryProvider).watchSongComments(songId);
    });

final feedCommentCountProvider = Provider.autoDispose.family<int?, String>((
  ref,
  songId,
) {
  return ref.watch(feedCommentsProvider(songId)).valueOrNull?.length;
});

enum FeedTabType { discover, following }

const _feedStateNoChange = Object();

class FeedState extends Equatable {
  const FeedState({
    this.selectedTab = FeedTabType.discover,
    this.discoverSongs = const [],
    this.followingSongs = const [],
    this.hiddenSongIds = const {},
    this.favoriteCountDeltas = const {},
    this.commentCountDeltas = const {},
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isReporting = false,
    this.commentingSongIds = const {},
    this.hasMore = true,
    this.initialErrorMessage,
    this.loadMoreErrorMessage,
    this.actionErrorMessage,
  });

  const FeedState.initial()
    : selectedTab = FeedTabType.discover,
      discoverSongs = const [],
      followingSongs = const [],
      hiddenSongIds = const {},
      favoriteCountDeltas = const {},
      commentCountDeltas = const {},
      isInitialLoading = true,
      isRefreshing = false,
      isLoadingMore = false,
      isReporting = false,
      commentingSongIds = const {},
      hasMore = true,
      initialErrorMessage = null,
      loadMoreErrorMessage = null,
      actionErrorMessage = null;

  final FeedTabType selectedTab;
  final List<SongEntity> discoverSongs;
  final List<SongEntity> followingSongs;
  final Set<String> hiddenSongIds;
  final Map<String, int> favoriteCountDeltas;
  final Map<String, int> commentCountDeltas;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isReporting;
  final Set<String> commentingSongIds;
  final bool hasMore;
  final String? initialErrorMessage;
  final String? loadMoreErrorMessage;
  final String? actionErrorMessage;

  List<SongEntity> get songs {
    final source = switch (selectedTab) {
      FeedTabType.discover => discoverSongs,
      FeedTabType.following => followingSongs,
    };

    if (hiddenSongIds.isEmpty) {
      return source;
    }

    return [
      for (final song in source)
        if (!hiddenSongIds.contains(song.id)) song,
    ];
  }

  bool get hasInitialError =>
      initialErrorMessage != null &&
      initialErrorMessage!.trim().isNotEmpty &&
      songs.isEmpty;

  bool get hasLoadMoreError =>
      loadMoreErrorMessage != null &&
      loadMoreErrorMessage!.trim().isNotEmpty &&
      songs.isNotEmpty;

  bool get isEmpty => songs.isEmpty && !isInitialLoading && !hasInitialError;

  int favoriteCountFor(SongEntity song) {
    return _countWithDelta(song.favoriteCount, favoriteCountDeltas[song.id]);
  }

  int commentCountFor(SongEntity song) {
    return _countWithDelta(song.commentCount, commentCountDeltas[song.id]);
  }

  FeedState copyWith({
    FeedTabType? selectedTab,
    List<SongEntity>? discoverSongs,
    List<SongEntity>? followingSongs,
    Set<String>? hiddenSongIds,
    Map<String, int>? favoriteCountDeltas,
    Map<String, int>? commentCountDeltas,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isReporting,
    Set<String>? commentingSongIds,
    bool? hasMore,
    Object? initialErrorMessage = _feedStateNoChange,
    Object? loadMoreErrorMessage = _feedStateNoChange,
    Object? actionErrorMessage = _feedStateNoChange,
  }) {
    return FeedState(
      selectedTab: selectedTab ?? this.selectedTab,
      discoverSongs: discoverSongs ?? this.discoverSongs,
      followingSongs: followingSongs ?? this.followingSongs,
      hiddenSongIds: hiddenSongIds ?? this.hiddenSongIds,
      favoriteCountDeltas: favoriteCountDeltas ?? this.favoriteCountDeltas,
      commentCountDeltas: commentCountDeltas ?? this.commentCountDeltas,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isReporting: isReporting ?? this.isReporting,
      commentingSongIds: commentingSongIds ?? this.commentingSongIds,
      hasMore: hasMore ?? this.hasMore,
      initialErrorMessage: initialErrorMessage == _feedStateNoChange
          ? this.initialErrorMessage
          : initialErrorMessage as String?,
      loadMoreErrorMessage: loadMoreErrorMessage == _feedStateNoChange
          ? this.loadMoreErrorMessage
          : loadMoreErrorMessage as String?,
      actionErrorMessage: actionErrorMessage == _feedStateNoChange
          ? this.actionErrorMessage
          : actionErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    selectedTab,
    discoverSongs,
    followingSongs,
    hiddenSongIds,
    favoriteCountDeltas,
    commentCountDeltas,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    isReporting,
    commentingSongIds,
    hasMore,
    initialErrorMessage,
    loadMoreErrorMessage,
    actionErrorMessage,
  ];

  int _countWithDelta(int value, int? delta) {
    final nextValue = value + (delta ?? 0);
    return nextValue < 0 ? 0 : nextValue;
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier({
    required this.getFeedSongsPageUseCase,
    required this.interactionRepository,
    required this.getProfileUseCase,
    required this.userId,
    required this.userName,
    bool autoLoad = true,
  }) : super(const FeedState.initial()) {
    loadHiddenSongs();
    if (autoLoad) {
      loadInitial();
    }
  }

  static const int _pageSize = 12;

  final GetFeedSongsPageUseCase getFeedSongsPageUseCase;
  final InteractionRepository interactionRepository;
  final GetProfileUseCase getProfileUseCase;
  final String userId;
  final String userName;
  SongPageCursor? _nextCursor;
  bool _discoverHasMore = true;

  bool get _isGuest => userId == 'guest' || userId == 'guest_user';

  Future<void> loadHiddenSongs() async {
    if (_isGuest) {
      return;
    }

    try {
      final hiddenSongIds = await interactionRepository.getHiddenFeedSongIds(
        userId,
      );
      if (!mounted) return;

      state = state.copyWith(hiddenSongIds: hiddenSongIds);
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(actionErrorMessage: ErrorMessageMapper.map(error));
    }
  }

  void selectTab(FeedTabType tab) {
    if (tab == state.selectedTab) {
      return;
    }

    if (tab == FeedTabType.following) {
      state = state.copyWith(
        selectedTab: tab,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: false,
        initialErrorMessage: null,
        loadMoreErrorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      selectedTab: tab,
      hasMore: _discoverHasMore,
      initialErrorMessage: null,
      loadMoreErrorMessage: null,
    );

    if (state.discoverSongs.isEmpty) {
      loadInitial();
    }
  }

  Future<void> refresh() => loadInitial(keepSongs: true);

  Future<void> loadInitial({bool keepSongs = false}) async {
    if (state.selectedTab == FeedTabType.following) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: false,
        initialErrorMessage: null,
        loadMoreErrorMessage: null,
      );
      return;
    }

    _nextCursor = null;
    _discoverHasMore = true;
    state = state.copyWith(
      discoverSongs: keepSongs ? state.discoverSongs : const [],
      isInitialLoading: !keepSongs,
      isRefreshing: keepSongs,
      isLoadingMore: false,
      hasMore: true,
      initialErrorMessage: null,
      loadMoreErrorMessage: null,
    );

    try {
      final page = await getFeedSongsPageUseCase(limit: _pageSize);
      if (!mounted) return;

      _nextCursor = page.nextCursor;
      _discoverHasMore = page.hasMore;
      state = state.copyWith(
        discoverSongs: page.songs,
        favoriteCountDeltas: const {},
        commentCountDeltas: const {},
        isInitialLoading: false,
        isRefreshing: false,
        hasMore: page.hasMore,
        initialErrorMessage: null,
        loadMoreErrorMessage: null,
      );
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: state.songs.isNotEmpty,
        initialErrorMessage: state.songs.isEmpty
            ? ErrorMessageMapper.map(error)
            : null,
        loadMoreErrorMessage: state.songs.isNotEmpty
            ? ErrorMessageMapper.map(error)
            : null,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.selectedTab == FeedTabType.following ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, loadMoreErrorMessage: null);

    try {
      final page = await getFeedSongsPageUseCase(
        limit: _pageSize,
        startAfter: _nextCursor,
      );
      if (!mounted) return;

      _nextCursor = page.nextCursor ?? _nextCursor;
      _discoverHasMore = page.hasMore;
      state = state.copyWith(
        discoverSongs: _mergeSongs(state.discoverSongs, page.songs),
        isLoadingMore: false,
        hasMore: page.hasMore,
        loadMoreErrorMessage: null,
      );
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: ErrorMessageMapper.map(error),
      );
    }
  }

  Future<void> retryLoadMore() => loadMore();

  Future<void> hideSong(SongEntity song) async {
    final songId = song.id;
    if (state.hiddenSongIds.contains(songId)) {
      return;
    }

    state = state.copyWith(hiddenSongIds: {...state.hiddenSongIds, songId});

    if (_isGuest) {
      return;
    }

    try {
      await interactionRepository.hideFeedSong(userId, song);
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        hiddenSongIds: {...state.hiddenSongIds}..remove(songId),
        actionErrorMessage: ErrorMessageMapper.map(error),
      );
    }
  }

  Future<bool> submitReport({
    required SongEntity song,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (_isGuest || trimmedReason.isEmpty || state.isReporting) {
      return false;
    }

    state = state.copyWith(isReporting: true, actionErrorMessage: null);

    try {
      await interactionRepository.reportSong(
        userId: userId,
        song: song,
        reason: trimmedReason,
      );
      if (!mounted) return true;

      state = state.copyWith(isReporting: false, actionErrorMessage: null);
      return true;
    } catch (error) {
      if (!mounted) return false;

      state = state.copyWith(
        isReporting: false,
        actionErrorMessage: ErrorMessageMapper.map(error),
      );
      return false;
    }
  }

  Future<bool> addComment({
    required SongEntity song,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (_isGuest ||
        trimmedText.isEmpty ||
        state.commentingSongIds.contains(song.id)) {
      return false;
    }

    state = state.copyWith(
      commentingSongIds: {...state.commentingSongIds, song.id},
      actionErrorMessage: null,
    );

    try {
      await interactionRepository.addSongComment(
        userId: userId,
        userName: await _commentUserName(),
        songId: song.id,
        text: trimmedText,
      );
      if (!mounted) return true;

      state = state.copyWith(
        commentingSongIds: {...state.commentingSongIds}..remove(song.id),
        commentCountDeltas: _countDeltasWith(song.id, 1, isComment: true),
        actionErrorMessage: null,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;

      state = state.copyWith(
        commentingSongIds: {...state.commentingSongIds}..remove(song.id),
        actionErrorMessage: ErrorMessageMapper.map(error),
      );
      return false;
    }
  }

  Future<String> _commentUserName() async {
    try {
      final profile = await getProfileUseCase();
      final profileName = profile.username.trim();
      if (profileName.isNotEmpty) {
        return profileName;
      }
    } catch (_) {
      // Session data is enough as a fallback when profile is unavailable.
    }

    final sessionName = userName.trim();
    return sessionName.isEmpty ? 'Listener' : sessionName;
  }

  Future<bool> deleteComment(FeedCommentEntity comment) async {
    if (_isGuest || comment.userId != userId) {
      return false;
    }

    try {
      await interactionRepository.deleteSongComment(
        songId: comment.songId,
        commentId: comment.id,
      );
      if (!mounted) return true;

      state = state.copyWith(
        commentCountDeltas: _countDeltasWith(
          comment.songId,
          -1,
          isComment: true,
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;

      state = state.copyWith(actionErrorMessage: ErrorMessageMapper.map(error));
      return false;
    }
  }

  void applyFavoriteDelta(String songId, int delta) {
    state = state.copyWith(
      favoriteCountDeltas: _countDeltasWith(songId, delta),
    );
  }

  Map<String, int> _countDeltasWith(
    String songId,
    int delta, {
    bool isComment = false,
  }) {
    final current = isComment
        ? state.commentCountDeltas
        : state.favoriteCountDeltas;
    final nextValue = (current[songId] ?? 0) + delta;
    final next = {...current};
    if (nextValue == 0) {
      next.remove(songId);
    } else {
      next[songId] = nextValue;
    }
    return next;
  }

  List<SongEntity> _mergeSongs(
    List<SongEntity> current,
    List<SongEntity> incoming,
  ) {
    final songsById = <String, SongEntity>{
      for (final song in current) song.id: song,
    };

    for (final song in incoming) {
      songsById[song.id] = song;
    }

    return songsById.values.toList();
  }
}
