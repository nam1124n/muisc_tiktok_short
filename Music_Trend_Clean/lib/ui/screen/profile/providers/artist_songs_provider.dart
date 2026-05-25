import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';

final artistSongsProvider = FutureProvider.family<List<SongEntity>, String>((
  ref,
  uploaderId,
) async {
  final songRepo = ref.watch(songRepositoryProvider);
  return songRepo.getSongsByUploaderId(uploaderId);
});

final userUploadedSongsProvider =
    FutureProvider.family<List<SongEntity>, String>((ref, uploaderId) async {
      final songRepo = ref.watch(songRepositoryProvider);
      final songs = await songRepo.getSongsByUploaderId(
        uploaderId,
        publishedOnly: false,
      );

      songs.sort((left, right) {
        final rightTime = right.updatedAt ?? right.publishedAt ?? right.savedAt;
        final leftTime = left.updatedAt ?? left.publishedAt ?? left.savedAt;
        final timeCompare = (rightTime?.millisecondsSinceEpoch ?? 0).compareTo(
          leftTime?.millisecondsSinceEpoch ?? 0,
        );

        if (timeCompare != 0) {
          return timeCompare;
        }

        return right.title.compareTo(left.title);
      });

      return songs;
    });
