import 'package:equatable/equatable.dart';

class AppLanguageEntity extends Equatable {
  final String languageCode;
  const AppLanguageEntity({required this.languageCode});

  static const String english = 'en';
  static const String vietnamese = 'vi';

  static bool isSupported(String code) {
    return code == english || code == vietnamese;
  }

  AppLanguageEntity copyWith({String? languageCode}) {
    return AppLanguageEntity(languageCode: languageCode ?? this.languageCode);
  }

  @override
  List<Object?> get props => [languageCode];
}
