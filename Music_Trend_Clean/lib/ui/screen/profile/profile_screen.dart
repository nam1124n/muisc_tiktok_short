import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/profile/playlist_detail_screen.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_state.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';
import 'package:login_flutter/ui/screen/profile/widgets/profile_actions.dart';
import 'package:login_flutter/ui/screen/profile/widgets/profile_header.dart';
import 'package:login_flutter/ui/screen/profile/widgets/profile_info.dart';
import 'package:login_flutter/ui/screen/auth/login_screen.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _background = Color(0xFFF7F3FB);
  static const Color _primary = Color(0xFFA066FF);
  static const Color _secondary = Color(0xFFCDAEFF);
  static const Color _textPrimary = Color(0xFF20202B);
  static const Color _textMuted = Color(0xFF8E889C);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: _background, body: ProfileContent());
  }
}

class ProfileContent extends ConsumerWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9F7FD), Color(0xFFF3EDF9)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _buildBody(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state is ProfileLoading || state is ProfileInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProfileError) {
      final isAuthError =
          state.message.toLowerCase().contains('đăng nhập') ||
          state.message.toLowerCase().contains('login') ||
          state.message.toLowerCase().contains('auth');

      if (isAuthError) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ProfileScreen._primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  size: 64,
                  color: ProfileScreen._primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chưa đăng nhập',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ProfileScreen._textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng đăng nhập để xem và tùy chỉnh hồ sơ cá nhân của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: ProfileScreen._textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileScreen._primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
      return Center(child: Text('${l10n.errorLabel}: ${state.message}'));
    }

    if (state is ProfileLoaded) {
      final profile = state.profile;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProfileHeader(textPrimary: ProfileScreen._textPrimary),
            const SizedBox(height: 18),
            ProfileInfo(
              profile: profile,
              primaryColor: ProfileScreen._primary,
              textPrimary: ProfileScreen._textPrimary,
            ),
            const SizedBox(height: 24),
            ProfileActions(
              profile: profile,
              primaryColor: ProfileScreen._primary,
            ),
            const SizedBox(height: 28),
            const _LibrarySection(),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

enum _ProfileLibraryTab { playlists, favorites }

class _LibrarySection extends StatefulWidget {
  const _LibrarySection();

  @override
  State<_LibrarySection> createState() => _LibrarySectionState();
}

class _LibrarySectionState extends State<_LibrarySection> {
  _ProfileLibraryTab _selectedTab = _ProfileLibraryTab.playlists;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LibraryTabs(
          selectedTab: _selectedTab,
          onTabSelected: (tab) {
            if (_selectedTab == tab) {
              return;
            }

            setState(() {
              _selectedTab = tab;
            });
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _selectedTab == _ProfileLibraryTab.playlists
              ? const _PlaylistLibraryContent(key: ValueKey('playlists'))
              : const _FavoritesLibraryContent(key: ValueKey('favorites')),
        ),
      ],
    );
  }
}

class _LibraryTabs extends StatelessWidget {
  const _LibraryTabs({required this.selectedTab, required this.onTabSelected});

  final _ProfileLibraryTab selectedTab;
  final ValueChanged<_ProfileLibraryTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _LibraryTabItem(
              label: l10n.playlistsLabel,
              icon: Icons.grid_view_rounded,
              isActive: selectedTab == _ProfileLibraryTab.playlists,
              onTap: () => onTabSelected(_ProfileLibraryTab.playlists),
            ),
          ),
          Expanded(
            child: _LibraryTabItem(
              label: l10n.favoritesLabel,
              icon: Icons.favorite_rounded,
              isActive: selectedTab == _ProfileLibraryTab.favorites,
              onTap: () => onTabSelected(_ProfileLibraryTab.favorites),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTabItem extends StatelessWidget {
  const _LibraryTabItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isActive
        ? ProfileScreen._primary
        : ProfileScreen._textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  letterSpacing: 0.2,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistLibraryContent extends ConsumerWidget {
  const _PlaylistLibraryContent({super.key});

  Future<void> _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreatePlaylistDialog(),
    );

    if (name == null) {
      return;
    }

    // Let the dialog route finish deactivating before mutating the page state.
    await WidgetsBinding.instance.endOfFrame;

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .createPlaylist(name);

    if (!context.mounted) {
      return;
    }

    final playlistState = ref.read(playlistNotifierProvider);
    final errorMessage = playlistState.errorMessage;
    if (!success && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
    }
  }

  void _openPlaylistDetail(BuildContext context, PlaylistEntity playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playlistState = ref.watch(playlistNotifierProvider);
    final playlists = playlistState.playlists;

    if (playlistState.isLoading && playlists.isEmpty) {
      return const _PlaylistStatusCard(
        key: ValueKey('playlists-loading'),
        child: CircularProgressIndicator(color: ProfileScreen._primary),
      );
    }

    if (playlistState.errorMessage != null && playlists.isEmpty) {
      return _PlaylistStatusCard(
        key: const ValueKey('playlists-error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playlistState.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ProfileScreen._textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(playlistNotifierProvider.notifier).loadPlaylists();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (playlists.isEmpty) {
      return Column(
        key: const ValueKey('playlists-empty'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CreatePlaylistCard(
            isCreating: playlistState.isCreating,
            onPressed: () => _showCreatePlaylistDialog(context, ref),
          ),
          const SizedBox(height: 16),
          const _PlaylistStatusCard(
            child: Text(
              'Chưa có playlist nào. Tạo playlist đầu tiên để bắt đầu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ProfileScreen._textMuted,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    final featuredPlaylist = playlists.first;
    final secondaryPlaylists = playlists.skip(1).toList();

    return Column(
      key: const ValueKey('playlist-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeaturedPlaylistCard(
          playlist: featuredPlaylist,
          onTap: () => _openPlaylistDetail(context, featuredPlaylist),
        ),
        const SizedBox(height: 16),
        _PlaylistGrid(
          playlists: secondaryPlaylists,
          isCreating: playlistState.isCreating,
          onCreatePressed: () => _showCreatePlaylistDialog(context, ref),
          onPlaylistPressed: (playlist) =>
              _openPlaylistDetail(context, playlist),
        ),
      ],
    );
  }
}

class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.createNewPlaylist,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _controller,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
        decoration: InputDecoration(
          labelText: 'Tên playlist',
          hintText: 'Midnight Echoes',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.saveChanges),
        ),
      ],
    );
  }
}

class _FavoritesLibraryContent extends ConsumerWidget {
  const _FavoritesLibraryContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favoriteSongs = ref.watch(favoriteNotifierProvider);

    if (favoriteSongs.isEmpty) {
      return Container(
        key: const ValueKey('favorites-content'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProfileScreen._primary.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: ProfileScreen._primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.favoriteSongsEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ProfileScreen._textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('favorites-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < favoriteSongs.length; index++) ...[
          _FavoriteSongCard(
            song: favoriteSongs[index],
            playlist: favoriteSongs,
          ),
          if (index < favoriteSongs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FavoriteSongCard extends ConsumerWidget {
  const _FavoriteSongCard({required this.song, required this.playlist});

  final SongEntity song;
  final List<SongEntity> playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ProfileScreen._secondary.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: ProfileScreen._primary.withValues(alpha: 0.12),
            ),
            clipBehavior: Clip.antiAlias,
            child: song.imageUrl.isNotEmpty
                ? Image.network(
                    song.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.music_note_rounded,
                      color: ProfileScreen._primary,
                      size: 26,
                    ),
                  )
                : const Icon(
                    Icons.music_note_rounded,
                    color: ProfileScreen._primary,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ProfileScreen._textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ProfileScreen._textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(favoriteNotifierProvider.notifier).toggleFavorite(song);
            },
            icon: const Icon(
              Icons.favorite_rounded,
              color: ProfileScreen._primary,
            ),
          ),
          _FavoriteSongPlayButton(song: song, playlist: playlist),
        ],
      ),
    );
  }
}

class _FavoriteSongPlayButton extends ConsumerWidget {
  const _FavoriteSongPlayButton({required this.song, required this.playlist});

  final SongEntity song;
  final List<SongEntity> playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerNotifierProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlayingThisSong = isCurrentSong && playerState.isPlaying;
    final isLoadingThisSong = isCurrentSong && playerState.isLoading;

    return IconButton(
      onPressed: () {
        if (isPlayingThisSong) {
          ref.read(audioPlayerNotifierProvider.notifier).pause();
          return;
        }

        if (isCurrentSong) {
          ref.read(audioPlayerNotifierProvider.notifier).resume();
          return;
        }

        ref
            .read(audioPlayerNotifierProvider.notifier)
            .playSong(song, playlist: playlist);
        ref.read(recentNotifierProvider.notifier).addRecent(song);
      },
      icon: isLoadingThisSong
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ProfileScreen._primary,
              ),
            )
          : Icon(
              isPlayingThisSong
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              size: 28,
              color: isCurrentSong
                  ? ProfileScreen._primary
                  : ProfileScreen._textMuted,
            ),
    );
  }
}

class _PlaylistStatusCard extends StatelessWidget {
  const _PlaylistStatusCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _FeaturedPlaylistCard extends StatelessWidget {
  const _FeaturedPlaylistCard({required this.playlist, required this.onTap});

  final PlaylistEntity playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = _playlistPalette(playlist.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.last.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Positioned(
                  left: -24,
                  top: -38,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  right: -12,
                  top: -6,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  top: 22,
                  left: 22,
                  child: Text(
                    l10n.playlistsLabel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 22,
                  child: _PlaylistArtwork(playlist: playlist, size: 92),
                ),
                Positioned(
                  left: 22,
                  right: 120,
                  bottom: 38,
                  child: Text(
                    playlist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  bottom: 16,
                  child: Text(
                    l10n.trackCount(playlist.trackCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 16,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  const _PlaylistGrid({
    required this.playlists,
    required this.onCreatePressed,
    required this.isCreating,
    required this.onPlaylistPressed,
  });

  final List<PlaylistEntity> playlists;
  final VoidCallback onCreatePressed;
  final bool isCreating;
  final ValueChanged<PlaylistEntity> onPlaylistPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;
        final spacing = compact ? 12.0 : 14.0;
        final itemWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _CreatePlaylistCard(
                isCreating: isCreating,
                onPressed: onCreatePressed,
              ),
            ),
            for (final playlist in playlists)
              SizedBox(
                width: itemWidth,
                child: _PlaylistGridCard(
                  playlist: playlist,
                  onTap: () => onPlaylistPressed(playlist),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlaylistGridCard extends StatelessWidget {
  const _PlaylistGridCard({required this.playlist, required this.onTap});

  final PlaylistEntity playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = _playlistPalette(playlist.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          height: 136,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.first, palette.last.withValues(alpha: 0.92)],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.last.withValues(alpha: 0.2),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                  left: -10,
                  top: -10,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: _PlaylistArtwork(playlist: playlist, size: 48),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 34,
                  child: Text(
                    playlist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 14,
                  child: Text(
                    l10n.trackCount(playlist.trackCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistArtwork extends StatelessWidget {
  const _PlaylistArtwork({required this.playlist, required this.size});

  final PlaylistEntity playlist;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (playlist.coverUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.32),
          color: Colors.white.withValues(alpha: 0.18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          playlist.coverUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _PlaylistArtworkFallback(
            label: _playlistMonogram(playlist.name),
            size: size,
          ),
        ),
      );
    }

    return _PlaylistArtworkFallback(
      label: _playlistMonogram(playlist.name),
      size: size,
    );
  }
}

class _PlaylistArtworkFallback extends StatelessWidget {
  const _PlaylistArtworkFallback({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _CreatePlaylistCard extends StatelessWidget {
  const _CreatePlaylistCard({
    required this.onPressed,
    required this.isCreating,
  });

  final VoidCallback onPressed;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      height: 136,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: ProfileScreen._secondary.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: isCreating ? null : onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ProfileScreen._primary.withValues(alpha: 0.14),
                ),
                alignment: Alignment.center,
                child: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ProfileScreen._primary,
                        ),
                      )
                    : const Icon(
                        Icons.add_rounded,
                        color: ProfileScreen._primary,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.createNewPlaylist,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: ProfileScreen._textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Color> _playlistPalette(String seed) {
  const palettes = [
    [Color(0xFF6654FF), Color(0xFFA36CFF)],
    [Color(0xFF247BA0), Color(0xFF70C1B3)],
    [Color(0xFF7A3E65), Color(0xFFE76F51)],
    [Color(0xFF214E34), Color(0xFF6E9F6D)],
    [Color(0xFF2D3047), Color(0xFF7D8597)],
  ];

  final code = seed.codeUnits.fold<int>(0, (total, unit) => total + unit);
  return palettes[code % palettes.length];
}

String _playlistMonogram(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return 'PL';
  }

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
}
