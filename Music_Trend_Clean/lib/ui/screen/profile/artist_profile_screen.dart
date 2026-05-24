import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/artist_songs_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/follow_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';

class ArtistProfileScreen extends ConsumerWidget {
  const ArtistProfileScreen({super.key, required this.artistId});

  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(publicProfileProvider(artistId));
    final songsAsync = ref.watch(artistSongsProvider(artistId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FB),
      appBar: AppBar(
        title: const Text('Hồ sơ Nghệ sĩ'),
        actions: [
          IconButton(
            tooltip: l10n.copyProfileLink,
            onPressed: () async {
              final link = AppConfig.buildPublicProfileUrl(artistId);
              await Clipboard.setData(ClipboardData(text: link));
              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.profileLinkCopiedMessage)),
              );
            },
            icon: const Icon(Icons.link_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          data: (profile) {
            return songsAsync.when(
              data: (songs) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ArtistProfileHero(profile: profile),
                      const SizedBox(height: 20),
                      _ArtistSongsSection(songs: songs),
                    ],
                  ),
                );
              },
              loading: () => Column(
                children: [
                  _ArtistProfileHero(profile: profile),
                  const SizedBox(height: 28),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (error, _) => _ArtistProfileError(
                title: 'Lỗi tải bài hát',
                message: error.toString(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ArtistProfileError(
            title: l10n.publicProfileTitle,
            message: error.toString(),
          ),
        ),
      ),
    );
  }
}

class _ArtistProfileHero extends ConsumerWidget {
  const _ArtistProfileHero({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isFollowingAsync = ref.watch(isFollowingProvider(profile.id));
    final isFollowing = isFollowingAsync.maybeWhen(data: (val) => val, orElse: () => false);
    final followControllerState = ref.watch(followControllerProvider(profile.id));
    final isLoading = followControllerState is AsyncLoading;

    ref.listen(followControllerProvider(profile.id), (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.red),
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5BFF), Color(0xFFA066FF), Color(0xFFCDAEFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA066FF).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              image: profile.avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(profile.avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: profile.avatarUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            profile.username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileIdLabel(profile.id),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ArtistStatChip(
                  label: l10n.followersLabel,
                  value: profile.followers.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ArtistStatChip(
                  label: l10n.followingLabel,
                  value: profile.following.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ArtistStatChip(
                  label: l10n.likesLabel,
                  value: profile.likes.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: isLoading ? null : () {
                  ref.read(followControllerProvider(profile.id).notifier).toggleFollow();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                  foregroundColor: isFollowing ? Colors.white : const Color(0xFF6B5BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: isFollowing ? const BorderSide(color: Colors.white, width: 1.5) : BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: isFollowing ? 0 : 2,
                  minimumSize: const Size(0, 40),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        isFollowing ? Icons.check_rounded : Icons.person_add_rounded,
                        size: 20,
                      ),
                label: Text(
                  isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtistStatChip extends StatelessWidget {
  const _ArtistStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistSongsSection extends ConsumerWidget {
  const _ArtistSongsSection({required this.songs});

  final List<SongEntity> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(
              Icons.music_note_rounded,
              color: Color(0xFFA066FF),
              size: 28,
            ),
            SizedBox(height: 14),
            Text(
              'Chưa có bài hát nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF20202B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Tracks',
              style: TextStyle(
                color: Color(0xFF20202B),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded,
                  color: Color(0xFFA066FF), size: 36),
              onPressed: () {
                ref
                    .read(audioPlayerNotifierProvider.notifier)
                    .playSong(songs.first, playlist: songs);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < songs.length; index++) ...[
          _ArtistSongCard(song: songs[index], allSongs: songs),
          if (index < songs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ArtistSongCard extends ConsumerWidget {
  const _ArtistSongCard({required this.song, required this.allSongs});

  final SongEntity song;
  final List<SongEntity> allSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref
            .read(audioPlayerNotifierProvider.notifier)
            .playSong(song, playlist: allSongs);
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFCDAEFF).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _ArtistSongArtwork(song: song),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF20202B),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8E889C),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA066FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 14, color: Color(0xFFA066FF)),
                            const SizedBox(width: 4),
                            Text(
                              song.totalPlayCount.toString(),
                              style: const TextStyle(
                                color: Color(0xFFA066FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistSongArtwork extends StatelessWidget {
  const _ArtistSongArtwork({required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C5BFF), Color(0xFFCDAEFF)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: song.imageUrl.isNotEmpty
          ? Image.network(
              song.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.music_note,
                  color: Colors.white, size: 28),
            )
          : const Icon(Icons.music_note, color: Colors.white, size: 28),
    );
  }
}

class _ArtistProfileError extends StatelessWidget {
  const _ArtistProfileError({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF20202B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8E889C),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
