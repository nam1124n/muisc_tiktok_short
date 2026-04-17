import 'package:flutter/material.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

class SearchResultTile extends StatelessWidget {
  final SongEntity song;
  final VoidCallback onTap;

  const SearchResultTile({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: song.imageUrl.isNotEmpty
            ? Image.network(
                song.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.music_note),
              )
            : const Icon(Icons.music_note),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.play_circle_outline),
      onTap: onTap,
    );
  }
}
