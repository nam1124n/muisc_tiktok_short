import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';

final recentNotifierProvider =
    StateNotifierProvider<RecentNotifier, List<SongEntity>>((ref) {
      final authState = ref.watch(authNotifierProvider);
      final userId = authState is AuthSuccess ? authState.user.id : 'guest';
      return RecentNotifier(
        userId: userId,
        repository: ref.read(interactionRepositoryProvider),
      );
    });

class RecentNotifier extends StateNotifier<List<SongEntity>> {
  final String userId;
  final InteractionRepository repository;

  RecentNotifier({required this.userId, required this.repository}) : super([]) {
    if (userId != 'guest') {
      _loadRecents();
    }
  }

  Future<void> _loadRecents() async {
    try {
      final loaded = await repository.getRecents(userId);
      state = loaded;
    } catch (_) {
      // Ignored
    }
  }

  Future<void> addRecent(SongEntity song) async {
    if (userId == 'guest') return;

    final currentList = List<SongEntity>.from(state);

    // Remove if already exists so it can be moved to the top
    currentList.removeWhere((s) => s.id == song.id);

    // Insert at index 0 (top of the list)
    currentList.insert(0, song);

    // Keep only last 20 recents locally for UI
    if (currentList.length > 20) {
      currentList.removeLast();
    }

    state = currentList;
    try {
      await repository.addRecent(userId, song);
    } catch (_) {
      // Background save error ignored to keep UI smooth
    }
  }
}
