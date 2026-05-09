import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;

  const ProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  final bool requiresAuthentication;

  const ProfileError({
    required this.message,
    this.requiresAuthentication = false,
  });

  @override
  List<Object?> get props => [message, requiresAuthentication];
}
