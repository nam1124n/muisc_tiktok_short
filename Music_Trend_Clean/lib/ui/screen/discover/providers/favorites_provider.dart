import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/data/datasource/remote/interaction_remote_data_source.dart';
import 'package:login_flutter/data/repositories/interaction_repository_impl.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';

final interactionRemoteDataSourceProvider =
    Provider<InteractionRemoteDataSource>((ref) {
      return InteractionRemoteDataSourceImpl();
    });

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepositoryImpl(
    ref.read(interactionRemoteDataSourceProvider),
  );
});

final favoriteNotifierProvider =
    StateNotifierProvider<FavoriteNotifier, List<SongEntity>>((ref) {
      final authState = ref.watch(authNotifierProvider);
      final userId = authState is AuthSuccess ? authState.user.id : 'guest';
      return FavoriteNotifier(
        userId: userId,
        repository: ref.read(interactionRepositoryProvider),
      );
    });

class FavoriteNotifier extends StateNotifier<List<SongEntity>> {
  final String userId;
  final InteractionRepository repository;

  FavoriteNotifier({required this.userId, required this.repository})
    : super([]) {
    if (userId != 'guest') {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final loaded = await repository.getFavorites(userId);
      state = loaded;
    } catch (_) {
      // Ignored
    }
  }

  Future<void> toggleFavorite(SongEntity song) async {
    if (userId == 'guest') return;

    final currentList = List<SongEntity>.from(state);
    final isFavorite = currentList.any((s) => s.id == song.id);

    if (isFavorite) {
      currentList.removeWhere((s) => s.id == song.id);
    } else {
      currentList.insert(0, song);
    }

    state = currentList;
    try {
      await repository.toggleFavorite(userId, song, !isFavorite);
    } catch (_) {
      // Revert if API fails
      if (isFavorite) {
        currentList.insert(0, song);
      } else {
        currentList.removeWhere((s) => s.id == song.id);
      }
      state = currentList;
    }
  }

  bool isFavorite(String songId) {
    return state.any((s) => s.id == songId);
  }
}
