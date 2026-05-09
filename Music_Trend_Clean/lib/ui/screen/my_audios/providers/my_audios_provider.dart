import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/config/audio_generation_config.dart';
import 'package:login_flutter/app/providers/app_language_provider.dart';
import 'package:login_flutter/app/providers/audio_generation_provider.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/data/datasource/remote/generated_audio_library_remote_data_source.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/domain/usecases/get_my_songs_usecase.dart';
import 'package:login_flutter/ui/screen/my_audios/providers/my_audios_sync_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

final myAudiosProvider =
    StateNotifierProvider<_MyAudiosNotifier, MyAudiosState>((ref) {
      final userId = ref.watch(sessionProvider.select((state) => state.userId));

      return _MyAudiosNotifier(
        userId: userId,
        cacheStore: _MyAudiosCacheStore(ref.read(sharedPreferencesProvider)),
        getMySongsUseCase: ref.read(getMySongsUseCaseProvider),
        libraryRemoteDataSource: ref.read(
          generatedAudioLibraryRemoteDataSourceProvider,
        ),
        syncHelper: const MyAudiosSyncHelper(),
      );
    });

const _stateNoChange = Object();

class MyAudiosState extends Equatable {
  const MyAudiosState({
    this.tasks = const [],
    this.isHydratingCache = false,
    this.isSyncingRemote = false,
    this.isPollingPending = false,
    this.errorMessage,
    this.lastSyncedAt,
  });

  final List<GeneratedAudioTaskEntity> tasks;
  final bool isHydratingCache;
  final bool isSyncingRemote;
  final bool isPollingPending;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  bool get isLoadingInitial => isHydratingCache && tasks.isEmpty;

  bool get isEmpty => tasks.isEmpty && !isHydratingCache && !isSyncingRemote;

  bool get hasError =>
      errorMessage != null && errorMessage!.trim().isNotEmpty && tasks.isEmpty;

  MyAudiosState copyWith({
    List<GeneratedAudioTaskEntity>? tasks,
    bool? isHydratingCache,
    bool? isSyncingRemote,
    bool? isPollingPending,
    Object? errorMessage = _stateNoChange,
    Object? lastSyncedAt = _stateNoChange,
  }) {
    return MyAudiosState(
      tasks: tasks ?? this.tasks,
      isHydratingCache: isHydratingCache ?? this.isHydratingCache,
      isSyncingRemote: isSyncingRemote ?? this.isSyncingRemote,
      isPollingPending: isPollingPending ?? this.isPollingPending,
      errorMessage: errorMessage == _stateNoChange
          ? this.errorMessage
          : errorMessage as String?,
      lastSyncedAt: lastSyncedAt == _stateNoChange
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    isHydratingCache,
    isSyncingRemote,
    isPollingPending,
    errorMessage,
    lastSyncedAt,
  ];
}

class _MyAudiosNotifier extends StateNotifier<MyAudiosState> {
  static const int _maxPendingRefreshAttempt = 3;

  _MyAudiosNotifier({
    required this.userId,
    required this.cacheStore,
    required this.getMySongsUseCase,
    required this.libraryRemoteDataSource,
    required this.syncHelper,
  }) : super(const MyAudiosState(isHydratingCache: true)) {
    _loadTasks();
  }

  final String userId;
  final _MyAudiosCacheStore cacheStore;
  final GetMySongsUseCase getMySongsUseCase;
  final GeneratedAudioLibraryRemoteDataSource libraryRemoteDataSource;
  final MyAudiosSyncHelper syncHelper;
  StreamSubscription<List<GeneratedAudioTaskEntity>>? _librarySubscription;
  Timer? _pendingRefreshTimer;
  bool _isRefreshingPending = false;
  int _pendingRefreshAttempt = 0;

  String get _key => 'my_generated_tasks_$userId';

  Future<void> reload() async {
    await _loadTasks(forceLibraryResubscribe: true);
  }

  Future<void> _loadTasks({bool forceLibraryResubscribe = false}) async {
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = null;
    _pendingRefreshAttempt = 0;
    state = state.copyWith(
      isHydratingCache: true,
      isSyncingRemote: false,
      errorMessage: null,
    );

    final cachedTasks = await cacheStore.readTasks(_key);
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      tasks: cachedTasks,
      isHydratingCache: false,
      errorMessage: null,
    );

    if (userId != 'guest_user' &&
        (forceLibraryResubscribe || _librarySubscription == null)) {
      _listenToLibraryUpdates();
    }

    await _syncRemoteSources();
  }

  Future<void> _syncRemoteSources() async {
    state = state.copyWith(isSyncingRemote: true, errorMessage: null);

    String? syncError;

    if (userId != 'guest_user') {
      try {
        final remoteTasks = await libraryRemoteDataSource.getTasks(userId);
        await _mergeAndPersist(remoteTasks, markSynced: false);
      } catch (error) {
        syncError = ErrorMessageMapper.map(error);
      }
    }

    try {
      final backendTasks = await getMySongsUseCase(userId: userId);
      if (!mounted) {
        return;
      }

      if (backendTasks.isNotEmpty) {
        final previousTasks = state.tasks;
        await _mergeAndPersist(backendTasks);

        if (userId != 'guest_user') {
          for (final task in backendTasks) {
            await _saveTaskToLibraryIfChanged(task, previousTasks);
          }
        }
      }
    } catch (error) {
      syncError ??= ErrorMessageMapper.map(error);
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isSyncingRemote: false,
      errorMessage: syncError,
      lastSyncedAt: syncError == null ? DateTime.now() : state.lastSyncedAt,
    );
    _syncPendingRefresh();
  }

  Future<void> _mergeAndPersist(
    List<GeneratedAudioTaskEntity> incoming, {
    bool markSynced = true,
  }) async {
    final previousTasks = state.tasks;
    final mergedTasks = syncHelper.mergeTasks(previousTasks, incoming);
    if (syncHelper.hasTaskListChanged(previousTasks, mergedTasks)) {
      _pendingRefreshAttempt = 0;
    }
    state = state.copyWith(
      tasks: mergedTasks,
      errorMessage: null,
      lastSyncedAt: markSynced ? DateTime.now() : state.lastSyncedAt,
    );
    await cacheStore.writeTasks(_key, mergedTasks);
    if (!mounted) {
      return;
    }
    _syncPendingRefresh();
  }

  void _listenToLibraryUpdates() {
    _librarySubscription?.cancel();
    _librarySubscription = libraryRemoteDataSource.watchTasks(userId).listen((
      tasks,
    ) async {
      if (!mounted) {
        return;
      }

      await _mergeAndPersist(tasks);
    }, onError: (_) {});
  }

  void _syncPendingRefresh() {
    final shouldPoll = syncHelper.shouldPollPending(state.tasks);
    if (state.isPollingPending != shouldPoll) {
      state = state.copyWith(isPollingPending: shouldPoll);
    }

    if (!shouldPoll) {
      _pendingRefreshAttempt = 0;
      _pendingRefreshTimer?.cancel();
      _pendingRefreshTimer = null;
      return;
    }

    if (_isRefreshingPending) {
      return;
    }

    _scheduleNextPendingRefresh();
  }

  Future<void> _refreshPendingTasks() async {
    if (_isRefreshingPending || !syncHelper.shouldPollPending(state.tasks)) {
      return;
    }

    _isRefreshingPending = true;
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = null;
    var hadProgress = false;
    try {
      final backendTasks = await getMySongsUseCase(userId: userId);
      if (!mounted) {
        return;
      }

      if (backendTasks.isNotEmpty) {
        final previousTasks = state.tasks;
        await _mergeAndPersist(backendTasks);
        hadProgress = syncHelper.hasTaskListChanged(previousTasks, state.tasks);

        if (userId != 'guest_user') {
          for (final task in backendTasks) {
            await _saveTaskToLibraryIfChanged(task, previousTasks);
          }
        }
      }
    } catch (_) {
      hadProgress = false;
    } finally {
      if (mounted) {
        _pendingRefreshAttempt = syncHelper.nextPollingAttempt(
          previousAttempt: _pendingRefreshAttempt,
          hadProgress: hadProgress,
          maxAttempt: _maxPendingRefreshAttempt,
        );
        _isRefreshingPending = false;
        _syncPendingRefresh();
      }
    }
  }

  void _scheduleNextPendingRefresh() {
    final delay = syncHelper.pollingDelayForAttempt(
      attempt: _pendingRefreshAttempt,
      baseSeconds: AudioGenerationConfig.pendingRefreshIntervalSeconds,
      maxSeconds: AudioGenerationConfig.pendingRefreshMaxIntervalSeconds,
    );
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = Timer(delay, _refreshPendingTasks);
  }

  Future<void> _saveTaskToLibraryIfChanged(
    GeneratedAudioTaskEntity task,
    List<GeneratedAudioTaskEntity> sourceTasks,
  ) async {
    GeneratedAudioTaskEntity? existingTask;
    for (final item in sourceTasks) {
      if (item.id == task.id) {
        existingTask = item;
        break;
      }
    }

    if (!syncHelper.hasTaskChanged(existingTask, task)) {
      return;
    }

    await libraryRemoteDataSource.saveTask(userId, task);
  }

  Future<void> saveTask(GeneratedAudioTaskEntity task) async {
    await _mergeAndPersist([task]);

    if (userId == 'guest_user') {
      return;
    }

    await libraryRemoteDataSource.saveTask(userId, task);
  }

  Future<void> removeTask(String taskId) async {
    final nextTasks = state.tasks.where((task) => task.id != taskId).toList();
    state = state.copyWith(tasks: nextTasks, errorMessage: null);
    await cacheStore.writeTasks(_key, nextTasks);
    if (!mounted) {
      return;
    }
    _syncPendingRefresh();

    if (userId == 'guest_user') {
      return;
    }

    await libraryRemoteDataSource.deleteTask(userId, taskId);
  }

  @override
  void dispose() {
    _librarySubscription?.cancel();
    _pendingRefreshTimer?.cancel();
    super.dispose();
  }
}

class _MyAudiosCacheStore {
  const _MyAudiosCacheStore(this.sharedPreferences);

  final SharedPreferences sharedPreferences;

  Future<List<GeneratedAudioTaskEntity>> readTasks(String key) async {
    final jsonList = sharedPreferences.getStringList(key);
    if (jsonList == null || jsonList.isEmpty) {
      return const [];
    }

    try {
      return jsonList
          .map((value) => GeneratedAudioTaskEntity.fromJson(jsonDecode(value)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeTasks(
    String key,
    List<GeneratedAudioTaskEntity> tasks,
  ) async {
    final jsonList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await sharedPreferences.setStringList(key, jsonList);
  }
}
