import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/domain/repositories/profile_repository.dart';
import 'package:login_flutter/data/datasource/remote/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProfileEntity> getProfile() async {
    try {
      final profileModel = await remoteDataSource.getProfile();
      return profileModel;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<ProfileEntity> getProfileById(String userId) async {
    try {
      final profileModel = await remoteDataSource.getProfileById(userId);
      return profileModel;
    } catch (e) {
      throw Exception('Failed to get public profile: $e');
    }
  }

  @override
  Future<void> updateAvatarUrl(String url) async {
    await remoteDataSource.updateAvatarUrl(url);
  }

  @override
  Future<void> updateProfile({
    required String username,
    required String ageGroup,
  }) async {
    await remoteDataSource.updateProfile(
      username: username,
      ageGroup: ageGroup,
    );
  }

  @override
  Future<void> toggleFollowUser(String targetUserId) async {
    return remoteDataSource.toggleFollowUser(targetUserId);
  }

  @override
  Stream<bool> watchIsFollowing(String targetUserId) {
    return remoteDataSource.watchIsFollowing(targetUserId);
  }

  @override
  Future<List<String>> getFollowingIds() async {
    return remoteDataSource.getFollowingIds();
  }
}
