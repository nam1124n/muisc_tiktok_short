import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/data/datasource/remote/audio_generation_remote_data_source.dart';
import 'package:login_flutter/data/repositories/audio_generation_repository_impl.dart';
import 'package:login_flutter/domain/repositories/audio_generation_repository.dart';
import 'package:login_flutter/domain/usecases/generate_audio_usecase.dart';
import 'package:login_flutter/domain/usecases/get_my_songs_usecase.dart';

final audioGenerationRemoteDataSourceProvider =
    Provider<AudioGenerationRemoteDataSource>((ref) {
      return AudioGenerationRemoteDataSource();
    });

final audioGenerationRepositoryProvider = Provider<AudioGenerationRepository>((
  ref,
) {
  return AudioGenerationRepositoryImpl(
    ref.read(audioGenerationRemoteDataSourceProvider),
  );
});

final generateAudioUseCaseProvider = Provider<GenerateAudioUseCase>((ref) {
  return GenerateAudioUseCase(ref.read(audioGenerationRepositoryProvider));
});

final getMySongsUseCaseProvider = Provider<GetMySongsUseCase>((ref) {
  return GetMySongsUseCase(ref.read(audioGenerationRepositoryProvider));
});
