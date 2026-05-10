class AppConfig {
  static const String _appEnvironmentEnvKey = 'APP_ENVIRONMENT';
  static const String _adminEmailEnvKey = 'ADMIN_EMAIL';
  static const String _cloudinaryCloudNameEnvKey = 'CLOUDINARY_CLOUD_NAME';
  static const String _cloudinaryUploadPresetEnvKey =
      'CLOUDINARY_UPLOAD_PRESET';
  static const String _profileShareBaseUrlEnvKey = 'PROFILE_SHARE_BASE_URL';

  static const String _defaultEnvironment = 'development';
  static const String _defaultAdminEmail = 'admin@gmail.com';
  static const String _defaultCloudinaryCloudName = 'ddy9wgrbj';
  static const String _defaultCloudinaryUploadPreset = 'musicapp';
  static const String _defaultProfileShareBaseUrl =
      'https://musictrend.app/profile';

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

  static String buildPublicProfileUrl(String profileId) {
    final trimmedBaseUrl = profileShareBaseUrl.replaceAll(RegExp(r'/$'), '');
    final trimmedProfileId = profileId.trim();
    return '$trimmedBaseUrl/$trimmedProfileId';
  }
}
