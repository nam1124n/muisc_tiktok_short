import 'package:login_flutter/domain/entities/audio_entity.dart';

abstract class DiscoveryRepository {
  Future<List<AudioEntity>> getTrendingAudios();
  Future<List<AudioEntity>> getForYouAudios();
}
