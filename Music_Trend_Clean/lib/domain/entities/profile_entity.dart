import 'package:equatable/equatable.dart';

class ProfileAgeGroups {
  static const String under13 = 'under_13';
  static const String teens = '13_to_17';
  static const String adults = '18_plus';
  static const String preferNotToSay = 'prefer_not_to_say';

  static const List<String> values = [under13, teens, adults, preferNotToSay];

  static String normalize(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    for (final ageGroup in values) {
      if (ageGroup == normalized) {
        return ageGroup;
      }
    }

    return preferNotToSay;
  }
}

class ProfileEntity extends Equatable {
  final String username;
  final String id;
  final String avatarUrl;
  final int followers;
  final int following;
  final int likes;
  final String ageGroup;

  const ProfileEntity({
    required this.username,
    required this.id,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    required this.likes,
    required this.ageGroup,
  });

  ProfileEntity copyWith({
    String? username,
    String? id,
    String? avatarUrl,
    int? followers,
    int? following,
    int? likes,
    String? ageGroup,
  }) {
    return ProfileEntity(
      username: username ?? this.username,
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      likes: likes ?? this.likes,
      ageGroup: ageGroup ?? this.ageGroup,
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
    ageGroup,
  ];
}
