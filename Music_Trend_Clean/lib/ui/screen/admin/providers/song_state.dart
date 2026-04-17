import 'package:login_flutter/domain/entities/song_entity.dart';

abstract class SongState {}

class SongInitial extends SongState {}

class SongLoading extends SongState {}

class SongLoaded extends SongState {
  final List<SongEntity> songs;
  SongLoaded(this.songs);
}

class SongError extends SongState {
  final String message;
  SongError(this.message);
}

class SongActionSuccess extends SongState {}
