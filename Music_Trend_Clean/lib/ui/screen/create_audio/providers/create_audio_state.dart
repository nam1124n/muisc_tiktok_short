import 'package:login_flutter/domain/entities/generated_audio_entity.dart';

enum CreateAudioStatus { initial, loading, success, error }

class CreateAudioState {
  final String prompt;
  final int durationSeconds;
  final CreateAudioStatus status;
  final GeneratedAudioEntity? generatedAudio;
  final String? errorMessage;

  const CreateAudioState({
    this.prompt = '',
    this.durationSeconds = 30,
    this.status = CreateAudioStatus.initial,
    this.generatedAudio,
    this.errorMessage,
  });

  CreateAudioState copyWith({
    String? prompt,
    int? durationSeconds,
    CreateAudioStatus? status,
    GeneratedAudioEntity? generatedAudio,
    bool clearGeneratedAudio = false,
    String? errorMessage,
  }) {
    return CreateAudioState(
      prompt: prompt ?? this.prompt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      generatedAudio: clearGeneratedAudio
          ? null
          : (generatedAudio ?? this.generatedAudio),
      errorMessage: errorMessage,
    );
  }
}
