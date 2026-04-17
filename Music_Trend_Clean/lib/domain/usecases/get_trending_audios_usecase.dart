import 'package:login_flutter/domain/entities/audio_entity.dart';
import 'package:login_flutter/domain/repositories/discovery_repository.dart';

class GetTrendingAudiosUseCase {
  final DiscoveryRepository repository;

  GetTrendingAudiosUseCase(this.repository);

  Future<List<AudioEntity>> call() async {
    return repository.getTrendingAudios();
  }
}
