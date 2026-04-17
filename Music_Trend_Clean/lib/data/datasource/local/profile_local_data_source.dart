import 'package:login_flutter/data/dto/profile/profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<ProfileModel> getProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  @override
  Future<ProfileModel> getProfile() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Returning mock data as per requirements:
    // Username: @musiclover_2024
    // ID: 982347102
    // Followers: 1200 (1.2k)
    // Following: 450
    // Likes: 15000 (15k)
    return const ProfileModel(
      username: '@musiclover_2024',
      id: '982347102',
      avatarUrl: '', // In the original code it's a styled gradient/container
      followers: 1200,
      following: 450,
      likes: 15000,
    );
  }
}
