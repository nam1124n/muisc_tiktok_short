import 'package:cloud_firestore/cloud_firestore.dart';

abstract class InteractionRemoteDataSource {
  Future<List<Map<String, dynamic>>> getFavorites(String userId);
  Future<void> toggleFavorite(
    String userId,
    Map<String, dynamic> songData,
    bool isFavorite,
  );
  Future<void> clearFavorites(String userId, List<String> songIds);
  Future<List<Map<String, dynamic>>> getRecents(String userId);
  Future<void> addRecent(String userId, Map<String, dynamic> songData);
  Future<void> updateRecentProgress(
    String userId,
    Map<String, dynamic> songData, {
    required int positionSeconds,
    required int durationSeconds,
    required bool markCompleted,
  });
  Future<void> clearRecents(String userId, List<String> songIds);
}

class InteractionRemoteDataSourceImpl implements InteractionRemoteDataSource {
  final _db = FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> toggleFavorite(
    String userId,
    Map<String, dynamic> songData,
    bool isFavorite,
  ) async {
    final songId = songData['id'] as String;
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(songId);

    if (isFavorite) {
      await docRef.set({
        ...songData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  @override
  Future<void> clearFavorites(String userId, List<String> songIds) async {
    if (songIds.isEmpty) {
      return;
    }

    final batch = _db.batch();
    final collectionRef = _db
        .collection('users')
        .doc(userId)
        .collection('favorites');

    for (final songId in songIds) {
      batch.delete(collectionRef.doc(songId));
    }

    await batch.commit();
  }

  @override
  Future<List<Map<String, dynamic>>> getRecents(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('recents')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> addRecent(String userId, Map<String, dynamic> songData) async {
    final songId = songData['id'] as String;
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('recents')
        .doc(songId);

    await docRef.set({
      ...songData,
      'timestamp': FieldValue.serverTimestamp(),
      'playCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateRecentProgress(
    String userId,
    Map<String, dynamic> songData, {
    required int positionSeconds,
    required int durationSeconds,
    required bool markCompleted,
  }) async {
    final songId = songData['id'] as String;
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('recents')
        .doc(songId);

    await docRef.set({
      ...songData,
      'timestamp': FieldValue.serverTimestamp(),
      'lastPositionSeconds': markCompleted ? 0 : positionSeconds,
      'durationSeconds': durationSeconds,
      if (markCompleted) 'completedCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearRecents(String userId, List<String> songIds) async {
    if (songIds.isEmpty) {
      return;
    }

    final batch = _db.batch();
    final collectionRef = _db
        .collection('users')
        .doc(userId)
        .collection('recents');

    for (final songId in songIds) {
      batch.delete(collectionRef.doc(songId));
    }

    await batch.commit();
  }
}
