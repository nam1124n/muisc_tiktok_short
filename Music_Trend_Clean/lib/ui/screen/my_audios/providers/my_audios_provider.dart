import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/audio_generation_provider.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/usecases/get_my_songs_usecase.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final myAudiosProvider =
    StateNotifierProvider<MyAudiosNotifier, List<GeneratedAudioEntity>>((ref) {
      final authState = ref.watch(authNotifierProvider);
      final userId = authState is AuthSuccess
          ? authState.user.id
          : 'guest_user';

      return MyAudiosNotifier(
        userId,
        getMySongsUseCase: ref.read(getMySongsUseCaseProvider),
      );
    });

class MyAudiosNotifier extends StateNotifier<List<GeneratedAudioEntity>> {
  final String userId;
  final GetMySongsUseCase getMySongsUseCase;

  MyAudiosNotifier(this.userId, {required this.getMySongsUseCase}) : super([]) {
    _loadAudios();
  }

  String get _key => 'my_created_audios_$userId';

  Future<void> _loadAudios() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key);

    if (jsonList != null && jsonList.isNotEmpty) {
      try {
        final loaded = jsonList
            .map((str) => GeneratedAudioEntity.fromJson(jsonDecode(str)))
            .toList();
        state = loaded;
      } catch (_) {}
    }

    if (userId == 'guest_user') {
      return;
    }

    try {
      final remoteSongs = await getMySongsUseCase(userId: userId);

      if (remoteSongs.isNotEmpty) {
        state = remoteSongs;
        await _saveAudios(remoteSongs);
      }
    } catch (_) {}
  }

  Future<void> _saveAudios(List<GeneratedAudioEntity> audios) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = audios.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  void addAudio(GeneratedAudioEntity audio) {
    state = [audio, ...state];
    _saveAudios(state);
  }

  void removeAudio(String id) {
    state = state.where((audio) => audio.id != id).toList();
    _saveAudios(state);
  }
}
