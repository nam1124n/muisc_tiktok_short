import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_state.dart';
import 'package:login_flutter/ui/screen/genre/providers/year_song_provider.dart';

class GenreScreen extends ConsumerStatefulWidget {
  const GenreScreen({super.key});

  @override
  ConsumerState<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends ConsumerState<GenreScreen> {
  static final List<int> _years = List<int>.generate(
    9,
    (index) => 2026 - index,
  );
  static const Color _purple = Color(0xFF7B43F3);
  static const Color _purpleDark = Color(0xFF4C1D95);
  static const Color _background = Color(0xFFF7F2FF);

  int _selectedYear = _years.first;
  bool _didSelectYear = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    final yearSongState = ref.watch(yearSongNotifierProvider);
    final playerState = ref.watch(audioPlayerNotifierProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          l10n.genreLabel,
          style: const TextStyle(
            color: Color(0xFF1F1147),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F4FF), Color(0xFFF4EEFF), Color(0xFFFDFBFF)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -20,
              child: _GlowOrb(
                size: 210,
                color: Color(0xFFD8C1FF),
                opacity: 0.5,
              ),
            ),
            const Positioned(
              top: 160,
              left: -50,
              child: _GlowOrb(
                size: 170,
                color: Color(0xFFEADBFF),
                opacity: 0.55,
              ),
            ),
            SafeArea(
              top: false,
              child: _buildContent(
                context: context,
                ref: ref,
                l10n: l10n,
                isVietnamese: isVietnamese,
                songState: yearSongState,
                playerState: playerState,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required bool isVietnamese,
    required SongState songState,
    required AudioPlayerState playerState,
  }) {
    if (songState is SongLoading || songState is SongInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B43F3)),
      );
    }

    if (songState is SongError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 12),
              Text(songState.message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(yearSongNotifierProvider.notifier).loadSongs(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final songs = songState is SongLoaded
        ? songState.songs
        : const <SongEntity>[];
    final songsByYear = _groupSongsByYear(songs);
    final autoSelectedYear = _preferredYear(songsByYear);
    final selectedYear = _didSelectYear ? _selectedYear : autoSelectedYear;
    final selectedSongs = songsByYear[selectedYear] ?? const <SongEntity>[];
    final yearsWithSongs = _years
        .where((year) => (songsByYear[year] ?? const []).isNotEmpty)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _HeaderCard(
          title: l10n.genreScreenTitle,
          subtitle: l10n.genreScreenSubtitle,
          selectedYear: selectedYear,
          totalSongs: songs.length,
          yearsWithMemories: yearsWithSongs,
          totalYears: _years.length,
          isVietnamese: isVietnamese,
        ),
        const SizedBox(height: 22),
        _buildYearTabs(selectedYear),
        const SizedBox(height: 20),
        _SectionHeader(
          title: _yearListTitle(selectedYear, isVietnamese),
          subtitle: _yearListSubtitle(
            selectedYear: selectedYear,
            songCount: selectedSongs.length,
            hasSongs: songs.isNotEmpty,
            isVietnamese: isVietnamese,
          ),
        ),
        const SizedBox(height: 14),
        if (selectedSongs.isEmpty)
          _EmptyStateCard(
            title: _emptyStateTitle(
              hasSongs: songs.isNotEmpty,
              selectedYear: selectedYear,
              isVietnamese: isVietnamese,
            ),
            subtitle: _emptyStateSubtitle(
              hasSongs: songs.isNotEmpty,
              isVietnamese: isVietnamese,
            ),
          )
        else
          ...selectedSongs.map(
            (song) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SongMemoryCard(
                song: song,
                note: _memoryNote(selectedYear, isVietnamese),
                isPlaying:
                    playerState.currentSong?.id == song.id &&
                    playerState.isPlaying,
                isLoading:
                    playerState.currentSong?.id == song.id &&
                    playerState.isLoading,
                onPlayPressed: () =>
                    _handlePlayAction(song: song, playlist: selectedSongs),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYearTabs(int selectedYear) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: _years.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final year = _years[index];
          final isSelected = year == selectedYear;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _selectedYear = year;
                  _didSelectYear = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _purple
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFE8DDFB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? _purple.withValues(alpha: 0.26)
                          : const Color(0xFF2B145F).withValues(alpha: 0.04),
                      blurRadius: isSelected ? 24 : 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$year',
                    style: TextStyle(
                      color: isSelected ? Colors.white : _purpleDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePlayAction({
    required SongEntity song,
    required List<SongEntity> playlist,
  }) async {
    final playerState = ref.read(audioPlayerNotifierProvider);
    final playerNotifier = ref.read(audioPlayerNotifierProvider.notifier);

    if (playerState.currentSong?.id == song.id) {
      if (playerState.isPlaying) {
        playerNotifier.pause();
      } else {
        playerNotifier.resume();
      }
      return;
    }

    await playerNotifier.playSong(song, playlist: playlist);
  }

  Map<int, List<SongEntity>> _groupSongsByYear(List<SongEntity> songs) {
    final grouped = {for (final year in _years) year: <SongEntity>[]};

    for (final song in songs) {
      final year = _bucketYearFor(song);
      grouped[year]!.add(song);
    }

    return grouped;
  }

  int _preferredYear(Map<int, List<SongEntity>> songsByYear) {
    for (final year in _years) {
      if ((songsByYear[year] ?? const []).isNotEmpty) {
        return year;
      }
    }

    return _years.first;
  }

  int _bucketYearFor(SongEntity song) {
    final savedYear = song.savedAt?.year;
    if (savedYear != null && _years.contains(savedYear)) {
      return savedYear;
    }

    // Keep legacy or newer records visible inside the archive even when
    // they do not expose one of the fixed design years.
    return _years.first;
  }

  String _yearListTitle(int year, bool isVietnamese) {
    return isVietnamese
        ? 'Những bài gợi nhớ $year'
        : 'Tracks that bring back $year';
  }

  String _yearListSubtitle({
    required int selectedYear,
    required int songCount,
    required bool hasSongs,
    required bool isVietnamese,
  }) {
    if (!hasSongs) {
      return isVietnamese
          ? 'Kho nhạc theo năm sẽ hiện ở đây sau khi admin thêm dữ liệu.'
          : 'The by-year archive will appear here after the admin adds songs.';
    }

    if (songCount == 0) {
      return isVietnamese
          ? 'Chưa có bài nào được gắn với năm $selectedYear.'
          : 'No songs are assigned to $selectedYear yet.';
    }

    return isVietnamese
        ? '$songCount bài đang được xếp vào mốc năm $selectedYear.'
        : '$songCount tracks are currently grouped under $selectedYear.';
  }

  String _emptyStateTitle({
    required bool hasSongs,
    required int selectedYear,
    required bool isVietnamese,
  }) {
    if (!hasSongs) {
      return isVietnamese
          ? 'Kho nhạc theo năm đang trống'
          : 'The by-year archive is empty';
    }

    return isVietnamese
        ? 'Năm $selectedYear chưa có bài nào'
        : '$selectedYear does not have any songs yet';
  }

  String _emptyStateSubtitle({
    required bool hasSongs,
    required bool isVietnamese,
  }) {
    if (!hasSongs) {
      return isVietnamese
          ? 'Admin có thể thêm nhạc ngắn theo từng năm từ 2018 đến 2026.'
          : 'The admin can add short tracks for each year from 2018 to 2026.';
    }

    return isVietnamese
        ? 'Thử chuyển sang một năm khác để nghe lại những bài đã được lưu.'
        : 'Try another year tab to revisit the tracks already archived.';
  }

  String _memoryNote(int selectedYear, bool isVietnamese) {
    return isVietnamese
        ? 'Một đoạn nhạc ngắn gợi lại không khí của $selectedYear.'
        : 'A short track that brings back the feel of $selectedYear.';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.selectedYear,
    required this.totalSongs,
    required this.yearsWithMemories,
    required this.totalYears,
    required this.isVietnamese,
  });

  final String title;
  final String subtitle;
  final int selectedYear;
  final int totalSongs;
  final int yearsWithMemories;
  final int totalYears;
  final bool isVietnamese;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6F3AF2), Color(0xFF9A76FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F3AF2).withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  '$selectedYear',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(
                label: isVietnamese ? 'Bài hiện có' : 'Tracks available',
                value: '$totalSongs',
              ),
              _StatChip(
                label: isVietnamese ? 'Năm có dữ liệu' : 'Active years',
                value: '$yearsWithMemories/$totalYears',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1147),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF6E5A9A),
          ),
        ),
      ],
    );
  }
}

class _SongMemoryCard extends StatelessWidget {
  const _SongMemoryCard({
    required this.song,
    required this.note,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPressed,
  });

  final SongEntity song;
  final String note;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8DDFB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF220B52).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _Artwork(imageUrl: song.imageUrl),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF23124F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7B43F3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF7B6B9A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPlayPressed,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPlaying
                      ? const Color(0xFF5B21B6)
                      : const Color(0xFFF1E8FF),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7B43F3),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 26,
                          color: isPlaying
                              ? Colors.white
                              : const Color(0xFF7B43F3),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.imageUrl});

  final String imageUrl;

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
          colors: [Color(0xFF6F3AF2), Color(0xFFC4A6FF)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ArtworkPlaceholder(),
            )
          : const _ArtworkPlaceholder(),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.music_note_rounded, size: 28, color: Colors.white),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8DDFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFF7B43F3),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF23124F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF6E5A9A),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
