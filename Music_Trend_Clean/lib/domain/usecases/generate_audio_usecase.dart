import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/domain/repositories/audio_generation_repository.dart';

class GenerateAudioUseCase {
  final AudioGenerationRepository repository;

  GenerateAudioUseCase(this.repository);

  Future<GeneratedAudioTaskEntity> call({
    required String userId,
    required String prompt,
  }) {
    return repository.generateAudio(userId: userId, prompt: prompt);
  }
}
