import 'package:login_flutter/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.token,
  });
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(), // Ensures ID is parsed as String
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      token: json['token'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'full_name': fullName, 'token': token};
  }
}
