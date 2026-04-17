class AudioGenerationConfig {
  static const String baseUrl = String.fromEnvironment(
    'AUDIO_GENERATION_BASE_URL',
    defaultValue: 'mock://audio-generator',
  );

  static const String generatePath = '/api/generate';
  static const String generationsPath = '/api/generations';
  static const String mySongsPath = '/api/my-songs';

  static const int timeoutSeconds = 30;
  static const int pendingRefreshIntervalSeconds = 10;
}
