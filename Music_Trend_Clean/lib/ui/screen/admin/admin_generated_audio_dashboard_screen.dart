import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/admin/providers/admin_generated_audio_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/admin_generated_audio_state.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';

class AdminGeneratedAudioDashboardScreen extends ConsumerStatefulWidget {
  const AdminGeneratedAudioDashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<AdminGeneratedAudioDashboardScreen> createState() =>
      _AdminGeneratedAudioDashboardScreenState();
}

class _AdminGeneratedAudioDashboardScreenState
    extends ConsumerState<AdminGeneratedAudioDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminGeneratedAudioProvider);

    final body = _buildBody(state);

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(adminGeneratedAudioProvider.notifier).loadTracks();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý nhạc AI (Suno)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8C52FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(adminGeneratedAudioProvider.notifier).loadTracks();
            },
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody(AdminGeneratedAudioState state) {
    if (state is AdminGeneratedAudioLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
      );
    }

    if (state is AdminGeneratedAudioError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(adminGeneratedAudioProvider.notifier).loadTracks();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state is AdminGeneratedAudioLoaded) {
      final tracks = state.tracks;

      if (tracks.isEmpty) {
        return const Center(child: Text('Chưa có bài nhạc AI nào.'));
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: tracks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _buildTrackTile(track);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTrackTile(GeneratedAudioEntity track) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: track.imageUrl.isNotEmpty
              ? Image.network(
                  track.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholderIcon(),
                )
              : _placeholderIcon(),
        ),
        title: Text(
          track.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prompt: ${track.prompt.isNotEmpty ? track.prompt : "N/A"}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'User: ${track.userId.isNotEmpty ? track.userId : "Unknown"}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Color(0xFF8C52FF)),
              onPressed: () => _playTrack(track),
            ),
            IconButton(
              icon: const Icon(Icons.rocket_launch, color: Colors.green),
              onPressed: () => _confirmPublish(track),
              tooltip: 'Đăng lên thư viện',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(track),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note, color: Color(0xFF8C52FF), size: 28),
    );
  }

  void _playTrack(GeneratedAudioEntity track) {
    if (track.audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bài hát này chưa có link Audio')),
      );
      return;
    }

    final dummySong = SongEntity(
      id: track.id,
      title: track.title,
      artist: 'AI Generated (${track.modelName})',
      audioUrl: track.audioUrl,
      imageUrl: track.imageUrl,
      status: 'published',
      trackInWeeklyStats: false,
    );

    ref.read(audioPlayerNotifierProvider.notifier).playSong(
      dummySong,
      playlist: [dummySong],
    );
  }

  void _confirmDelete(GeneratedAudioEntity track) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa bài nhạc AI này?'),
          content: Text('Bạn có chắc chắn muốn xóa "${track.title}"? Thao tác này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _executeDelete(track);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDelete(GeneratedAudioEntity track) async {
    await ref.read(adminGeneratedAudioProvider.notifier).deleteTrack(track);
  }

  void _confirmPublish(GeneratedAudioEntity track) {
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Phát hành bài nhạc?'),
          content: Text('Bạn có chắc chắn muốn đăng bài "${track.title}" lên thư viện chính cho tất cả mọi người cùng nghe không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _executePublish(track, scaffold);
              },
              child: const Text('Đăng bài'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executePublish(GeneratedAudioEntity track, ScaffoldMessengerState scaffold) async {
    try {
      await ref.read(adminGeneratedAudioProvider.notifier).publishTrack(track);
      if (!mounted) return;
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Đã đăng bài hát lên thư viện thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đăng bài hát: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
