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
  Future<List<String>> getHiddenFeedSongIds(String userId);
  Future<void> hideFeedSong(String userId, Map<String, dynamic> songData);
  Future<void> reportSong({
    required String userId,
    required Map<String, dynamic> songData,
    required String reason,
  });
  Stream<List<Map<String, dynamic>>> watchSongComments(String songId);
  Future<void> addSongComment({
    required String userId,
    required String userName,
    required String songId,
    required String text,
  });
  Future<void> deleteSongComment({
    required String songId,
    required String commentId,
  });
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
    final favoriteRef = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(songId);
    final songRef = _db.collection('songs').doc(songId);

    await _db.runTransaction((transaction) async {
      final favoriteSnapshot = await transaction.get(favoriteRef);
      if (isFavorite && !favoriteSnapshot.exists) {
        transaction.set(favoriteRef, {
          ...songData,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.set(songRef, {
          'favoriteCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (!isFavorite && favoriteSnapshot.exists) {
        transaction.delete(favoriteRef);
        transaction.set(songRef, {
          'favoriteCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
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

  @override
  Future<List<String>> getHiddenFeedSongIds(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('hidden_feed_songs')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<void> hideFeedSong(
    String userId,
    Map<String, dynamic> songData,
  ) async {
    final songId = songData['id'] as String;
    await _db
        .collection('users')
        .doc(userId)
        .collection('hidden_feed_songs')
        .doc(songId)
        .set({...songData, 'hiddenAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> reportSong({
    required String userId,
    required Map<String, dynamic> songData,
    required String reason,
  }) async {
    final songId = songData['id'] as String;
    final reportRef = _db.collection('song_reports').doc();
    final songRef = _db.collection('songs').doc(songId);
    final batch = _db.batch();

    batch.set(reportRef, {
      'songId': songId,
      'song': songData,
      'userId': userId,
      'reason': reason,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(songRef, {
      'reportCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchSongComments(String songId) {
    return _db
        .collection('songs')
        .doc(songId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id, 'songId': songId})
              .toList();
        });
  }

  @override
  Future<void> addSongComment({
    required String userId,
    required String userName,
    required String songId,
    required String text,
  }) async {
    final songRef = _db.collection('songs').doc(songId);
    final commentRef = songRef.collection('comments').doc();
    final batch = _db.batch();

    batch.set(commentRef, {
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(songRef, {
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<void> deleteSongComment({
    required String songId,
    required String commentId,
  }) async {
    final songRef = _db.collection('songs').doc(songId);
    final commentRef = songRef.collection('comments').doc(commentId);

    await _db.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) {
        return;
      }

      transaction.delete(commentRef);
      transaction.set(songRef, {
        'commentCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
