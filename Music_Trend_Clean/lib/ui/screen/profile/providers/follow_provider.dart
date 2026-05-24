import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';

final isFollowingProvider = StreamProvider.family<bool, String>((ref, targetUserId) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchIsFollowing(targetUserId);
});

class FollowController extends StateNotifier<AsyncValue<void>> {
  FollowController(this._ref, this.targetUserId) : super(const AsyncData(null));

  final Ref _ref;
  final String targetUserId;

  Future<void> toggleFollow() async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(profileRepositoryProvider);
      await repo.toggleFollowUser(targetUserId);
      state = const AsyncData(null);
      // Invalidate profile to reflect the updated followers count
      _ref.invalidate(publicProfileProvider(targetUserId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final followControllerProvider = StateNotifierProvider.family<FollowController, AsyncValue<void>, String>((ref, targetUserId) {
  return FollowController(ref, targetUserId);
});
