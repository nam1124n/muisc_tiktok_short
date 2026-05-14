import 'package:login_flutter/data/datasource/remote/audio_generation_remote_data_source.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/domain/repositories/audio_generation_repository.dart';

class AudioGenerationRepositoryImpl implements AudioGenerationRepository {
  final AudioGenerationRemoteDataSource remoteDataSource;

  AudioGenerationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<GeneratedAudioTaskEntity> generateAudio({
    required String userId,
    required String prompt,
  }) async {
    return remoteDataSource.generateAudioTask(userId: userId, prompt: prompt);
  }
}
