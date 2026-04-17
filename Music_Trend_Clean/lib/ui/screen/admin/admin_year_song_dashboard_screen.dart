import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/admin_year_song_form_screen.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';
import 'package:login_flutter/ui/screen/genre/providers/year_song_provider.dart';

class AdminYearSongDashboardScreen extends ConsumerWidget {
  const AdminYearSongDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final songState = ref.watch(yearSongNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n.yearSongAdminTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8C52FF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(yearSongNotifierProvider.notifier).loadSongs(),
          ),
        ],
      ),
      body: _buildBody(context, ref, authState, songState),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8C52FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.addYearSongLabel),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminYearSongFormScreen()),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    SongState songState,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (authState is! AuthSuccess ||
        authState.user.email != 'admin@gmail.com') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.accessDeniedTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.accessDeniedMessage),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.goBack),
            ),
          ],
        ),
      );
    }

    if (songState is SongLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
      );
    }

    if (songState is SongError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(songState.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(yearSongNotifierProvider.notifier).loadSongs(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (songState is SongLoaded) {
      if (songState.songs.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: songState.songs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final song = songState.songs[index];
          final yearLabel = song.savedAt?.year.toString() ?? '';

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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: song.imageUrl.isNotEmpty
                    ? Image.network(
                        song.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholderIcon(),
                      )
                    : _placeholderIcon(),
              ),
              title: Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                yearLabel.isEmpty ? song.artist : '${song.artist} • $yearLabel',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF8C52FF),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminYearSongFormScreen(initialSong: song),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        _confirmDelete(context, ref, song.id, song.title),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
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

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.yearSongEmptyTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.yearSongEmptySubtitle,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String title,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteYearSongConfirmMessage(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(yearSongNotifierProvider.notifier).deleteSong(id);

              if (!context.mounted) {
                return;
              }

              final songState = ref.read(yearSongNotifierProvider);
              if (songState is SongActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.actionSuccessMessage),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                ref.read(yearSongNotifierProvider.notifier).loadSongs();
              } else if (songState is SongError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.errorLabel}: ${songState.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              l10n.deleteLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
