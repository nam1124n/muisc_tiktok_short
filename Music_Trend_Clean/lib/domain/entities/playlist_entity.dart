import 'package:equatable/equatable.dart';

class PlaylistEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final List<String> songIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlaylistEntity({
    required this.id,
    required this.name,
    this.description = '',
    required this.coverUrl,
    this.songIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get trackCount => songIds.length;

  PlaylistEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    coverUrl,
    songIds,
    createdAt,
    updatedAt,
  ];
}
