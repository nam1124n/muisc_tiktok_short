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

    return ProfileModel(
      username:
          data['username'] ??
          fallbackUsername ??
          '@user_${userId.substring(0, 5)}',
      id: userId,
      avatarUrl: data['avatarUrl'] ?? '',
      followers: data['followers'] ?? 1200,
      following: data['following'] ?? 450,
      likes: data['likes'] ?? 15000,
      ageGroup: ProfileAgeGroups.normalize(data['ageGroup']?.toString()),
    );
  }
}
