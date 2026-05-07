import 'package:login_flutter/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.token,
    required super.role,
    required super.isEmailVerified,
  });
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(), // Ensures ID is parsed as String
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      token: json['token'] ?? '',
      role: UserRoles.normalize(json['role']?.toString()),
      isEmailVerified: json['is_email_verified'] == true,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'token': token,
      'role': role,
      'is_email_verified': isEmailVerified,
    };
  }
}
