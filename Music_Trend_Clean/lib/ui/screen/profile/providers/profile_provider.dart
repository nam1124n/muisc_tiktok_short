import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/data/datasource/remote/profile_remote_data_source.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/data/repositories/profile_repository_impl.dart';
import 'package:login_flutter/domain/repositories/profile_repository.dart';
import 'package:login_flutter/domain/usecases/get_profile_usecase.dart';
import 'package:login_flutter/domain/usecases/update_avatar_usecase.dart';
import 'package:login_flutter/domain/usecases/update_profile_usecase.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_state.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSourceImpl();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.read(profileRemoteDataSourceProvider),
  );
});

final profileImageUploadRemoteDataSourceProvider =
    Provider<SongRemoteDataSource>((ref) {
      return SongRemoteDataSource();
    });

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.read(profileRepositoryProvider));
});

final updateAvatarUseCaseProvider = Provider<UpdateAvatarUseCase>((ref) {
  return UpdateAvatarUseCase(ref.read(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(profileRepositoryProvider));
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      return ProfileNotifier(
        getProfileUseCase: ref.read(getProfileUseCaseProvider),
        updateAvatarUseCase: ref.read(updateAvatarUseCaseProvider),
        updateProfileUseCase: ref.read(updateProfileUseCaseProvider),
        remoteDataSource: ref.read(profileImageUploadRemoteDataSourceProvider),
      );
    });

class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final SongRemoteDataSource remoteDataSource;

  ProfileNotifier({
    required this.getProfileUseCase,
    required this.updateAvatarUseCase,
    required this.updateProfileUseCase,
    required this.remoteDataSource,
  }) : super(ProfileInitial()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = ProfileLoading();

    try {
      final profile = await getProfileUseCase();
      state = ProfileLoaded(profile: profile);
    } catch (e) {
      state = ProfileError(message: e.toString());
    }
  }

  Future<void> updateAvatar({required String imagePath}) async {
    if (state is! ProfileLoaded) {
      return;
    }

    final currentState = state as ProfileLoaded;
    state = ProfileLoading();

    try {
      final imageUrl = await remoteDataSource.uploadImage(XFile(imagePath));
      await updateAvatarUseCase(imageUrl);
      final updatedProfile = currentState.profile.copyWith(avatarUrl: imageUrl);
      state = ProfileLoaded(profile: updatedProfile);
    } catch (e) {
      state = ProfileError(message: e.toString());
      state = ProfileLoaded(profile: currentState.profile);
    }
  }

  Future<void> updateProfileInfo({required String username}) async {
    if (state is! ProfileLoaded) {
      return;
    }

    final currentState = state as ProfileLoaded;
    state = ProfileLoading();

    try {
      await updateProfileUseCase(username);
      final updatedProfile = currentState.profile.copyWith(username: username);
      state = ProfileLoaded(profile: updatedProfile);
    } catch (e) {
      state = ProfileError(message: e.toString());
      state = ProfileLoaded(profile: currentState.profile);
    }
  }
}
