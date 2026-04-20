import 'package:flutter/foundation.dart';

class AudioGenerationConfig {
  static const String _baseUrlEnvKey = 'AUDIO_GENERATION_BASE_URL';
  static const String _localhostBaseUrl = 'http://127.0.0.1:4000';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:4000';

  static String get baseUrl {
    const configuredUrl = String.fromEnvironment(_baseUrlEnvKey);
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (kIsWeb) {
      return _localhostBaseUrl;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidEmulatorBaseUrl,
      _ => _localhostBaseUrl,
    };
  }

  static String? get androidDeviceSetupHint {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    const configuredUrl = String.fromEnvironment(_baseUrlEnvKey);
    if (configuredUrl.isNotEmpty) {
      return null;
    }

    return 'Android đang dùng $_androidEmulatorBaseUrl. '
        'Địa chỉ này chỉ truy cập được từ Android emulator. '
        'Nếu chạy trên điện thoại thật, hãy truyền '
        '--dart-define=$_baseUrlEnvKey=http://<IP_LAN_MAY_TINH>:4000 '
        'hoặc dùng URL public của backend.';
  }

  static String buildTimeoutMessage(String baseUrl) {
    final normalizedBaseUrl = _normalize(baseUrl);

    if (normalizedBaseUrl.startsWith(_androidEmulatorBaseUrl)) {
      return 'Kết nối backend bị timeout sau ${timeoutSeconds}s. '
          '$_androidEmulatorBaseUrl chỉ dùng cho Android emulator. '
          'Nếu đang chạy trên điện thoại thật, hãy đổi $_baseUrlEnvKey '
          'sang IP nội bộ của máy đang chạy backend, ví dụ '
          'http://192.168.1.10:4000.';
    }

    if (_isLoopbackUrl(normalizedBaseUrl)) {
      return 'Kết nối backend bị timeout sau ${timeoutSeconds}s. '
          'Thiết bị hiện không truy cập được $normalizedBaseUrl. '
          'Nếu backend đang chạy trên máy tính khác, hãy đổi $_baseUrlEnvKey '
          'sang IP nội bộ hoặc URL public của backend.';
    }

    return 'Kết nối backend bị timeout sau ${timeoutSeconds}s. '
        'Kiểm tra backend đang chạy và thiết bị có truy cập được $normalizedBaseUrl.';
  }

  static String buildConnectionErrorMessage(String baseUrl, {String? details}) {
    final normalizedBaseUrl = _normalize(baseUrl);
    final detailMessage = details == null || details.trim().isEmpty
        ? ''
        : ' Chi tiết: $details';

    if (normalizedBaseUrl.startsWith(_androidEmulatorBaseUrl)) {
      return 'Không kết nối được tới backend $normalizedBaseUrl. '
          '$_androidEmulatorBaseUrl chỉ dùng cho Android emulator. '
          'Nếu đang chạy trên điện thoại thật, hãy đổi $_baseUrlEnvKey '
          'sang IP nội bộ hoặc URL public của backend.$detailMessage';
    }

    return 'Không kết nối được tới backend $normalizedBaseUrl. '
        'Kiểm tra backend đang chạy và thiết bị truy cập được địa chỉ này.'
        '$detailMessage';
  }

  static const String generatePath = '/api/generate';
  static const String generationsPath = '/api/generations';
  static const String mySongsPath = '/api/my-songs';

  static const int timeoutSeconds = 30;
  static const int pendingRefreshIntervalSeconds = 10;

  static bool _isLoopbackUrl(String value) {
    return value.startsWith(_localhostBaseUrl) ||
        value.startsWith('http://localhost') ||
        value.startsWith('https://localhost');
  }

  static String _normalize(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
