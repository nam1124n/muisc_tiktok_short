class UserRoles {
  static const String user = 'user';
  static const String admin = 'admin';

  static String normalize(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized == admin ? admin : user;
  }
}

class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String token;
  final String role;
  final bool isEmailVerified;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.token,
    required this.role,
    required this.isEmailVerified,
  });

  bool get isAdmin => role == UserRoles.admin;
}
