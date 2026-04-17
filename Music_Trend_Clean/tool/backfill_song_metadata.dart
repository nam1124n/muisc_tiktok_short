import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:login_flutter/app/utils/song_metadata_backfill.dart';

Future<void> main(List<String> args) async {
  final config = _BackfillConfig.parse(args);

  if (config.showHelp) {
    stdout.writeln(_BackfillConfig.helpText);
    return;
  }

  if (!config.isValid) {
    stderr.writeln(config.validationError);
    stderr.writeln('');
    stderr.writeln(_BackfillConfig.helpText);
    exitCode = 64;
    return;
  }

  final client = http.Client();

  try {
    final idToken = await _signInWithPassword(
      client: client,
      apiKey: config.apiKey,
      email: config.email,
      password: config.password,
    );

    stdout.writeln(
      config.apply
          ? 'Backfill mode: APPLY changes to Firestore.'
          : 'Backfill mode: DRY RUN only. Re-run with --apply to update Firestore.',
    );
    stdout.writeln(
      'Project: ${config.projectId} | Collection: ${config.collection} | Page size: ${config.pageSize}',
    );

    final summary = await _runBackfill(
      client: client,
      config: config,
      idToken: idToken,
    );

    stdout.writeln('');
    stdout.writeln('Processed: ${summary.processed}');
    stdout.writeln('Updated: ${summary.updated}');
    stdout.writeln('Skipped: ${summary.skipped}');
    stdout.writeln('Errors: ${summary.errors}');

    if (!config.apply) {
      stdout.writeln('No Firestore documents were modified.');
    }
  } finally {
    client.close();
  }
}

Future<String> _signInWithPassword({
  required http.Client client,
  required String apiKey,
  required String email,
  required String password,
}) async {
  final uri = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
  );

  final response = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }),
  );

  final data = jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode >= 400) {
    final message =
        (data['error'] as Map<String, dynamic>?)?['message']?.toString() ??
        'Firebase Auth sign-in failed';
    throw Exception(message);
  }

  final idToken = data['idToken']?.toString();
  if (idToken == null || idToken.isEmpty) {
    throw Exception('Missing Firebase ID token');
  }

  return idToken;
}

Future<_BackfillSummary> _runBackfill({
  required http.Client client,
  required _BackfillConfig config,
  required String idToken,
}) async {
  var processed = 0;
  var updated = 0;
  var skipped = 0;
  var errors = 0;
  String? pageToken;
  var hasMore = true;

  while (hasMore) {
    final page = await _fetchSongsPage(
      client: client,
      projectId: config.projectId,
      collection: config.collection,
      pageSize: config.pageSize,
      pageToken: pageToken,
      idToken: idToken,
    );

    for (final document in page.documents) {
      if (config.limit != null && processed >= config.limit!) {
        hasMore = false;
        break;
      }

      processed += 1;

      try {
        final result = await _processDocument(
          client: client,
          config: config,
          idToken: idToken,
          document: document,
        );

        switch (result) {
          case _DocumentAction.updated:
            updated += 1;
          case _DocumentAction.skipped:
            skipped += 1;
        }
      } catch (error) {
        errors += 1;
        stderr.writeln('Error at ${document.shortName}: $error');
      }
    }

    pageToken = page.nextPageToken;
    hasMore = hasMore && pageToken != null && pageToken.isNotEmpty;
  }

  return _BackfillSummary(
    processed: processed,
    updated: updated,
    skipped: skipped,
    errors: errors,
  );
}

Future<_DocumentAction> _processDocument({
  required http.Client client,
  required _BackfillConfig config,
  required String idToken,
  required _FirestoreDocument document,
}) async {
  final title = document.readString('title');
  final artist = document.readString('artist');
  final currentTags = document.readStringList('semanticTags');
  final currentEnergy = document.readInt('energyLevel');

  if (title.isEmpty && artist.isEmpty) {
    stdout.writeln('[SKIP] ${document.shortName} missing title/artist');
    return _DocumentAction.skipped;
  }

  final suggestion = inferBasicSongMetadata(title: title, artist: artist);
  if (!suggestion.hasData) {
    stdout.writeln(
      '[SKIP] ${document.shortName} | "$title" -> no confident tags',
    );
    return _DocumentAction.skipped;
  }

  final nextTags = _resolveTags(
    currentTags: currentTags,
    inferredTags: suggestion.semanticTags,
    overwrite: config.overwrite,
  );
  final nextEnergy = _resolveEnergy(
    currentEnergy: currentEnergy,
    inferredEnergy: suggestion.energyLevel,
    overwrite: config.overwrite,
  );

  if (_sameStringLists(currentTags, nextTags) && currentEnergy == nextEnergy) {
    stdout.writeln(
      '[SKIP] ${document.shortName} | "$title" already has metadata',
    );
    return _DocumentAction.skipped;
  }

  stdout.writeln(
    '[PLAN] ${document.shortName} | "$title" -> tags=${nextTags.join(', ')}'
    '${nextEnergy != null ? ' | energy=$nextEnergy' : ''}'
    ' | rules=${suggestion.matchedRules.join(', ')}',
  );

  if (!config.apply) {
    return _DocumentAction.updated;
  }

  final patchData = <String, dynamic>{};
  final updateMasks = <String>[];

  if (!_sameStringLists(currentTags, nextTags)) {
    patchData['semanticTags'] = _encodeStringArray(nextTags);
    updateMasks.add('semanticTags');
  }

  if (currentEnergy != nextEnergy && nextEnergy != null) {
    patchData['energyLevel'] = {'integerValue': nextEnergy.toString()};
    updateMasks.add('energyLevel');
  }

  if (patchData.isEmpty) {
    return _DocumentAction.skipped;
  }

  await _patchDocument(
    client: client,
    documentName: document.name,
    fields: patchData,
    updateMasks: updateMasks,
    idToken: idToken,
  );

  stdout.writeln('[DONE] ${document.shortName}');
  return _DocumentAction.updated;
}

List<String> _resolveTags({
  required List<String> currentTags,
  required List<String> inferredTags,
  required bool overwrite,
}) {
  if (overwrite) {
    return inferredTags;
  }

  if (currentTags.isNotEmpty) {
    return currentTags;
  }

  return inferredTags;
}

int? _resolveEnergy({
  required int? currentEnergy,
  required int? inferredEnergy,
  required bool overwrite,
}) {
  if (overwrite) {
    return inferredEnergy;
  }

  return currentEnergy ?? inferredEnergy;
}

bool _sameStringLists(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}

Map<String, dynamic> _encodeStringArray(List<String> values) {
  return {
    'arrayValue': {
      'values': values.map((value) => {'stringValue': value}).toList(),
    },
  };
}

Future<_FirestorePage> _fetchSongsPage({
  required http.Client client,
  required String projectId,
  required String collection,
  required int pageSize,
  required String? pageToken,
  required String idToken,
}) async {
  final query = <String, String>{'pageSize': pageSize.toString()};
  if (pageToken != null && pageToken.isNotEmpty) {
    query['pageToken'] = pageToken;
  }

  final uri = Uri.https(
    'firestore.googleapis.com',
    '/v1/projects/$projectId/databases/(default)/documents/$collection',
    query,
  );

  final response = await client.get(
    uri,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode >= 400) {
    final message =
        (data['error'] as Map<String, dynamic>?)?['message']?.toString() ??
        'Failed to load Firestore documents';
    throw Exception(message);
  }

  final documents = ((data['documents'] as List?) ?? const [])
      .cast<Map<String, dynamic>>()
      .map(_FirestoreDocument.fromJson)
      .toList();

  return _FirestorePage(
    documents: documents,
    nextPageToken: data['nextPageToken']?.toString(),
  );
}

Future<void> _patchDocument({
  required http.Client client,
  required String documentName,
  required Map<String, dynamic> fields,
  required List<String> updateMasks,
  required String idToken,
}) async {
  final query = updateMasks
      .map((mask) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(mask)}')
      .join('&');
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/$documentName?$query',
  );

  final response = await client.patch(
    uri,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'fields': fields}),
  );

  if (response.statusCode >= 400) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        (data['error'] as Map<String, dynamic>?)?['message']?.toString() ??
        'Failed to patch Firestore document';
    throw Exception(message);
  }
}

class _FirestorePage {
  final List<_FirestoreDocument> documents;
  final String? nextPageToken;

  const _FirestorePage({required this.documents, required this.nextPageToken});
}

class _FirestoreDocument {
  final String name;
  final Map<String, dynamic> fields;

  const _FirestoreDocument({required this.name, required this.fields});

  factory _FirestoreDocument.fromJson(Map<String, dynamic> json) {
    return _FirestoreDocument(
      name: json['name']?.toString() ?? '',
      fields: (json['fields'] as Map<String, dynamic>?) ?? const {},
    );
  }

  String get shortName {
    if (name.isEmpty) {
      return '<unknown>';
    }
    return name.split('/').last;
  }

  String readString(String key) {
    final value = fields[key];
    if (value is! Map<String, dynamic>) {
      return '';
    }

    return value['stringValue']?.toString() ?? '';
  }

  int? readInt(String key) {
    final value = fields[key];
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final raw =
        value['integerValue']?.toString() ?? value['doubleValue']?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return int.tryParse(raw.split('.').first);
  }

  List<String> readStringList(String key) {
    final value = fields[key];
    if (value is! Map<String, dynamic>) {
      return const [];
    }

    final arrayValue = value['arrayValue'];
    if (arrayValue is! Map<String, dynamic>) {
      return const [];
    }

    final values = arrayValue['values'];
    if (values is! List) {
      return const [];
    }

    return values
        .whereType<Map<String, dynamic>>()
        .map((item) => item['stringValue']?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class _BackfillSummary {
  final int processed;
  final int updated;
  final int skipped;
  final int errors;

  const _BackfillSummary({
    required this.processed,
    required this.updated,
    required this.skipped,
    required this.errors,
  });
}

enum _DocumentAction { updated, skipped }

class _BackfillConfig {
  static const String helpText =
      'Usage:\n'
      '  dart run tool/backfill_song_metadata.dart --email admin@gmail.com --password your_password [--apply]\n'
      '\n'
      'Options:\n'
      '  --email <value>          Firebase account email used to access Firestore.\n'
      '  --password <value>       Firebase account password.\n'
      '  --api-key <value>        Firebase Web API key. Defaults to current project config.\n'
      '  --project-id <value>     Firestore project id. Defaults to current project config.\n'
      '  --collection <value>     Firestore collection name. Default: songs.\n'
      '  --page-size <value>      Number of documents per request. Default: 50.\n'
      '  --limit <value>          Process only the first N documents.\n'
      '  --overwrite              Replace existing semanticTags/energyLevel instead of only filling missing fields.\n'
      '  --apply                  Actually write changes to Firestore. Without this flag the script is dry-run only.\n'
      '  --help                   Show this help.\n';

  final String email;
  final String password;
  final String apiKey;
  final String projectId;
  final String collection;
  final int pageSize;
  final int? limit;
  final bool overwrite;
  final bool apply;
  final bool showHelp;

  const _BackfillConfig({
    required this.email,
    required this.password,
    required this.apiKey,
    required this.projectId,
    required this.collection,
    required this.pageSize,
    required this.limit,
    required this.overwrite,
    required this.apply,
    required this.showHelp,
  });

  factory _BackfillConfig.parse(List<String> args) {
    final options = <String, String>{};
    final flags = <String>{};

    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index];
      if (!arg.startsWith('--')) {
        continue;
      }

      final trimmed = arg.substring(2);
      final separatorIndex = trimmed.indexOf('=');

      if (separatorIndex != -1) {
        options[trimmed.substring(0, separatorIndex)] = trimmed.substring(
          separatorIndex + 1,
        );
        continue;
      }

      final next = index + 1 < args.length ? args[index + 1] : null;
      if (next != null && !next.startsWith('--')) {
        options[trimmed] = next;
        index += 1;
      } else {
        flags.add(trimmed);
      }
    }

    return _BackfillConfig(
      email: options['email'] ?? '',
      password: options['password'] ?? '',
      apiKey: options['api-key'] ?? 'AIzaSyCaunJrZfmVkcX6XQidUh5fi6F7VntnZ8w',
      projectId: options['project-id'] ?? 'appmusi-4ff75',
      collection: options['collection'] ?? 'songs',
      pageSize: int.tryParse(options['page-size'] ?? '') ?? 50,
      limit: int.tryParse(options['limit'] ?? ''),
      overwrite: flags.contains('overwrite'),
      apply: flags.contains('apply'),
      showHelp: flags.contains('help'),
    );
  }

  bool get isValid =>
      showHelp || (email.isNotEmpty && password.isNotEmpty && pageSize > 0);

  String get validationError {
    if (pageSize <= 0) {
      return 'page-size must be greater than 0.';
    }
    if (email.isEmpty) {
      return 'Missing required option: --email';
    }
    if (password.isEmpty) {
      return 'Missing required option: --password';
    }
    return 'Invalid arguments.';
  }
}
