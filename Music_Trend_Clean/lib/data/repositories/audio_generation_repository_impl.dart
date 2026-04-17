import 'package:login_flutter/app/config/audio_generation_config.dart';
import 'package:login_flutter/data/datasource/remote/audio_generation_remote_data_source.dart';
import 'package:login_flutter/data/dto/audio_generation/generated_audio_model.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/repositories/audio_generation_repository.dart';

class AudioGenerationRepositoryImpl implements AudioGenerationRepository {
  final AudioGenerationRemoteDataSource remoteDataSource;
  final String baseUrl;

  AudioGenerationRepositoryImpl(this.remoteDataSource, {String? baseUrl})
    : baseUrl = baseUrl ?? AudioGenerationConfig.baseUrl;

  @override
  Future<GeneratedAudioEntity> generateAudio({
    required String userId,
    required String prompt,
    required int durationSeconds,
  }) async {
    if (baseUrl.startsWith('mock://')) {
      return remoteDataSource.generateMockAudio(
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
    }

    final generationId = await remoteDataSource.createGeneration(
      baseUrl: baseUrl,
      userId: userId,
      prompt: prompt,
      durationSeconds: durationSeconds,
    );

    for (
      var attempt = 0;
      attempt < AudioGenerationConfig.maxPollAttempts;
      attempt++
    ) {
      final payload = await remoteDataSource.getGeneration(
        baseUrl: baseUrl,
        generationId: generationId,
      );

      final status = payload['status']?.toString() ?? '';

      if (status == 'completed') {
        return GeneratedAudioModel.fromJson(payload);
      }

      if (status != 'processing') {
        throw Exception('Generation thất bại với trạng thái: $status');
      }

      await Future<void>.delayed(
        Duration(seconds: AudioGenerationConfig.pollIntervalSeconds),
      );
    }

    throw Exception('Tạo audio quá lâu, vui lòng thử lại.');
  }

  @override
  Future<List<GeneratedAudioEntity>> getMySongs({
    required String userId,
  }) async {
    if (baseUrl.startsWith('mock://')) {
      return const [];
    }

    return remoteDataSource.getMySongs(baseUrl: baseUrl, userId: userId);
  }
}
