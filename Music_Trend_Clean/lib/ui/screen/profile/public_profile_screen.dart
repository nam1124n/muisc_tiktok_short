import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(publicProfileProvider(profileId));
    final playlistsAsync = ref.watch(publicPlaylistsProvider(profileId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FB),
      appBar: AppBar(
        title: Text(l10n.publicProfileTitle),
        actions: [
          IconButton(
            tooltip: l10n.copyProfileLink,
            onPressed: () async {
              final link = AppConfig.buildPublicProfileUrl(profileId);
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
            return playlistsAsync.when(
              data: (playlists) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PublicProfileHero(profile: profile),
                      const SizedBox(height: 20),
                      _PublicPlaylistsSection(playlists: playlists),
                    ],
                  ),
                );
              },
              loading: () => Column(
                children: [
                  _PublicProfileHero(profile: profile),
                  const SizedBox(height: 28),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (error, _) => _PublicProfileError(
                title: l10n.publicPlaylistsTitle,
                message: error.toString(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PublicProfileError(
            title: l10n.publicProfileTitle,
            message: error.toString(),
          ),
        ),
      ),
    );
  }
}

class _PublicProfileHero extends StatelessWidget {
  const _PublicProfileHero({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                child: _PublicStatChip(
                  label: l10n.followersLabel,
                  value: profile.followers.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PublicStatChip(
                  label: l10n.followingLabel,
                  value: profile.following.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PublicStatChip(
                  label: l10n.likesLabel,
                  value: profile.likes.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublicStatChip extends StatelessWidget {
  const _PublicStatChip({required this.label, required this.value});

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

class _PublicPlaylistsSection extends StatelessWidget {
  const _PublicPlaylistsSection({required this.playlists});

  final List<PlaylistEntity> playlists;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (playlists.isEmpty) {
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
        child: Column(
          children: [
            const Icon(
              Icons.library_music_rounded,
              color: Color(0xFFA066FF),
              size: 28,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.publicPlaylistsEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
        Text(
          l10n.publicPlaylistsTitle,
          style: const TextStyle(
            color: Color(0xFF20202B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.publicPlaylistsSubtitle,
          style: const TextStyle(
            color: Color(0xFF8E889C),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < playlists.length; index++) ...[
          _PublicPlaylistCard(playlist: playlists[index]),
          if (index < playlists.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PublicPlaylistCard extends StatelessWidget {
  const _PublicPlaylistCard({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
          _PublicPlaylistArtwork(playlist: playlist),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF20202B),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (playlist.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    playlist.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8E889C),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA066FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.trackCount(playlist.trackCount),
                    style: const TextStyle(
                      color: Color(0xFFA066FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPlaylistArtwork extends StatelessWidget {
  const _PublicPlaylistArtwork({required this.playlist});

  final PlaylistEntity playlist;

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
      child: playlist.coverUrl.isNotEmpty
          ? Image.network(
              playlist.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PublicPlaylistArtworkFallback(
                label: _playlistMonogram(playlist.name),
              ),
            )
          : _PublicPlaylistArtworkFallback(
              label: _playlistMonogram(playlist.name),
            ),
    );
  }
}

class _PublicPlaylistArtworkFallback extends StatelessWidget {
  const _PublicPlaylistArtworkFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PublicProfileError extends StatelessWidget {
  const _PublicProfileError({required this.title, required this.message});

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

String _playlistMonogram(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return 'MT';
  }

  final words = trimmed
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length == 1) {
    final end = words.first.length >= 2 ? 2 : 1;
    return words.first.substring(0, end).toUpperCase();
  }

  return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
      .toUpperCase();
}
