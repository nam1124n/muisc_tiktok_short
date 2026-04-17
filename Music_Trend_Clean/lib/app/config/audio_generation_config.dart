class AudioGenerationConfig {
  static const String baseUrl = String.fromEnvironment(
    'AUDIO_GENERATION_BASE_URL',
    defaultValue: 'mock://audio-generator',
  );

  static const String generatePath = '/api/generate';
  static const String generationsPath = '/api/generations';
  static const String mySongsPath = '/api/my-songs';

  static const int timeoutSeconds = 45;
  static const int pollIntervalSeconds = 2;
  static const int maxPollAttempts = 15;
}
