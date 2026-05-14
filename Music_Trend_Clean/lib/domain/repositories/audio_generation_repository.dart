import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';

abstract class AudioGenerationRepository {
  Future<GeneratedAudioTaskEntity> generateAudio({
    required String userId,
    required String prompt,
  });
}
