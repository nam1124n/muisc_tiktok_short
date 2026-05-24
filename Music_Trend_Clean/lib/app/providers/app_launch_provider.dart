import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/app_language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hasCompletedOnboardingKey = 'has_completed_onboarding';

final appLaunchProvider =
    StateNotifierProvider<AppLaunchNotifier, AppLaunchState>((ref) {
      return AppLaunchNotifier(
        sharedPreferences: ref.read(sharedPreferencesProvider),
      );
    });

enum AppLaunchDestination { loading, onboarding, app }

AppLaunchDestination resolveAppLaunchDestination(AppLaunchState state) {
  if (state.isLoading) {
    return AppLaunchDestination.loading;
  }

  return state.hasCompletedOnboarding
      ? AppLaunchDestination.app
      : AppLaunchDestination.onboarding;
}

class AppLaunchState extends Equatable {
  const AppLaunchState({
    required this.isLoading,
    required this.hasCompletedOnboarding,
  });

  const AppLaunchState.loading()
    : this(isLoading: true, hasCompletedOnboarding: false);

  final bool isLoading;
  final bool hasCompletedOnboarding;

  AppLaunchState copyWith({bool? isLoading, bool? hasCompletedOnboarding}) {
    return AppLaunchState(
      isLoading: isLoading ?? this.isLoading,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  List<Object?> get props => [isLoading, hasCompletedOnboarding];
}

class AppLaunchNotifier extends StateNotifier<AppLaunchState> {
  AppLaunchNotifier({required this.sharedPreferences})
    : super(const AppLaunchState.loading()) {
    load();
  }

  final SharedPreferences sharedPreferences;

  Future<void> load() async {
    final hasCompletedOnboarding =
        sharedPreferences.getBool(_hasCompletedOnboardingKey) ?? false;
    state = state.copyWith(
      isLoading: false,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  Future<void> completeOnboarding() async {
    await sharedPreferences.setBool(_hasCompletedOnboardingKey, true);
    state = state.copyWith(isLoading: false, hasCompletedOnboarding: true);
  }
}
