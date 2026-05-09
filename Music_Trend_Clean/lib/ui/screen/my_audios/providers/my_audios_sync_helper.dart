import 'dart:convert';
import 'dart:math' as math;

import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';

class MyAudiosSyncHelper {
  const MyAudiosSyncHelper();

  List<GeneratedAudioTaskEntity> mergeTasks(
    List<GeneratedAudioTaskEntity> current,
    List<GeneratedAudioTaskEntity> incoming,
  ) {
    final tasksById = <String, GeneratedAudioTaskEntity>{
      for (final task in current) task.id: task,
    };

    for (final task in incoming) {
      final existing = tasksById[task.id];
      tasksById[task.id] = existing == null ? task : preferTask(existing, task);
    }

    final merged = tasksById.values.toList();
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

  GeneratedAudioTaskEntity preferTask(
    GeneratedAudioTaskEntity current,
    GeneratedAudioTaskEntity incoming,
  ) {
    if (incoming.tracks.length != current.tracks.length) {
      return incoming.tracks.length > current.tracks.length
          ? incoming
          : current;
    }

    final incomingRank = statusRank(incoming.status);
    final currentRank = statusRank(current.status);
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

  int statusRank(String status) {
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

  bool isPendingTask(GeneratedAudioTaskEntity task) {
    final normalized = task.status.trim().toLowerCase();
    return normalized == 'processing' || normalized == 'first_success';
  }

  bool shouldPollPending(List<GeneratedAudioTaskEntity> tasks) {
    return tasks.any(isPendingTask);
  }

  bool hasTaskChanged(
    GeneratedAudioTaskEntity? current,
    GeneratedAudioTaskEntity incoming,
  ) {
    if (current == null) {
      return true;
    }

    return jsonEncode(current.toJson()) != jsonEncode(incoming.toJson());
  }

  bool hasTaskListChanged(
    List<GeneratedAudioTaskEntity> current,
    List<GeneratedAudioTaskEntity> next,
  ) {
    if (current.length != next.length) {
      return true;
    }

    for (var index = 0; index < current.length; index++) {
      if (jsonEncode(current[index].toJson()) !=
          jsonEncode(next[index].toJson())) {
        return true;
      }
    }

    return false;
  }

  int nextPollingAttempt({
    required int previousAttempt,
    required bool hadProgress,
    required int maxAttempt,
  }) {
    if (hadProgress) {
      return 0;
    }

    return math.min(previousAttempt + 1, maxAttempt);
  }

  Duration pollingDelayForAttempt({
    required int attempt,
    required int baseSeconds,
    required int maxSeconds,
  }) {
    final safeAttempt = attempt.clamp(0, 30);
    final multiplier = 1 << safeAttempt;
    final seconds = math.min(baseSeconds * multiplier, maxSeconds);
    return Duration(seconds: seconds);
  }
}
