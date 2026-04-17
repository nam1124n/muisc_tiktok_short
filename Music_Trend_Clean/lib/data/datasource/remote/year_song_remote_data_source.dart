import 'package:cloud_firestore/cloud_firestore.dart';

class YearSongRemoteDataSource {
  static const String _collection = 'yearly_songs';

  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getSongsStream() {
    return _db
        .collection(_collection)
        .orderBy('year', descending: true)
        .snapshots();
  }

  Future<void> addSong(Map<String, dynamic> data) async {
    await _db.collection(_collection).add(data);
  }

  Future<void> updateSong(String id, Map<String, dynamic> data) async {
    await _db.collection(_collection).doc(id).update(data);
  }

  Future<void> deleteSong(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
