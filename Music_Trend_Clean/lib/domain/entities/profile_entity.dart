import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String username;
  final String id;
  final String avatarUrl;
  final int followers;
  final int following;
  final int likes;

  const ProfileEntity({
    required this.username,
    required this.id,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    required this.likes,
  });

  ProfileEntity copyWith({
    String? username,
    String? id,
    String? avatarUrl,
    int? followers,
    int? following,
    int? likes,
  }) {
    return ProfileEntity(
      username: username ?? this.username,
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      likes: likes ?? this.likes,
    );
  }

  @override
  List<Object?> get props => [
    username,
    id,
    avatarUrl,
    followers,
    following,
    likes,
  ];
}
