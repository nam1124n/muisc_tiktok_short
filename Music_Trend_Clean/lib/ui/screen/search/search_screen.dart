import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';
import 'package:login_flutter/ui/screen/search/providers/search_provider.dart';
import 'package:login_flutter/ui/screen/search/providers/search_state.dart';
import 'package:login_flutter/ui/screen/search/widgets/search_info_card.dart';
import 'package:login_flutter/ui/screen/search/widgets/search_result_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value, List<SongEntity> songs) {
    ref
        .read(searchNotifierProvider.notifier)
        .search(query: value, songs: songs);
  }

  @override
  Widget build(BuildContext context) {
    final songState = ref.watch(songNotifierProvider);
    final searchState = ref.watch(searchNotifierProvider);
    final songs = songState is SongLoaded ? songState.songs : <SongEntity>[];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchLabel)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onChanged: (value) => _onQueryChanged(value, songs),
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildContent(context, searchState, songState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SearchState searchState,
    SongState songState,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (songState is SongLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (songState is SongError) {
      return Center(child: Text(songState.message));
    }

    if (searchState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.hasError) {
      return Center(child: Text(searchState.errorMessage!));
    }

    if (searchState.isEmpty && searchState.plan != null) {
      return Column(
        children: [
          SearchInfoCard(plan: searchState.plan!),
          const SizedBox(height: 16),
          Expanded(child: Center(child: Text(l10n.noMatchingSongs))),
        ],
      );
    }

    if (searchState.hasResults && searchState.plan != null) {
      return Column(
        children: [
          SearchInfoCard(plan: searchState.plan!),
          const SizedBox(height: 12),
          Expanded(child: _buildResultsList(searchState.results)),
        ],
      );
    }

    return Center(child: Text(l10n.enterSearchPrompt));
  }

  Widget _buildResultsList(List<SongEntity> results) {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final song = results[index];
        return SearchResultTile(
          song: song,
          onTap: () {
            ref
                .read(audioPlayerNotifierProvider.notifier)
                .playSong(song, playlist: results);
            ref.read(recentNotifierProvider.notifier).addRecent(song);
          },
        );
      },
    );
  }
}
