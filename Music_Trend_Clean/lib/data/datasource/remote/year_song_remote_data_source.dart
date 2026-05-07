import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';

class YearSongRemoteDataSource {
  static const String _collection = 'yearly_songs';

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> ensureAdminAccess() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Vui lòng đăng nhập để thực hiện thao tác quản trị.');
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    final role = UserRoles.normalize(doc.data()?['role']?.toString());
    final isAdminEmail =
        (user.email ?? '').trim().toLowerCase() == 'admin@gmail.com';

    if (role != UserRoles.admin && !isAdminEmail) {
      throw Exception('Bạn không có quyền thực hiện thao tác quản trị.');
    }
  }

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
