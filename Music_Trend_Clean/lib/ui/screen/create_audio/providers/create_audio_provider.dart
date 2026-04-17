import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/audio_generation_provider.dart';
import 'package:login_flutter/domain/usecases/generate_audio_usecase.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';
import 'package:login_flutter/ui/screen/create_audio/providers/create_audio_state.dart';
import 'package:login_flutter/ui/screen/my_audios/providers/my_audios_provider.dart';

final createAudioNotifierProvider =
    StateNotifierProvider.autoDispose<CreateAudioNotifier, CreateAudioState>((
      ref,
    ) {
      return CreateAudioNotifier(
        ref.read(generateAudioUseCaseProvider),
        ref: ref,
      );
    });

class CreateAudioNotifier extends StateNotifier<CreateAudioState> {
  final GenerateAudioUseCase generateAudioUseCase;
  final Ref ref;

  CreateAudioNotifier(this.generateAudioUseCase, {required this.ref})
    : super(const CreateAudioState());

  void onPromptChanged(String value) {
    state = state.copyWith(
      prompt: value,
      status: CreateAudioStatus.initial,
      errorMessage: null,
    );
  }

  void onDurationChanged(int value) {
    state = state.copyWith(
      durationSeconds: value,
      status: CreateAudioStatus.initial,
      errorMessage: null,
    );
  }

  Future<void> generateAudio({
    required String promptRequiredMessage,
    required String promptTooShortMessage,
    required String audioDurationRangeMessage,
  }) async {
    final prompt = state.prompt.trim();

    if (prompt.isEmpty) {
      state = state.copyWith(
        status: CreateAudioStatus.error,
        errorMessage: promptRequiredMessage,
        clearGeneratedAudio: true,
      );
      return;
    }

    if (prompt.length < 10) {
      state = state.copyWith(
        status: CreateAudioStatus.error,
        errorMessage: promptTooShortMessage,
        clearGeneratedAudio: true,
      );
      return;
    }

    if (state.durationSeconds < 5 || state.durationSeconds > 60) {
      state = state.copyWith(
        status: CreateAudioStatus.error,
        errorMessage: audioDurationRangeMessage,
        clearGeneratedAudio: true,
      );
      return;
    }

    state = state.copyWith(
      status: CreateAudioStatus.loading,
      errorMessage: null,
      clearGeneratedAudio: true,
    );

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState is AuthSuccess
          ? authState.user.id
          : 'guest_user';

      final generatedAudio = await generateAudioUseCase(
        userId: userId,
        prompt: prompt,
        durationSeconds: state.durationSeconds,
      );

      // Save it to my audios
      ref.read(myAudiosProvider.notifier).addAudio(generatedAudio);

      state = state.copyWith(
        status: CreateAudioStatus.success,
        generatedAudio: generatedAudio,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: CreateAudioStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        clearGeneratedAudio: true,
      );
    }
  }
}
