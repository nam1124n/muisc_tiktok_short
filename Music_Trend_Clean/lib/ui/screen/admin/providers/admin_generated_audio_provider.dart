import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/audio_generation_provider.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/admin/providers/admin_generated_audio_state.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';

final adminGeneratedAudioProvider =
    StateNotifierProvider<
      AdminGeneratedAudioNotifier,
      AdminGeneratedAudioState
    >((ref) {
      return AdminGeneratedAudioNotifier(ref);
    });

class AdminGeneratedAudioNotifier
    extends StateNotifier<AdminGeneratedAudioState> {
  AdminGeneratedAudioNotifier(this.ref) : super(AdminGeneratedAudioLoading()) {
    loadTracks();
  }

  final Ref ref;

  Future<void> loadTracks() async {
    try {
      state = AdminGeneratedAudioLoading();
      final dataSource = ref.read(
        generatedAudioLibraryRemoteDataSourceProvider,
      );
      final trackMaps = await dataSource.getAllGeneratedTracksForAdmin();
      final tracks = trackMaps
          .map((map) => GeneratedAudioEntity.fromJson(map))
          .toList();

      if (!mounted) return;
      state = AdminGeneratedAudioLoaded(tracks);
    } catch (e) {
      if (!mounted) return;
      state = AdminGeneratedAudioError(e.toString());
    }
  }

  Future<void> deleteTrack(GeneratedAudioEntity track) async {
    try {
      final dataSource = ref.read(
        generatedAudioLibraryRemoteDataSourceProvider,
      );
      await dataSource.deleteGeneratedTrackByAdmin(track.id, track.userId);

      if (state is AdminGeneratedAudioLoaded) {
        final currentTracks = (state as AdminGeneratedAudioLoaded).tracks;
        final newTracks = currentTracks.where((t) => t.id != track.id).toList();
        state = AdminGeneratedAudioLoaded(newTracks);
      }
    } catch (e) {
      // Could show a snackbar or log error, but for now we just reload
      await loadTracks();
    }
  }

  Future<void> publishTrack(GeneratedAudioEntity track) async {
    try {
      final songRemoteDataSource = ref.read(songRemoteDataSourceProvider);

      final songMap = {
        'title': track.title.isNotEmpty ? track.title : 'AI Song',
        'artist': 'Suno AI',
        'audioUrl': track.audioUrl,
        'imageUrl': track.imageUrl,
        'trackInWeeklyStats': true,
        'status': SongStatuses.published,
      };

      await songRemoteDataSource.addSong(songMap);

      // We don't automatically delete the track from AI list, but we can if we want.
      // For now, we just leave it so Admin can refer to it.
    } catch (e) {
      throw Exception('Failed to publish track: $e');
    }
  }
}
