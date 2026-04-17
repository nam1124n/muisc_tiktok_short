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

  Future<void> generateAudio({
    required String promptRequiredMessage,
    required String promptTooShortMessage,
  }) async {
    final prompt = state.prompt.trim();

    if (prompt.isEmpty) {
      state = state.copyWith(
        status: CreateAudioStatus.error,
        errorMessage: promptRequiredMessage,
        clearGeneratedTask: true,
      );
      return;
    }

    if (prompt.length < 10) {
      state = state.copyWith(
        status: CreateAudioStatus.error,
        errorMessage: promptTooShortMessage,
        clearGeneratedTask: true,
      );
      return;
    }

    state = state.copyWith(
      status: CreateAudioStatus.loading,
      errorMessage: null,
      clearGeneratedTask: true,
    );

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState is AuthSuccess
          ? authState.user.id
          : 'guest_user';

      final generatedTask = await generateAudioUseCase(
        userId: userId,
        prompt: prompt,
      );

      await ref.read(myAudiosProvider.notifier).saveTask(generatedTask);

      state = state.copyWith(
        status: CreateAudioStatus.success,
        generatedTask: generatedTask,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: CreateAudioStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        clearGeneratedTask: true,
      );
    }
  }
}
