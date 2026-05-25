import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_flutter/data/dto/profile/profile_model.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';

abstract class ProfileRemoteDataSource {
  Future<void> updateAvatarUrl(String url);
  Future<void> updateProfile({
    required String username,
    required String ageGroup,
  });
  Future<ProfileModel> getProfile();
  Future<ProfileModel> getProfileById(String userId);
  Future<void> toggleFollowUser(String targetUserId);
  Stream<bool> watchIsFollowing(String targetUserId);
  Future<List<String>> getFollowingIds();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Future<void> updateAvatarUrl(String url) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'avatarUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      throw Exception('Vui lòng đăng nhập trước khi thực hiện.');
    }
  }

  @override
  Future<void> updateProfile({
    required String username,
    required String ageGroup,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(username);
      await _db.collection('users').doc(user.uid).set({
        'username': username,
        'ageGroup': ProfileAgeGroups.normalize(ageGroup),
        'emailVerified': user.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      throw Exception('Vui lòng đăng nhập trước khi cập nhật.');
    }
  }

  @override
  Future<ProfileModel> getProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      return _readProfileModel(
        userId: user.uid,
        fallbackUsername: user.displayName,
      );
    } else {
      throw Exception(
        'Không tìm thấy tài khoản để lấy profile. Yêu cầu đăng nhập.',
      );
    }
  }

  @override
  Future<ProfileModel> getProfileById(String userId) async {
    return _readProfileModel(userId: userId);
  }

  Future<ProfileModel> _readProfileModel({
    required String userId,
    String? fallbackUsername,
  }) async {
    final doc = await _db.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    final totalSongLikes = await _readTotalSongLikes(userId);

    return ProfileModel(
      username:
          data['username'] ??
          fallbackUsername ??
          '@user_${userId.substring(0, 5)}',
      id: userId,
      avatarUrl: data['avatarUrl'] ?? '',
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      likes: totalSongLikes,
      ageGroup: ProfileAgeGroups.normalize(data['ageGroup']?.toString()),
    );
  }

  Future<int> _readTotalSongLikes(String userId) async {
    final snapshot = await _db
        .collection('songs')
        .where('uploaderId', isEqualTo: userId)
        .get();

    var totalLikes = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'archived') {
        continue;
      }

      totalLikes += (data['favoriteCount'] as num?)?.toInt() ?? 0;
    }

    return totalLikes;
  }

  @override
  Future<void> toggleFollowUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Yêu cầu đăng nhập để theo dõi.');
    }
    if (currentUser.uid == targetUserId) {
      throw Exception('Bạn không thể theo dõi chính mình.');
    }

    final followerRef = _db
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUser.uid);
    final followingRef = _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(targetUserId);

    final targetUserRef = _db.collection('users').doc(targetUserId);
    final currentUserRef = _db.collection('users').doc(currentUser.uid);

    await _db.runTransaction((tx) async {
      final followerDoc = await tx.get(followerRef);
      if (followerDoc.exists) {
        // Unfollow
        tx.delete(followerRef);
        tx.delete(followingRef);
        tx.set(targetUserRef, {
          'followers': FieldValue.increment(-1),
        }, SetOptions(merge: true));
        tx.set(currentUserRef, {
          'following': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      } else {
        // Follow
        tx.set(followerRef, {'timestamp': FieldValue.serverTimestamp()});
        tx.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});
        tx.set(targetUserRef, {
          'followers': FieldValue.increment(1),
        }, SetOptions(merge: true));
        tx.set(currentUserRef, {
          'following': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    });
  }

  @override
  Stream<bool> watchIsFollowing(String targetUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);

    return _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Future<List<String>> getFollowingIds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
