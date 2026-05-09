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

    test('shouldPollPending returns true only when pending tasks exist', () {
      final tasks = [
        _task(id: 'task_1', status: 'completed'),
        _task(id: 'task_2', status: 'first_success'),
      ];

      expect(helper.shouldPollPending(tasks), isTrue);
      expect(
        helper.shouldPollPending([_task(id: 'task_3', status: 'failed')]),
        isFalse,
      );
    });

    test(
      'hasTaskListChanged detects content changes between task snapshots',
      () {
        final current = [
          _task(id: 'task_1', status: 'processing'),
          _task(id: 'task_2', status: 'completed'),
        ];
        final same = [
          _task(id: 'task_1', status: 'processing'),
          _task(id: 'task_2', status: 'completed'),
        ];
        final changed = [
          _task(id: 'task_1', status: 'completed'),
          _task(id: 'task_2', status: 'completed'),
        ];

        expect(helper.hasTaskListChanged(current, same), isFalse);
        expect(helper.hasTaskListChanged(current, changed), isTrue);
      },
    );

    test('nextPollingAttempt resets on progress and caps repeated retries', () {
      expect(
        helper.nextPollingAttempt(
          previousAttempt: 2,
          hadProgress: true,
          maxAttempt: 3,
        ),
        0,
      );
      expect(
        helper.nextPollingAttempt(
          previousAttempt: 0,
          hadProgress: false,
          maxAttempt: 3,
        ),
        1,
      );
      expect(
        helper.nextPollingAttempt(
          previousAttempt: 3,
          hadProgress: false,
          maxAttempt: 3,
        ),
        3,
      );
    });

    test('pollingDelayForAttempt doubles up to the configured cap', () {
      expect(
        helper.pollingDelayForAttempt(
          attempt: 0,
          baseSeconds: 10,
          maxSeconds: 60,
        ),
        const Duration(seconds: 10),
      );
      expect(
        helper.pollingDelayForAttempt(
          attempt: 1,
          baseSeconds: 10,
          maxSeconds: 60,
        ),
        const Duration(seconds: 20),
      );
      expect(
        helper.pollingDelayForAttempt(
          attempt: 2,
          baseSeconds: 10,
          maxSeconds: 60,
        ),
        const Duration(seconds: 40),
      );
      expect(
        helper.pollingDelayForAttempt(
          attempt: 4,
          baseSeconds: 10,
          maxSeconds: 60,
        ),
        const Duration(seconds: 60),
      );
    });

    test(
      'hasTaskChanged detects semantic changes and ignores identical data',
      () {
        final current = _task(
          id: 'task_1',
          status: 'processing',
          updatedAt: DateTime(2026, 5, 8, 10),
        );
        final same = _task(
          id: 'task_1',
          status: 'processing',
          updatedAt: DateTime(2026, 5, 8, 10),
        );
        final changed = _task(
          id: 'task_1',
          status: 'completed',
          updatedAt: DateTime(2026, 5, 8, 11),
        );

        expect(helper.hasTaskChanged(current, same), isFalse);
        expect(helper.hasTaskChanged(current, changed), isTrue);
        expect(helper.hasTaskChanged(null, changed), isTrue);
      },
    );
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
