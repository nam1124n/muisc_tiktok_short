import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_task_model.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';

class GeneratedAudioLibraryRemoteDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _taskCollection(String userId) {
    return _db.collection('users').doc(userId).collection('generation_tasks');
  }

  CollectionReference<Map<String, dynamic>> _trackCollection(String userId) {
    return _db.collection('users').doc(userId).collection('generated_tracks');
  }

  Future<List<GeneratedAudioTaskEntity>> getTasks(String userId) async {
    final taskSnapshot = await _taskCollection(
      userId,
    ).orderBy('createdAt', descending: true).get();
    final trackSnapshot = await _trackCollection(
      userId,
    ).orderBy('createdAt', descending: true).get();

    final tracksByTaskId = <String, List<Map<String, dynamic>>>{};
    for (final doc in trackSnapshot.docs) {
      final data = {...doc.data(), 'id': doc.id};
      final taskId = data['taskId']?.toString() ?? '';
      if (taskId.isEmpty) {
        continue;
      }

      tracksByTaskId.putIfAbsent(taskId, () => []).add(data);
    }

    final tasks = taskSnapshot.docs.map((doc) {
      final data = {
        ...doc.data(),
        'taskId': doc.id,
        'tracks': tracksByTaskId[doc.id] ?? const <Map<String, dynamic>>[],
      };
      return GeneratedAudioTaskModel.fromJson(data);
    }).toList();

    tasks.sort((left, right) {
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

    return tasks;
  }

  Stream<List<GeneratedAudioTaskEntity>> watchTasks(String userId) {
    return _taskCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((_) => getTasks(userId));
  }

  Future<void> saveTask(String userId, GeneratedAudioTaskEntity task) async {
    final batch = _db.batch();
    final taskRef = _taskCollection(userId).doc(task.id);
    final taskMap = Map<String, dynamic>.from(task.toJson())..remove('tracks');

    batch.set(taskRef, taskMap, SetOptions(merge: true));

    for (final track in task.tracks) {
      final trackRef = _trackCollection(userId).doc(track.id);
      batch.set(trackRef, {
        ...track.toJson(),
        'taskId': task.id,
        'userId': userId,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> deleteTask(String userId, String taskId) async {
    final batch = _db.batch();
    final taskRef = _taskCollection(userId).doc(taskId);
    final tracksSnapshot = await _trackCollection(
      userId,
    ).where('taskId', isEqualTo: taskId).get();

    batch.delete(taskRef);
    for (final doc in tracksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
