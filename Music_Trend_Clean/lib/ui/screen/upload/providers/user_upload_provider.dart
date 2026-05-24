import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';

class UserUploadState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const UserUploadState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  UserUploadState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return UserUploadState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class UserUploadNotifier extends StateNotifier<UserUploadState> {
  final Ref _ref;

  UserUploadNotifier(this._ref) : super(const UserUploadState());

  Future<void> uploadSong({
    required String title,
    required XFile imageFile,
    required XFile audioFile,
  }) async {
    if (title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập tên bài hát');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final session = _ref.read(sessionProvider);
      final currentUser = session.currentUser;

      if (!session.isAuthenticated || currentUser == null) {
        throw Exception('Vui lòng đăng nhập để tải nhạc lên');
      }

      final songRepo = _ref.read(songRepositoryProvider);
      final song = SongEntity(
        id: '', // Firestore auto-generates
        title: title.trim(),
        artist: currentUser.fullName,
        uploaderId: currentUser.id,
        audioUrl: '', // Upload handles this
        imageUrl: '', // Upload handles this
        status: SongStatuses.pending,
      );

      await songRepo.userUploadSong(song, imageFile, audioFile);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const UserUploadState();
  }
}

final userUploadNotifierProvider =
    StateNotifierProvider.autoDispose<UserUploadNotifier, UserUploadState>((ref) {
  return UserUploadNotifier(ref);
});
