import 'package:login_flutter/domain/entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<void> updateAvatarUrl(String url);
  Future<void> updateProfile(String username);
}
