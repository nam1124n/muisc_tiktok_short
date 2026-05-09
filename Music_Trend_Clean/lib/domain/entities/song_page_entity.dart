import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

class SongPageCursor extends Equatable {
  const SongPageCursor({required this.title, required this.id});

  final String title;
  final String id;

  @override
  List<Object?> get props => [title, id];
}

class SongPageEntity extends Equatable {
  const SongPageEntity({
    required this.songs,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<SongEntity> songs;
  final SongPageCursor? nextCursor;
  final bool hasMore;

  @override
  List<Object?> get props => [songs, nextCursor, hasMore];
}
