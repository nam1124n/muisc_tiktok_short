import 'package:login_flutter/data/dto/auth/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> signUp(String fullName, String email, String password);

  Future<void> resetPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String email, String password) async {
    try {
      // ✅ Sửa: Gọi FirebaseAuth.instance.signIn.... trực tiếp ngay tại đây
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user!;
      return UserModel(
        id: user.uid,
        email: user.email ?? email,
        fullName: user.displayName ?? "No Name",
        token: "firebase-auth-token-giao-cho-tuong-lai",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Không tìm thấy tài khoản với email này.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu không chính xác.');
      }
      throw Exception('Lỗi đăng nhập: ${e.message}');
    }
  }

  @override
  Future<UserModel> signUp(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      // ✅ Sửa: Gọi FirebaseAuth.instance.create.... trực tiếp ngay tại đây luôn
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user!;
      await user.updateDisplayName(fullName);
      return UserModel(
        id: user.uid,
        email: user.email ?? email,
        fullName: fullName,
        token: "firebase-auth-token-giao-cho-tuong-lai",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu (cần ít nhất 6 ký tự).');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email này đã được sử dụng rồi.');
      }
      throw Exception('Lỗi đăng ký: ${e.message}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user - not - found ') {
        throw Exception(' khong tim thay tai khoan voi email nay. ');
      }

      throw Exception('Lỗi quên mật khẩu: ${e.message}');
    }
  }
}
