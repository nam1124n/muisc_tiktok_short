import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/ui/screen/my_audios/providers/my_audios_sync_helper.dart';

void main() {
  const helper = MyAudiosSyncHelper();

  group('MyAudiosSyncHelper', () {
    test('mergeTasks prefers task with more tracks for the same id', () {
      final current = [
        _task(id: 'task_1', status: 'processing', trackCount: 1),
      ];
      final incoming = [
        _task(id: 'task_1', status: 'processing', trackCount: 2),
      ];

      final merged = helper.mergeTasks(current, incoming);

      expect(merged, hasLength(1));
      expect(merged.single.tracks, hasLength(2));
    });

    test('mergeTasks prefers task with higher status rank', () {
      final current = [_task(id: 'task_1', status: 'processing')];
      final incoming = [_task(id: 'task_1', status: 'completed')];

      final merged = helper.mergeTasks(current, incoming);

      expect(merged.single.status, 'completed');
    });

    test('mergeTasks prefers newer task when status rank is equal', () {
      final current = [
        _task(
          id: 'task_1',
          status: 'completed',
          updatedAt: DateTime(2026, 5, 8, 10),
        ),
      ];
      final incoming = [
        _task(
          id: 'task_1',
          status: 'completed',
          updatedAt: DateTime(2026, 5, 8, 12),
        ),
      ];

      final merged = helper.mergeTasks(current, incoming);

      expect(merged.single.updatedAt, DateTime(2026, 5, 8, 12));
    });
  });
}

GeneratedAudioTaskEntity _task({
  required String id,
  required String status,
  int trackCount = 1,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final tracks = List.generate(
    trackCount,
    (index) => GeneratedAudioEntity(
      id: '$id-track-$index',
      taskId: id,
      variantIndex: index,
      title: 'Track $index',
      prompt: 'Prompt',
      audioUrl: 'https://example.com/$id/$index.mp3',
      streamAudioUrl: 'https://example.com/$id/$index-stream.mp3',
      imageUrl: 'https://example.com/$id/$index.jpg',
      durationSeconds: 30,
      provider: 'suno',
      modelName: 'model',
    ),
  );

  return GeneratedAudioTaskEntity(
    id: id,
    userId: 'user_1',
    prompt: 'Prompt',
    status: status,
    provider: 'suno',
    outputCount: trackCount,
    tracks: tracks,
    createdAt: createdAt ?? DateTime(2026, 5, 8, 9),
    updatedAt: updatedAt,
  );
}
