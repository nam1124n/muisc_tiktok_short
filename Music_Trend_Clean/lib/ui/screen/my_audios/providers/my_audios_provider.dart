import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/app/providers/app_language_provider.dart';
import 'package:login_flutter/app/providers/audio_generation_provider.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/data/datasource/remote/audio_generation_remote_data_source.dart';
import 'package:login_flutter/data/datasource/remote/generated_audio_library_remote_data_source.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/ui/screen/my_audios/providers/my_audios_sync_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

final myAudiosProvider =
    StateNotifierProvider<_MyAudiosNotifier, MyAudiosState>((ref) {
      final userId = ref.watch(sessionProvider.select((state) => state.userId));

      return _MyAudiosNotifier(
        userId: userId,
        cacheStore: _MyAudiosCacheStore(ref.read(sharedPreferencesProvider)),
        libraryRemoteDataSource: ref.read(
          generatedAudioLibraryRemoteDataSourceProvider,
        ),
        generationRemoteDataSource: ref.read(
          audioGenerationRemoteDataSourceProvider,
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
    this.errorMessage,
    this.lastSyncedAt,
  });

  final List<GeneratedAudioTaskEntity> tasks;
  final bool isHydratingCache;
  final bool isSyncingRemote;
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
    Object? errorMessage = _stateNoChange,
    Object? lastSyncedAt = _stateNoChange,
  }) {
    return MyAudiosState(
      tasks: tasks ?? this.tasks,
      isHydratingCache: isHydratingCache ?? this.isHydratingCache,
      isSyncingRemote: isSyncingRemote ?? this.isSyncingRemote,
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
    errorMessage,
    lastSyncedAt,
  ];
}

class _MyAudiosNotifier extends StateNotifier<MyAudiosState> {
  _MyAudiosNotifier({
    required this.userId,
    required this.cacheStore,
    required this.libraryRemoteDataSource,
    required this.generationRemoteDataSource,
    required this.syncHelper,
  }) : super(const MyAudiosState(isHydratingCache: true)) {
    _loadTasks();
  }

  final String userId;
  final _MyAudiosCacheStore cacheStore;
  final GeneratedAudioLibraryRemoteDataSource libraryRemoteDataSource;
  final AudioGenerationRemoteDataSource generationRemoteDataSource;
  final MyAudiosSyncHelper syncHelper;
  StreamSubscription<List<GeneratedAudioTaskEntity>>? _librarySubscription;
  Timer? _pendingRefreshTimer;
  bool _isRefreshingPendingTasks = false;

  String get _key => 'my_generated_tasks_$userId';

  Future<void> reload() async {
    await _loadTasks(forceLibraryResubscribe: true);
  }

  Future<void> _loadTasks({bool forceLibraryResubscribe = false}) async {
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

    await _syncRemoteSource();
    await _refreshPendingTasks();
    _schedulePendingRefresh();
  }

  Future<void> _syncRemoteSource() async {
    if (userId == 'guest_user') {
      state = state.copyWith(isSyncingRemote: false, errorMessage: null);
      return;
    }

    state = state.copyWith(isSyncingRemote: true, errorMessage: null);

    String? syncError;

    try {
      final remoteTasks = await libraryRemoteDataSource.getTasks(userId);
      if (!mounted) {
        return;
      }

      await _mergeAndPersist(remoteTasks, markSynced: false);
    } catch (error) {
      syncError = ErrorMessageMapper.map(error);
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isSyncingRemote: false,
      errorMessage: syncError,
      lastSyncedAt: syncError == null ? DateTime.now() : state.lastSyncedAt,
    );
  }

  Future<void> _mergeAndPersist(
    List<GeneratedAudioTaskEntity> incoming, {
    bool markSynced = true,
  }) async {
    final previousTasks = state.tasks;
    final mergedTasks = syncHelper.mergeTasks(previousTasks, incoming);
    state = state.copyWith(
      tasks: mergedTasks,
      errorMessage: null,
      lastSyncedAt: markSynced ? DateTime.now() : state.lastSyncedAt,
    );
    await cacheStore.writeTasks(_key, mergedTasks);
    _schedulePendingRefresh();
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

  Future<void> saveTask(GeneratedAudioTaskEntity task) async {
    await _mergeAndPersist([task]);

    if (userId == 'guest_user') {
      unawaited(refreshTaskStatus(task.id));
      return;
    }

    await libraryRemoteDataSource.saveTask(userId, task);
    unawaited(refreshTaskStatus(task.id));
  }

  Future<void> refreshTaskStatus(String taskId) async {
    GeneratedAudioTaskEntity? task;
    for (final item in state.tasks) {
      if (item.id == taskId) {
        task = item;
        break;
      }
    }

    if (task == null || !_shouldRefreshFromWorker(task)) {
      return;
    }

    await _refreshPendingTasks(tasks: [task]);
  }

  Future<void> _refreshPendingTasks({
    List<GeneratedAudioTaskEntity>? tasks,
  }) async {
    if (_isRefreshingPendingTasks) {
      return;
    }

    final pendingTasks = (tasks ?? state.tasks)
        .where(_shouldRefreshFromWorker)
        .toList();
    if (pendingTasks.isEmpty) {
      _schedulePendingRefresh();
      return;
    }

    _isRefreshingPendingTasks = true;
    state = state.copyWith(isSyncingRemote: true, errorMessage: null);

    final refreshedTasks = <GeneratedAudioTaskEntity>[];
    String? refreshError;

    try {
      for (final task in pendingTasks) {
        final refreshedTask = await generationRemoteDataSource
            .getGenerationStatus(task.id);
        final mergedTask = _withCurrentTaskContext(task, refreshedTask);
        refreshedTasks.add(mergedTask);

        if (userId != 'guest_user') {
          await libraryRemoteDataSource.saveTask(userId, mergedTask);
        }
      }

      if (refreshedTasks.isNotEmpty && mounted) {
        await _mergeAndPersist(refreshedTasks);
      }
    } catch (error) {
      refreshError = ErrorMessageMapper.map(error);
    } finally {
      _isRefreshingPendingTasks = false;
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isSyncingRemote: false,
      errorMessage: refreshError,
      lastSyncedAt: refreshError == null ? DateTime.now() : state.lastSyncedAt,
    );
    _schedulePendingRefresh();
  }

  GeneratedAudioTaskEntity _withCurrentTaskContext(
    GeneratedAudioTaskEntity current,
    GeneratedAudioTaskEntity refreshed,
  ) {
    return GeneratedAudioTaskEntity(
      id: refreshed.id,
      userId: refreshed.userId.trim().isEmpty
          ? current.userId
          : refreshed.userId,
      prompt: refreshed.prompt.trim().isEmpty
          ? current.prompt
          : refreshed.prompt,
      requestedDurationSeconds:
          refreshed.requestedDurationSeconds ??
          current.requestedDurationSeconds,
      status: refreshed.status,
      provider: refreshed.provider,
      outputCount: refreshed.outputCount,
      tracks: refreshed.tracks,
      createdAt: refreshed.createdAt ?? current.createdAt,
      updatedAt: refreshed.updatedAt ?? DateTime.now(),
    );
  }

  void _schedulePendingRefresh() {
    _pendingRefreshTimer?.cancel();

    if (!mounted || !state.tasks.any(_shouldRefreshFromWorker)) {
      return;
    }

    _pendingRefreshTimer = Timer(
      const Duration(
        seconds: AppConfig.audioGenerationPendingRefreshIntervalSeconds,
      ),
      () {
        if (mounted) {
          unawaited(_refreshPendingTasks());
        }
      },
    );
  }

  bool _shouldRefreshFromWorker(GeneratedAudioTaskEntity task) {
    if (task.provider.trim().toLowerCase() != 'suno-api') {
      return false;
    }

    final status = task.status.trim().toLowerCase();
    if (status == 'failed') {
      return false;
    }

    if ((status == 'success' || status == 'completed') &&
        task.tracks.isNotEmpty) {
      return false;
    }

    return true;
  }

  Future<void> removeTask(String taskId) async {
    final nextTasks = state.tasks.where((task) => task.id != taskId).toList();
    state = state.copyWith(tasks: nextTasks, errorMessage: null);
    await cacheStore.writeTasks(_key, nextTasks);
    _schedulePendingRefresh();

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
