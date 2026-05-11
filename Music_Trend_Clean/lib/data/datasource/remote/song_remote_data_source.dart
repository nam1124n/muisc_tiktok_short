import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/data/dto/admin/song_model.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';

class SongRemoteDataSource {
  static const String _songsCollection = 'songs';
  static const String _weeklyStatsCollection = 'song_weekly_stats';

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

  // ── Cloudinary: upload ảnh, trả về URL ──
  Future<String> uploadImage(XFile imageFile) async {
    return _uploadToCloudinary(
      file: imageFile,
      cloudName: AppConfig.cloudinaryCloudName,
      uploadPreset: AppConfig.cloudinaryUploadPreset,
      resourceType: 'image',
      fallbackFileName: 'cover.jpg',
    );
  }

  // ── Cloudinary: upload audio, trả về URL ──
  Future<String> uploadAudio(XFile audioFile) async {
    return _uploadToCloudinary(
      file: audioFile,
      cloudName: AppConfig.cloudinaryCloudName,
      uploadPreset: AppConfig.cloudinaryUploadPreset,
      resourceType: 'video',
      fallbackFileName: 'audio.mp3',
    );
  }

  Future<String> _uploadToCloudinary({
    required XFile file,
    required String cloudName,
    required String uploadPreset,
    required String resourceType,
    required String fallbackFileName,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: file.name.isNotEmpty ? file.name : fallbackFileName,
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode >= 400 || json['secure_url'] == null) {
      final message =
          (json['error']?['message'] as String?) ?? 'Upload file thất bại';
      throw Exception(message);
    }

    return json['secure_url'] as String;
  }

  // ── Firestore: thêm bài hát ──
  Future<void> addSong(Map<String, dynamic> data) async {
    await _db.collection(_songsCollection).add({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Firestore: cập nhật bài hát ──
  Future<void> updateSong(String id, Map<String, dynamic> data) async {
    await _db.collection(_songsCollection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      ..._legacySearchMetadataCleanup(),
    });
  }

  // ── Firestore: xoá bài hát ──
  Future<void> deleteSong(String id) async {
    final moderatedBy = _auth.currentUser?.email ?? '';
    await _db.collection(_songsCollection).doc(id).update({
      'status': SongStatuses.archived,
      'moderationReason': 'Archived from admin action',
      'moderatedBy': moderatedBy,
      'moderatedAt': FieldValue.serverTimestamp(),
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Firestore: lắng nghe danh sách realtime ──
  Stream<QuerySnapshot> getSongsStream() {
    return _db.collection(_songsCollection).orderBy('title').snapshots();
  }

  Future<SongPageEntity> fetchSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(_songsCollection)
        .orderBy('title')
        .orderBy(FieldPath.documentId)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfter([startAfter.title, startAfter.id]);
    }

    final snapshot = await query.get();
    final songs = snapshot.docs
        .map((doc) => SongModel.fromFirestore(doc.data(), doc.id))
        .toList();
    final lastDocument = snapshot.docs.isEmpty ? null : snapshot.docs.last;

    return SongPageEntity(
      songs: songs,
      nextCursor: lastDocument == null
          ? null
          : SongPageCursor(
              title:
                  lastDocument.data()['title']?.toString() ?? songs.last.title,
              id: lastDocument.id,
            ),
      hasMore: snapshot.docs.length == limit,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getWeeklyTrendingSongsStream() {
    return _db
        .collection(_weeklyStatsCollection)
        .doc(_currentWeekKey())
        .collection('songs')
        .orderBy('uniqueUserCount', descending: true)
        .snapshots();
  }

  Future<void> trackSongListen(Map<String, dynamic> songData) async {
    final userId = _auth.currentUser?.uid;
    final songId = songData['id'] as String?;

    if (userId == null || songId == null || songId.isEmpty) {
      return;
    }

    final weekKey = _currentWeekKey();
    final statsRef = _db
        .collection(_weeklyStatsCollection)
        .doc(weekKey)
        .collection('songs')
        .doc(songId);
    final listenerRef = statsRef.collection('listeners').doc(userId);

    await _db.runTransaction((transaction) async {
      final statsSnapshot = await transaction.get(statsRef);
      final listenerSnapshot = await transaction.get(listenerRef);

      final currentTotal =
          (statsSnapshot.data()?['totalPlayCount'] as num?)?.toInt() ?? 0;
      final currentUnique =
          (statsSnapshot.data()?['uniqueUserCount'] as num?)?.toInt() ?? 0;
      final isNewUniqueListener = !listenerSnapshot.exists;

      transaction.set(statsRef, {
        ...songData,
        ..._legacySearchMetadataCleanup(),
        'songId': songId,
        'weekKey': weekKey,
        'totalPlayCount': currentTotal + 1,
        'uniqueUserCount': currentUnique + (isNewUniqueListener ? 1 : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(listenerRef, {
        'userId': userId,
        'listenedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  String _currentWeekKey() {
    final now = DateTime.now();
    final normalized = DateTime(now.year, now.month, now.day);
    final startOfWeek = normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );

    final year = startOfWeek.year.toString().padLeft(4, '0');
    final month = startOfWeek.month.toString().padLeft(2, '0');
    final day = startOfWeek.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Map<String, Object> _legacySearchMetadataCleanup() {
    return {
      'semanticTags': FieldValue.delete(),
      'searchAliases': FieldValue.delete(),
      'energyLevel': FieldValue.delete(),
    };
  }
}
