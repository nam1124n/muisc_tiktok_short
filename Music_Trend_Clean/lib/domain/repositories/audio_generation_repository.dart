import 'package:login_flutter/domain/entities/generated_audio_entity.dart';

abstract class AudioGenerationRepository {
  Future<GeneratedAudioEntity> generateAudio({
    required String userId,
    required String prompt,
    required int durationSeconds,
  });

  Future<List<GeneratedAudioEntity>> getMySongs({required String userId});
}
