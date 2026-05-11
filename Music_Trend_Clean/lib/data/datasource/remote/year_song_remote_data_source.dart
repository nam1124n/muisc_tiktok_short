import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
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
    final isAdminEmail = AppConfig.isAdminEmail(user.email);

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
    await _db.collection(_collection).add({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSong(String id, Map<String, dynamic> data) async {
    await _db.collection(_collection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSong(String id) async {
    final moderatedBy = _auth.currentUser?.email ?? '';
    await _db.collection(_collection).doc(id).update({
      'status': SongStatuses.archived,
      'moderationReason': 'Archived from admin action',
      'moderatedBy': moderatedBy,
      'moderatedAt': FieldValue.serverTimestamp(),
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
