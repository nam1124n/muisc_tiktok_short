import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/config/audio_generation_config.dart';
import 'package:login_flutter/app/providers/audio_generation_provider.dart';
import 'package:login_flutter/data/datasource/remote/generated_audio_library_remote_data_source.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/domain/usecases/get_my_songs_usecase.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final myAudiosProvider =
    StateNotifierProvider<MyAudiosNotifier, List<GeneratedAudioTaskEntity>>((
      ref,
    ) {
      final authState = ref.watch(authNotifierProvider);
      final userId = authState is AuthSuccess
          ? authState.user.id
          : 'guest_user';

      return MyAudiosNotifier(
        userId,
        getMySongsUseCase: ref.read(getMySongsUseCaseProvider),
        libraryRemoteDataSource: ref.read(
          generatedAudioLibraryRemoteDataSourceProvider,
        ),
      );
    });

class MyAudiosNotifier extends StateNotifier<List<GeneratedAudioTaskEntity>> {
  final String userId;
  final GetMySongsUseCase getMySongsUseCase;
  final GeneratedAudioLibraryRemoteDataSource libraryRemoteDataSource;
  StreamSubscription<List<GeneratedAudioTaskEntity>>? _librarySubscription;
  Timer? _pendingRefreshTimer;
  bool _isRefreshingPending = false;

  MyAudiosNotifier(
    this.userId, {
    required this.getMySongsUseCase,
    required this.libraryRemoteDataSource,
  }) : super([]) {
    _loadTasks();
  }

  String get _key => 'my_generated_tasks_$userId';

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key);

    if (jsonList != null && jsonList.isNotEmpty) {
      try {
        state = jsonList
            .map((str) => GeneratedAudioTaskEntity.fromJson(jsonDecode(str)))
            .toList();
      } catch (_) {}
    }

    if (userId != 'guest_user') {
      _listenToLibraryUpdates();

      try {
        final remoteTasks = await libraryRemoteDataSource.getTasks(userId);
        state = _mergeTasks(state, remoteTasks);
        await _saveTasks(state);
      } catch (_) {}
    }

    try {
      final backendTasks = await getMySongsUseCase(userId: userId);

      if (backendTasks.isEmpty) {
        _syncPendingRefresh();
        return;
      }

      final previousState = state;
      state = _mergeTasks(state, backendTasks);
      await _saveTasks(state);

      if (userId != 'guest_user') {
        for (final task in backendTasks) {
          await _saveTaskToLibraryIfChanged(task, previousState);
        }
      }
    } catch (_) {}

    _syncPendingRefresh();
  }

  Future<void> _saveTasks(List<GeneratedAudioTaskEntity> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  List<GeneratedAudioTaskEntity> _mergeTasks(
    List<GeneratedAudioTaskEntity> current,
    List<GeneratedAudioTaskEntity> incoming,
  ) {
    final map = <String, GeneratedAudioTaskEntity>{
      for (final task in current) task.id: task,
    };

    for (final task in incoming) {
      final existing = map[task.id];
      map[task.id] = existing == null ? task : _preferTask(existing, task);
    }

    final merged = map.values.toList();
    merged.sort((left, right) {
      final rightTime =
          right.createdAt?.millisecondsSinceEpoch ??
          right.updatedAt?.millisecondsSinceEpoch ??
          0;
      final leftTime =
          left.createdAt?.millisecondsSinceEpoch ??
          left.updatedAt?.millisecondsSinceEpoch ??
          0;
      return rightTime.compareTo(leftTime);
    });

    return merged;
  }

  GeneratedAudioTaskEntity _preferTask(
    GeneratedAudioTaskEntity current,
    GeneratedAudioTaskEntity incoming,
  ) {
    if (incoming.tracks.length != current.tracks.length) {
      return incoming.tracks.length > current.tracks.length
          ? incoming
          : current;
    }

    final incomingRank = _statusRank(incoming.status);
    final currentRank = _statusRank(current.status);
    if (incomingRank != currentRank) {
      return incomingRank > currentRank ? incoming : current;
    }

    final incomingUpdatedAt =
        incoming.updatedAt?.millisecondsSinceEpoch ??
        incoming.createdAt?.millisecondsSinceEpoch ??
        0;
    final currentUpdatedAt =
        current.updatedAt?.millisecondsSinceEpoch ??
        current.createdAt?.millisecondsSinceEpoch ??
        0;

    return incomingUpdatedAt >= currentUpdatedAt ? incoming : current;
  }

  int _statusRank(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return 5;
      case 'success':
        return 4;
      case 'failed':
        return 3;
      case 'first_success':
        return 2;
      case 'processing':
        return 1;
      default:
        return 0;
    }
  }

  bool _isPendingTask(GeneratedAudioTaskEntity task) {
    final normalized = task.status.trim().toLowerCase();
    return normalized == 'processing' || normalized == 'first_success';
  }

  void _listenToLibraryUpdates() {
    _librarySubscription?.cancel();
    _librarySubscription = libraryRemoteDataSource.watchTasks(userId).listen((
      tasks,
    ) async {
      state = _mergeTasks(state, tasks);
      await _saveTasks(state);
      _syncPendingRefresh();
    }, onError: (_) {});
  }

  void _syncPendingRefresh() {
    if (state.any(_isPendingTask)) {
      _pendingRefreshTimer ??= Timer.periodic(
        const Duration(
          seconds: AudioGenerationConfig.pendingRefreshIntervalSeconds,
        ),
        (_) => _refreshPendingTasks(),
      );
      return;
    }

    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = null;
  }

  Future<void> _refreshPendingTasks() async {
    if (_isRefreshingPending || !state.any(_isPendingTask)) {
      return;
    }

    _isRefreshingPending = true;
    try {
      final backendTasks = await getMySongsUseCase(userId: userId);

      if (backendTasks.isEmpty) {
        return;
      }

      final previousState = state;
      state = _mergeTasks(state, backendTasks);
      await _saveTasks(state);

      if (userId != 'guest_user') {
        for (final task in backendTasks) {
          await _saveTaskToLibraryIfChanged(task, previousState);
        }
      }
    } catch (_) {
    } finally {
      _isRefreshingPending = false;
      _syncPendingRefresh();
    }
  }

  Future<void> _saveTaskToLibraryIfChanged(
    GeneratedAudioTaskEntity task,
    List<GeneratedAudioTaskEntity> sourceState,
  ) async {
    GeneratedAudioTaskEntity? existingTask;
    for (final item in sourceState) {
      if (item.id == task.id) {
        existingTask = item;
        break;
      }
    }

    if (existingTask != null &&
        jsonEncode(existingTask.toJson()) == jsonEncode(task.toJson())) {
      return;
    }

    await libraryRemoteDataSource.saveTask(userId, task);
  }

  Future<void> saveTask(GeneratedAudioTaskEntity task) async {
    state = _mergeTasks(state, [task]);
    await _saveTasks(state);
    _syncPendingRefresh();

    if (userId == 'guest_user') {
      return;
    }

    await libraryRemoteDataSource.saveTask(userId, task);
  }

  Future<void> removeTask(String taskId) async {
    state = state.where((task) => task.id != taskId).toList();
    await _saveTasks(state);
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
