import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';

enum CreateAudioStatus { initial, loading, success, error }

class CreateAudioState {
  final String prompt;
  final CreateAudioStatus status;
  final GeneratedAudioTaskEntity? generatedTask;
  final String? errorMessage;

  const CreateAudioState({
    this.prompt = '',
    this.status = CreateAudioStatus.initial,
    this.generatedTask,
    this.errorMessage,
  });

  CreateAudioState copyWith({
    String? prompt,
    CreateAudioStatus? status,
    GeneratedAudioTaskEntity? generatedTask,
    bool clearGeneratedTask = false,
    String? errorMessage,
  }) {
    return CreateAudioState(
      prompt: prompt ?? this.prompt,
      status: status ?? this.status,
      generatedTask: clearGeneratedTask
          ? null
          : (generatedTask ?? this.generatedTask),
      errorMessage: errorMessage,
    );
  }
}
