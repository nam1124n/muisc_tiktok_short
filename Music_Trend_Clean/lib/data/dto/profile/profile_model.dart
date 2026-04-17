import 'package:login_flutter/domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.username,
    required super.id,
    required super.avatarUrl,
    required super.followers,
    required super.following,
    required super.likes,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      username: json['username'] ?? '',
      id: json['id'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'id': id,
      'avatarUrl': avatarUrl,
      'followers': followers,
      'following': following,
      'likes': likes,
    };
  }
}
