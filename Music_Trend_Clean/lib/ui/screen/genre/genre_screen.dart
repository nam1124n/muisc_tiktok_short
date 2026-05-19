import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/genre/providers/library_song_provider.dart';

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
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _tealSoft = Color(0xFFE6F6F3);
  static const Color _rose = Color(0xFFE11D48);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE2E8F0);

  int? _selectedYear;
  String _selectedAudioType = 'all';
  _LibrarySortOption _sortOption = _LibrarySortOption.newest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    final songState = ref.watch(librarySongCatalogProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          l10n.genreLabel,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _buildContent(
          ref: ref,
          l10n: l10n,
          isVietnamese: isVietnamese,
          songState: songState,
        ),
      ),
    );
  }

  Widget _buildContent({
    required WidgetRef ref,
    required AppLocalizations l10n,
    required bool isVietnamese,
    required LibrarySongCatalogState songState,
  }) {
    if (songState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }

    if (songState.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: _rose),
              const SizedBox(height: 12),
              Text(songState.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(librarySongCatalogProvider.notifier).reload(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final audioFilteredSongs = _filterSongsByAudioType(songState.songs);
    final visibleSongs = _sortSongs(
      _selectedYear == null
          ? audioFilteredSongs
          : audioFilteredSongs
                .where((song) => _bucketYearFor(song) == _selectedYear)
                .toList(),
    );
    final groupedSongs = _groupSongsByYear(visibleSongs);
    final yearsWithSongs = _years.where((year) {
      return audioFilteredSongs.any((song) => _bucketYearFor(song) == year);
    }).length;
    final selectedScopeLabel = _selectedYear == null
        ? (isVietnamese ? 'Tất cả năm' : 'All years')
        : _selectedYear.toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        _LibrarySummaryPanel(
          title: l10n.genreScreenTitle,
          subtitle: l10n.genreScreenSubtitle,
          selectedScopeLabel: selectedScopeLabel,
          totalSongs: songState.songs.length,
          visibleSongs: visibleSongs.length,
          yearsWithSongs: yearsWithSongs,
          totalYears: _years.length,
          isVietnamese: isVietnamese,
        ),
        const SizedBox(height: 16),
        _buildControlPanel(isVietnamese),
        const SizedBox(height: 18),
        if (visibleSongs.isEmpty)
          _EmptyStateCard(
            title: _emptyStateTitle(
              hasSongs: songState.songs.isNotEmpty,
              isVietnamese: isVietnamese,
            ),
            subtitle: _emptyStateSubtitle(
              hasSongs: songState.songs.isNotEmpty,
              isVietnamese: isVietnamese,
            ),
          )
        else if (_selectedYear == null)
          ..._buildGroupedLibrarySections(
            groupedSongs: groupedSongs,
            playlist: visibleSongs,
            isVietnamese: isVietnamese,
          )
        else
          ..._buildSingleYearSection(
            year: _selectedYear!,
            songs: visibleSongs,
            playlist: visibleSongs,
            isVietnamese: isVietnamese,
          ),
      ],
    );
  }

  Widget _buildControlPanel(bool isVietnamese) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: _teal, size: 20),
              const SizedBox(width: 8),
              Text(
                isVietnamese ? 'Bộ lọc thư viện' : 'Library filters',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 148,
                child: DropdownButtonFormField<_LibrarySortOption>(
                  initialValue: _sortOption,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border),
                    ),
                  ),
                  items: _LibrarySortOption.values.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(
                        _sortLabel(option, isVietnamese),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() => _sortOption = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAudioTypeFilter(isVietnamese),
          const SizedBox(height: 14),
          _buildYearFilter(isVietnamese),
        ],
      ),
    );
  }

  Widget _buildAudioTypeFilter(bool isVietnamese) {
    final options = [
      _AudioTypeFilterOption(
        value: 'all',
        label: isVietnamese ? 'Tất cả' : 'All',
      ),
      _AudioTypeFilterOption(
        value: SongAudioTypes.short,
        label: isVietnamese ? 'Nhạc ngắn' : 'Short',
      ),
      _AudioTypeFilterOption(
        value: SongAudioTypes.full,
        label: isVietnamese ? 'Bản đầy đủ' : 'Full',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.value == _selectedAudioType;

        return _FilterChipButton(
          label: option.label,
          selected: isSelected,
          icon: option.value == SongAudioTypes.full
              ? Icons.album_outlined
              : option.value == SongAudioTypes.short
              ? Icons.flash_on_outlined
              : Icons.library_music_outlined,
          onTap: () {
            setState(() => _selectedAudioType = option.value);
          },
        );
      }).toList(),
    );
  }

  Widget _buildYearFilter(bool isVietnamese) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: _years.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final year = index == 0 ? null : _years[index - 1];
          final isSelected = year == _selectedYear;
          final label = year == null
              ? (isVietnamese ? 'Tất cả năm' : 'All years')
              : '$year';

          return _YearChip(
            label: label,
            selected: isSelected,
            onTap: () => setState(() => _selectedYear = year),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedLibrarySections({
    required Map<int, List<SongEntity>> groupedSongs,
    required List<SongEntity> playlist,
    required bool isVietnamese,
  }) {
    final sections = <Widget>[];

    for (final year in _orderedSectionYears()) {
      final songs = groupedSongs[year] ?? const <SongEntity>[];
      if (songs.isEmpty) {
        continue;
      }

      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 18));
      }
      sections.add(_YearSectionHeader(year: year, count: songs.length));
      sections.add(const SizedBox(height: 10));
      sections.addAll(
        songs.map(
          (song) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LibrarySongTile(
              song: song,
              playlist: playlist,
              year: year,
              isVietnamese: isVietnamese,
            ),
          ),
        ),
      );
    }

    return sections;
  }

  List<Widget> _buildSingleYearSection({
    required int year,
    required List<SongEntity> songs,
    required List<SongEntity> playlist,
    required bool isVietnamese,
  }) {
    return [
      _YearSectionHeader(year: year, count: songs.length),
      const SizedBox(height: 10),
      ...songs.map(
        (song) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LibrarySongTile(
            song: song,
            playlist: playlist,
            year: year,
            isVietnamese: isVietnamese,
          ),
        ),
      ),
    ];
  }

  List<SongEntity> _filterSongsByAudioType(List<SongEntity> songs) {
    if (_selectedAudioType == 'all') {
      return songs;
    }

    return songs.where((song) => song.audioType == _selectedAudioType).toList();
  }

  Map<int, List<SongEntity>> _groupSongsByYear(List<SongEntity> songs) {
    final grouped = {for (final year in _years) year: <SongEntity>[]};

    for (final song in songs) {
      grouped[_bucketYearFor(song)]!.add(song);
    }

    return grouped;
  }

  List<SongEntity> _sortSongs(List<SongEntity> songs) {
    final sortedSongs = List<SongEntity>.from(songs);

    sortedSongs.sort((left, right) {
      return switch (_sortOption) {
        _LibrarySortOption.title => left.title.toLowerCase().compareTo(
          right.title.toLowerCase(),
        ),
        _LibrarySortOption.oldest => _compareByYear(left, right),
        _LibrarySortOption.newest => _compareByYear(right, left),
      };
    });

    return sortedSongs;
  }

  int _compareByYear(SongEntity left, SongEntity right) {
    final yearCompare = _bucketYearFor(left).compareTo(_bucketYearFor(right));
    if (yearCompare != 0) {
      return yearCompare;
    }

    final dateCompare = (left.savedAt ?? DateTime(0)).compareTo(
      right.savedAt ?? DateTime(0),
    );
    if (dateCompare != 0) {
      return dateCompare;
    }

    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  }

  int _bucketYearFor(SongEntity song) {
    final savedYear = song.releaseYear ?? song.savedAt?.year;
    if (savedYear != null && _years.contains(savedYear)) {
      return savedYear;
    }

    return _years.first;
  }

  List<int> _orderedSectionYears() {
    if (_sortOption == _LibrarySortOption.oldest) {
      return _years.reversed.toList();
    }

    return _years;
  }

  String _sortLabel(_LibrarySortOption option, bool isVietnamese) {
    return switch (option) {
      _LibrarySortOption.newest => isVietnamese ? 'Mới nhất' : 'Newest',
      _LibrarySortOption.oldest => isVietnamese ? 'Cũ nhất' : 'Oldest',
      _LibrarySortOption.title => 'A-Z',
    };
  }

  String _emptyStateTitle({
    required bool hasSongs,
    required bool isVietnamese,
  }) {
    if (!hasSongs) {
      return isVietnamese ? 'Thư viện đang trống' : 'The library is empty';
    }

    return isVietnamese ? 'Không có bài phù hợp' : 'No matching tracks';
  }

  String _emptyStateSubtitle({
    required bool hasSongs,
    required bool isVietnamese,
  }) {
    if (!hasSongs) {
      return isVietnamese
          ? 'Admin có thể thêm nhạc ngắn hoặc bản đầy đủ vào bộ sưu tập.'
          : 'The admin can add short clips or full tracks to the collection.';
    }

    return isVietnamese
        ? 'Thử đổi loại nhạc, chọn tất cả năm hoặc đổi cách sắp xếp.'
        : 'Try another audio type, all years, or a different sort.';
  }
}

enum _LibrarySortOption { newest, oldest, title }

class _AudioTypeFilterOption {
  const _AudioTypeFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _LibrarySummaryPanel extends StatelessWidget {
  const _LibrarySummaryPanel({
    required this.title,
    required this.subtitle,
    required this.selectedScopeLabel,
    required this.totalSongs,
    required this.visibleSongs,
    required this.yearsWithSongs,
    required this.totalYears,
    required this.isVietnamese,
  });

  final String title;
  final String subtitle;
  final String selectedScopeLabel;
  final int totalSongs;
  final int visibleSongs;
  final int yearsWithSongs;
  final int totalYears;
  final bool isVietnamese;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _GenreScreenState._ink,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
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
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ScopeBadge(label: selectedScopeLabel),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryMetric(
                label: isVietnamese ? 'Đang hiển thị' : 'Visible',
                value: '$visibleSongs',
              ),
              _SummaryMetric(
                label: isVietnamese ? 'Tổng bài' : 'Total tracks',
                value: '$totalSongs',
              ),
              _SummaryMetric(
                label: isVietnamese ? 'Năm có dữ liệu' : 'Active years',
                value: '$yearsWithSongs/$totalYears',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeBadge extends StatelessWidget {
  const _ScopeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _GenreScreenState._teal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _GenreScreenState._tealSoft : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _GenreScreenState._teal
                  : _GenreScreenState._border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? _GenreScreenState._teal
                    : _GenreScreenState._muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? _GenreScreenState._teal
                      : _GenreScreenState._ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _GenreScreenState._ink : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _GenreScreenState._ink
                  : _GenreScreenState._border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _GenreScreenState._ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YearSectionHeader extends StatelessWidget {
  const _YearSectionHeader({required this.year, required this.count});

  final int year;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _GenreScreenState._ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$year',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _GenreScreenState._border)),
        const SizedBox(width: 10),
        Text(
          '$count',
          style: const TextStyle(
            color: _GenreScreenState._muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LibrarySongTile extends ConsumerWidget {
  const _LibrarySongTile({
    required this.song,
    required this.playlist,
    required this.year,
    required this.isVietnamese,
  });

  final SongEntity song;
  final List<SongEntity> playlist;
  final int year;
  final bool isVietnamese;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackForSongProvider(song.id));
    final playerNotifier = ref.read(audioPlayerNotifierProvider.notifier);
    final isCurrentSong = playback.isCurrentSong;
    final isPlaying = playback.isPlaying;
    final isLoading = playback.isLoading;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _GenreScreenState._border),
      ),
      child: Row(
        children: [
          _Artwork(imageUrl: song.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _GenreScreenState._ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _GenreScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _AudioTypeBadge(audioType: song.audioType),
                    _YearBadge(year: year),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PlayButton(
            isPlaying: isPlaying,
            isLoading: isLoading,
            onTap: () async {
              if (isPlaying) {
                playerNotifier.pause();
                return;
              }

              if (isCurrentSong) {
                playerNotifier.resume();
                return;
              }

              await playerNotifier.playSong(song, playlist: playlist);
            },
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPlaying
                ? _GenreScreenState._teal
                : _GenreScreenState._tealSoft,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _GenreScreenState._teal,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isPlaying ? Colors.white : _GenreScreenState._teal,
                    size: 25,
                  ),
          ),
        ),
      ),
    );
  }
}

class _AudioTypeBadge extends StatelessWidget {
  const _AudioTypeBadge({required this.audioType});

  final String audioType;

  @override
  Widget build(BuildContext context) {
    final isFull = audioType == SongAudioTypes.full;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isFull ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFull ? 'FULL' : 'SHORT',
        style: TextStyle(
          color: isFull ? const Color(0xFF1D4ED8) : const Color(0xFFC2410C),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _YearBadge extends StatelessWidget {
  const _YearBadge({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$year',
        style: const TextStyle(
          color: _GenreScreenState._ink,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
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
      child: Icon(
        Icons.music_note_rounded,
        size: 24,
        color: _GenreScreenState._muted,
      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _GenreScreenState._border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _GenreScreenState._tealSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _GenreScreenState._teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _GenreScreenState._ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: _GenreScreenState._muted,
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
