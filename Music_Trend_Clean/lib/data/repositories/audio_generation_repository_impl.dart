import 'package:login_flutter/app/config/audio_generation_config.dart';
import 'package:login_flutter/data/datasource/remote/audio_generation_remote_data_source.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_task_model.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/domain/repositories/audio_generation_repository.dart';

class AudioGenerationRepositoryImpl implements AudioGenerationRepository {
  final AudioGenerationRemoteDataSource remoteDataSource;
  final String baseUrl;

  AudioGenerationRepositoryImpl(this.remoteDataSource, {String? baseUrl})
    : baseUrl = baseUrl ?? AudioGenerationConfig.baseUrl;

  @override
  Future<GeneratedAudioTaskEntity> generateAudio({
    required String userId,
    required String prompt,
  }) async {
    if (baseUrl.startsWith('mock://')) {
      return remoteDataSource.generateMockAudioTask(
        userId: userId,
        prompt: prompt,
      );
    }

    final response = await remoteDataSource.createGeneration(
      baseUrl: baseUrl,
      userId: userId,
      prompt: prompt,
    );
    final generationId =
        response['taskId']?.toString() ?? response['task_id']?.toString() ?? '';

    if (generationId.isEmpty) {
      throw Exception('Backend không trả về generation id hợp lệ.');
    }

    final now = DateTime.now().toUtc();

    return GeneratedAudioTaskModel(
      id: generationId,
      userId: userId,
      prompt: prompt,
      status: response['status']?.toString() ?? 'processing',
      provider: 'phoenix-backend',
      outputCount:
          (response['outputCount'] as num?)?.toInt() ??
          (response['output_count'] as num?)?.toInt() ??
          2,
      tracks: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<List<GeneratedAudioTaskEntity>> getMySongs({
    required String userId,
  }) async {
    if (baseUrl.startsWith('mock://')) {
      return const [];
    }

    return remoteDataSource.getMySongs(baseUrl: baseUrl, userId: userId);
  }
}
