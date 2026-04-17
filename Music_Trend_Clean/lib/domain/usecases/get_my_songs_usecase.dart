import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/repositories/audio_generation_repository.dart';

class GetMySongsUseCase {
  final AudioGenerationRepository repository;

  GetMySongsUseCase(this.repository);

  Future<List<GeneratedAudioEntity>> call({required String userId}) {
    return repository.getMySongs(userId: userId);
  }
}
