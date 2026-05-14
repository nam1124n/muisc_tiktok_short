import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _appEnvironmentEnvKey = 'APP_ENVIRONMENT';
  static const String _adminEmailEnvKey = 'ADMIN_EMAIL';
  static const String _cloudinaryCloudNameEnvKey = 'CLOUDINARY_CLOUD_NAME';
  static const String _cloudinaryUploadPresetEnvKey =
      'CLOUDINARY_UPLOAD_PRESET';
  static const String _profileShareBaseUrlEnvKey = 'PROFILE_SHARE_BASE_URL';
  static const String _audioGenerationWorkerUrlEnvKey =
      'AUDIO_GENERATION_WORKER_URL';

  static const String _defaultEnvironment = 'development';
  static const String _defaultAdminEmail = 'admin@gmail.com';
  static const String _defaultCloudinaryCloudName = 'ddy9wgrbj';
  static const String _defaultCloudinaryUploadPreset = 'musicapp';
  static const String _defaultProfileShareBaseUrl =
      'https://musictrend.app/profile';
  static const String _localhostAudioGenerationWorkerUrl =
      'http://127.0.0.1:8787';
  static const String _androidAudioGenerationWorkerUrl = 'http://10.0.2.2:8787';

  static const int audioGenerationRequestTimeoutSeconds = 30;
  static const int audioGenerationPendingRefreshIntervalSeconds = 10;

  static String get environment {
    const configuredEnvironment = String.fromEnvironment(_appEnvironmentEnvKey);

    if (configuredEnvironment.isEmpty) {
      return _defaultEnvironment;
    }

    return configuredEnvironment.trim().toLowerCase();
  }

  static bool get isProduction => environment == 'production';

  static bool get isStaging => environment == 'staging';

  static bool get isDevelopment => !isProduction && !isStaging;

  static String get adminEmail {
    const configuredAdminEmail = String.fromEnvironment(_adminEmailEnvKey);

    if (configuredAdminEmail.isEmpty) {
      return _defaultAdminEmail;
    }

    return configuredAdminEmail.trim().toLowerCase();
  }

  static bool isAdminEmail(String? email) {
    return (email ?? '').trim().toLowerCase() == adminEmail;
  }

  static String get cloudinaryCloudName {
    const configuredCloudName = String.fromEnvironment(
      _cloudinaryCloudNameEnvKey,
    );

    if (configuredCloudName.isEmpty) {
      return _defaultCloudinaryCloudName;
    }

    return configuredCloudName.trim();
  }

  static String get cloudinaryUploadPreset {
    const configuredUploadPreset = String.fromEnvironment(
      _cloudinaryUploadPresetEnvKey,
    );

    if (configuredUploadPreset.isEmpty) {
      return _defaultCloudinaryUploadPreset;
    }

    return configuredUploadPreset.trim();
  }

  static String get profileShareBaseUrl {
    const configuredBaseUrl = String.fromEnvironment(
      _profileShareBaseUrlEnvKey,
    );

    if (configuredBaseUrl.isEmpty) {
      return _defaultProfileShareBaseUrl;
    }

    return configuredBaseUrl.trim();
  }

  static String get audioGenerationWorkerBaseUrl {
    const configuredUrl = String.fromEnvironment(
      _audioGenerationWorkerUrlEnvKey,
    );

    if (configuredUrl.isNotEmpty) {
      return _normalizeBaseUrl(configuredUrl);
    }

    if (kIsWeb) {
      return _localhostAudioGenerationWorkerUrl;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidAudioGenerationWorkerUrl,
      _ => _localhostAudioGenerationWorkerUrl,
    };
  }

  static String buildAudioGenerationTimeoutMessage(String baseUrl) {
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);

    return 'Kết nối Worker bị timeout sau '
        '${audioGenerationRequestTimeoutSeconds}s. '
        'Kiểm tra Worker đang chạy và thiết bị truy cập được '
        '$normalizedBaseUrl.';
  }

  static String buildAudioGenerationConnectionErrorMessage(
    String baseUrl, {
    String? details,
  }) {
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    final detailMessage = details == null || details.trim().isEmpty
        ? ''
        : ' Chi tiết: $details';

    return 'Không kết nối được tới Worker $normalizedBaseUrl. '
        'Nếu chạy trên điện thoại thật, truyền '
        '--dart-define=$_audioGenerationWorkerUrlEnvKey=<WORKER_URL>.'
        '$detailMessage';
  }

  static String buildPublicProfileUrl(String profileId) {
    final trimmedBaseUrl = _normalizeBaseUrl(profileShareBaseUrl);
    final trimmedProfileId = profileId.trim();
    return '$trimmedBaseUrl/$trimmedProfileId';
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
