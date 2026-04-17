import 'package:cloud_firestore/cloud_firestore.dart';

abstract class InteractionRemoteDataSource {
  Future<List<Map<String, dynamic>>> getFavorites(String userId);
  Future<void> toggleFavorite(
    String userId,
    Map<String, dynamic> songData,
    bool isFavorite,
  );
  Future<List<Map<String, dynamic>>> getRecents(String userId);
  Future<void> addRecent(String userId, Map<String, dynamic> songData);
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
  Future<List<Map<String, dynamic>>> getRecents(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('recents')
        .orderBy('timestamp', descending: true)
        .limit(20)
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

    // Xóa record cũ nếu có (bằng cách ghi đè) sẽ tự động làm nhờ docRef.set, nhưng timestamps sẽ được cập nhật.
    await docRef.set({...songData, 'timestamp': FieldValue.serverTimestamp()});
  }
}
