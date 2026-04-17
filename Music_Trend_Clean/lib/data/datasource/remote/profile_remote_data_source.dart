import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_flutter/data/dto/profile/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<void> updateAvatarUrl(String url);
  Future<void> updateProfile(String username);
  Future<ProfileModel> getProfile();
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
      }, SetOptions(merge: true));
    } else {
      throw Exception('Vui lòng đăng nhập trước khi thực hiện.');
    }
  }

  @override
  Future<void> updateProfile(String username) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(username);
      await _db.collection('users').doc(user.uid).set({
        'username': username,
      }, SetOptions(merge: true));
    } else {
      throw Exception('Vui lòng đăng nhập trước khi cập nhật.');
    }
  }

  @override
  Future<ProfileModel> getProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      return ProfileModel(
        username:
            data['username'] ??
            user.displayName ??
            '@user_${user.uid.substring(0, 5)}',
        id: user.uid,
        avatarUrl: data['avatarUrl'] ?? '',
        followers: data['followers'] ?? 1200,
        following: data['following'] ?? 450,
        likes: data['likes'] ?? 15000,
      );
    } else {
      throw Exception(
        'Không tìm thấy tài khoản để lấy profile. Yêu cầu đăng nhập.',
      );
    }
  }
}
