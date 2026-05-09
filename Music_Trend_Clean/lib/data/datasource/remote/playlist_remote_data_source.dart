import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_flutter/data/dto/profile/playlist_model.dart';

abstract class PlaylistRemoteDataSource {
  Future<List<PlaylistModel>> getUserPlaylists(String userId);
  Future<PlaylistModel> createPlaylist({
    required String userId,
    required String name,
  });
  Future<void> updatePlaylistName({
    required String userId,
    required String playlistId,
    required String name,
  });
  Future<void> updatePlaylistSongs({
    required String userId,
    required String playlistId,
    required List<String> songIds,
  });
  Future<void> deletePlaylist({
    required String userId,
    required String playlistId,
  });
}

class PlaylistRemoteDataSourceImpl implements PlaylistRemoteDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<PlaylistModel>> getUserPlaylists(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PlaylistModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<PlaylistModel> createPlaylist({
    required String userId,
    required String name,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc();

    final now = DateTime.now();
    final playlist = PlaylistModel(
      id: docRef.id,
      name: name,
      coverUrl: '',
      songIds: const [],
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set({
      ...playlist.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return playlist;
  }

  @override
  Future<void> updatePlaylistName({
    required String userId,
    required String playlistId,
    required String name,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .set({
          'name': name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> updatePlaylistSongs({
    required String userId,
    required String playlistId,
    required List<String> songIds,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .set({
          'songIds': songIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> deletePlaylist({
    required String userId,
    required String playlistId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .delete();
  }
}
