import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/repositories/audio_generation_repository.dart';

class GenerateAudioUseCase {
  final AudioGenerationRepository repository;

  GenerateAudioUseCase(this.repository);

  Future<GeneratedAudioEntity> call({
    required String userId,
    required String prompt,
    required int durationSeconds,
  }) {
    return repository.generateAudio(
      userId: userId,
      prompt: prompt,
      durationSeconds: durationSeconds,
    );
  }
}
