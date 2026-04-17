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
  Future<void> updateAvatarUrl(String url) async {
    await remoteDataSource.updateAvatarUrl(url);
  }

  @override
  Future<void> updateProfile(String username) async {
    await remoteDataSource.updateProfile(username);
  }
}
