import 'package:login_flutter/domain/entities/generated_audio_entity.dart';

abstract class AdminGeneratedAudioState {}

class AdminGeneratedAudioLoading extends AdminGeneratedAudioState {}

class AdminGeneratedAudioLoaded extends AdminGeneratedAudioState {
  final List<GeneratedAudioEntity> tracks;

  AdminGeneratedAudioLoaded(this.tracks);
}

class AdminGeneratedAudioError extends AdminGeneratedAudioState {
  final String message;

  AdminGeneratedAudioError(this.message);
}
