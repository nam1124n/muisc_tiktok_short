import 'package:flutter/foundation.dart';

class AiConfig {
  static List<String> get localBaseUrls {
    final configuredBaseUrls = _splitBaseUrls(
      const String.fromEnvironment('OLLAMA_LOCAL_BASE_URL', defaultValue: ''),
    );
    if (configuredBaseUrls.isNotEmpty) {
      return configuredBaseUrls;
    }

    if (kIsWeb) {
      return const ['http://127.0.0.1:11434/api'];
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => const [
        'http://10.0.2.2:11434/api',
        'http://127.0.0.1:11434/api',
        'http://10.0.3.2:11434/api',
      ],
      _ => const ['http://127.0.0.1:11434/api'],
    };
  }

  static String get localBaseUrl {
    return localBaseUrls.first;
  }

  static String get cloudBaseUrl =>
      const String.fromEnvironment('OLLAMA_CLOUD_BASE_URL', defaultValue: '');

  static String get localModel => const String.fromEnvironment(
    'OLLAMA_LOCAL_MODEL',
    defaultValue: 'llama3:latest',
  );

  static String get cloudModel => const String.fromEnvironment(
    'OLLAMA_CLOUD_MODEL',
    defaultValue: 'gpt-oss:20b-cloud',
  );

  static int get maxPredictTokens =>
      const int.fromEnvironment('OLLAMA_MAX_PREDICT_TOKENS', defaultValue: 64);

  static String get keepAlive =>
      const String.fromEnvironment('OLLAMA_KEEP_ALIVE', defaultValue: '10m');

  static int get timeoutSeconds =>
      const int.fromEnvironment('OLLAMA_TIMEOUT_SECONDS', defaultValue: 60);

  static List<String> _splitBaseUrls(String rawValue) {
    return rawValue
        .split(RegExp(r'[,;\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }
}
