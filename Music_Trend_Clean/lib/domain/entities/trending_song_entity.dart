import 'package:login_flutter/domain/entities/song_entity.dart';

class TrendingSongEntity {
  final SongEntity song;
  final int uniqueUserCount;
  final int totalPlayCount;

  const TrendingSongEntity({
    required this.song,
    required this.uniqueUserCount,
    required this.totalPlayCount,
  });
}
