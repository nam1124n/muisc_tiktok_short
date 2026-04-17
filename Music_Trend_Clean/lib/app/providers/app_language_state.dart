import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/app_language_entity.dart';

abstract class AppLanguageState extends Equatable {
  const AppLanguageState();

  @override
  List<Object?> get props => [];
}

class AppLanguageInitial extends AppLanguageState {}

class AppLanguageLoaded extends AppLanguageState {
  final AppLanguageEntity language;

  const AppLanguageLoaded({required this.language});

  @override
  List<Object?> get props => [language];
}

class AppLanguageError extends AppLanguageState {
  final String message;

  const AppLanguageError({required this.message});

  @override
  List<Object?> get props => [message];
}
