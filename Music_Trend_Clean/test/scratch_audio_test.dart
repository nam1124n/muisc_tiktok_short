import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect just_audio platform method calls', () async {
    const channel = MethodChannel('com.ryanheise.just_audio.methods');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          print('Platform call: ${methodCall.method}');
          if (methodCall.method == 'init') {
            final id = methodCall.arguments['id'];
            final playerChannel = MethodChannel(
              'com.ryanheise.just_audio.methods.$id',
            );
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(playerChannel, (
                  MethodCall playerCall,
                ) async {
                  print('Player $id call: ${playerCall.method}');
                  return {};
                });
            return {};
          }
          return {};
        });

    final player = AudioPlayer();
    print('AudioPlayer created successfully!');

    try {
      await player.setUrl('https://example.com/audio.mp3');
      print('setUrl completed!');
    } catch (e) {
      print('setUrl threw exception: $e');
    }

    await player.dispose();
    print('AudioPlayer disposed successfully!');
  });
}
