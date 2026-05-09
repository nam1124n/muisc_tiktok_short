import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/data/dto/auth/user_model.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> signUp(
    String fullName,
    String email,
    String password,
    String ageGroup,
  );
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> watchCurrentUser();
  Future<void> resetPassword(String email);
  Future<void> resendEmailVerification(String email, String password);
  Future<void> sendCurrentUserEmailVerification();
  Future<void> reloadCurrentUser();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user!;
      final profile = await _syncUserProfile(user);
      final token = await user.getIdToken();

      return UserModel(
        id: user.uid,
        email: user.email ?? email.trim(),
        fullName: profile.fullName,
        token: token ?? '',
        role: profile.role,
        isEmailVerified: user.emailVerified,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception(
          'Không tìm thấy tài khoản hoặc thông tin đăng nhập sai.',
        );
      } else if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu không chính xác.');
      } else if (e.code == 'too-many-requests') {
        throw Exception(
          'Bạn đã thử đăng nhập quá nhiều lần. Vui lòng chờ vài phút rồi thử lại.',
        );
      }
      throw Exception('Lỗi đăng nhập: ${e.message}');
    }
  }

  @override
  Future<UserModel> signUp(
    String fullName,
    String email,
    String password,
    String ageGroup,
  ) async {
    try {
      final trimmedFullName = fullName.trim();
      final trimmedEmail = email.trim();
      final normalizedAgeGroup = ProfileAgeGroups.normalize(ageGroup);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = userCredential.user!;
      await user.updateDisplayName(trimmedFullName);

      final profile = await _syncUserProfile(
        user,
        fullName: trimmedFullName,
        username: trimmedFullName,
        ageGroup: normalizedAgeGroup,
      );
      await user.sendEmailVerification();
      final token = await user.getIdToken();
      await _auth.signOut();

      return UserModel(
        id: user.uid,
        email: user.email ?? trimmedEmail,
        fullName: profile.fullName,
        token: token ?? '',
        role: profile.role,
        isEmailVerified: false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email này đã được sử dụng rồi.');
      }
      throw Exception('Lỗi đăng ký: ${e.message}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    return _buildUserModel(user);
  }

  @override
  Stream<UserModel?> watchCurrentUser() async* {
    await for (final user in _auth.userChanges()) {
      if (user == null) {
        yield null;
        continue;
      }

      yield await _buildUserModel(user);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Không tìm thấy tài khoản với email này.');
      }

      throw Exception('Lỗi quên mật khẩu: ${e.message}');
    }
  }

  @override
  Future<void> resendEmailVerification(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user!;
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception(
          'Bạn đã gửi yêu cầu quá nhiều lần. Vui lòng chờ vài phút rồi thử lại.',
        );
      } else if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception(
          'Không tìm thấy tài khoản hoặc thông tin đăng nhập sai.',
        );
      } else if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu không chính xác.');
      }
      throw Exception('Lỗi gửi lại email: ${e.message}');
    }
  }

  @override
  Future<void> sendCurrentUserEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Không tìm thấy tài khoản hiện tại.');
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception(
          'Bạn đã gửi yêu cầu quá nhiều lần. Vui lòng chờ vài phút rồi thử lại.',
        );
      }

      throw Exception('Lỗi gửi email xác thực: ${e.message}');
    }
  }

  @override
  Future<void> reloadCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw Exception('Lỗi làm mới trạng thái xác thực: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<_SyncedUserProfile> _syncUserProfile(
    User user, {
    String? fullName,
    String? username,
    String? ageGroup,
  }) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final resolvedFullName = _resolveFullName(
      data['fullName']?.toString(),
      user.displayName,
      fullName,
    );
    final resolvedUsername = _resolveUsername(
      data['username']?.toString(),
      username,
      resolvedFullName,
      user.uid,
    );
    final resolvedRole = _resolveRole(
      data['role']?.toString(),
      user.email ?? '',
    );
    final resolvedAgeGroup = ageGroup == null
        ? ProfileAgeGroups.normalize(data['ageGroup']?.toString())
        : ProfileAgeGroups.normalize(ageGroup);

    final payload = <String, Object?>{
      'email': user.email ?? '',
      'fullName': resolvedFullName,
      'username': resolvedUsername,
      'role': resolvedRole,
      'ageGroup': resolvedAgeGroup,
      'emailVerified': user.emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      payload['avatarUrl'] = data['avatarUrl'] ?? '';
      payload['followers'] = data['followers'] ?? 0;
      payload['following'] = data['following'] ?? 0;
      payload['likes'] = data['likes'] ?? 0;
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(payload, SetOptions(merge: true));

    return _SyncedUserProfile(
      fullName: resolvedFullName,
      role: resolvedRole,
      ageGroup: resolvedAgeGroup,
    );
  }

  Future<UserModel> _buildUserModel(User user) async {
    final profile = await _syncUserProfile(user);
    final token = await user.getIdToken();

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      fullName: profile.fullName,
      token: token ?? '',
      role: profile.role,
      isEmailVerified: user.emailVerified,
    );
  }

  String _resolveFullName(
    String? storedFullName,
    String? firebaseDisplayName,
    String? fallbackFullName,
  ) {
    final fullName = [storedFullName, firebaseDisplayName, fallbackFullName]
        .map((value) => value?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => 'Người dùng');

    return fullName;
  }

  String _resolveUsername(
    String? storedUsername,
    String? fallbackUsername,
    String resolvedFullName,
    String uid,
  ) {
    final username = [storedUsername, fallbackUsername, resolvedFullName]
        .map((value) => value?.trim() ?? '')
        .firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '@user_${uid.substring(0, 5)}',
        );

    return username;
  }

  String _resolveRole(String? storedRole, String email) {
    if (storedRole != null && storedRole.trim().isNotEmpty) {
      return UserRoles.normalize(storedRole);
    }

    if (AppConfig.isAdminEmail(email)) {
      return UserRoles.admin;
    }

    return UserRoles.user;
  }
}

class _SyncedUserProfile {
  const _SyncedUserProfile({
    required this.fullName,
    required this.role,
    required this.ageGroup,
  });

  final String fullName;
  final String role;
  final String ageGroup;
}
