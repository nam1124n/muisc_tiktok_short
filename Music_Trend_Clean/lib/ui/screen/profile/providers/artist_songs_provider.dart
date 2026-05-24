import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';

final artistSongsProvider =
    FutureProvider.family<List<SongEntity>, String>((ref, uploaderId) async {
  final songRepo = ref.watch(songRepositoryProvider);
  return songRepo.getSongsByUploaderId(uploaderId);
});
