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
}
