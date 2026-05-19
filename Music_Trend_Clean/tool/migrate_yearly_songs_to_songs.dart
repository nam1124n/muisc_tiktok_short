import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final config = _MigrationConfig.parse(args);

  if (config.showHelp) {
    stdout.writeln(_MigrationConfig.helpText);
    return;
  }

  if (!config.isValid) {
    stderr.writeln(config.validationError);
    stderr.writeln('');
    stderr.writeln(_MigrationConfig.helpText);
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
          ? 'Migration mode: APPLY changes to Firestore.'
          : 'Migration mode: DRY RUN only. Re-run with --apply to update Firestore.',
    );
    stdout.writeln(
      'Project: ${config.projectId} | ${config.sourceCollection} -> '
      '${config.destinationCollection} | Page size: ${config.pageSize}',
    );
    stdout.writeln(
      config.overwriteExisting
          ? 'Existing destination docs will be overwritten.'
          : 'Existing destination docs will be skipped.',
    );

    final summary = await _runMigration(
      client: client,
      config: config,
      idToken: idToken,
    );

    stdout.writeln('');
    stdout.writeln('Processed: ${summary.processed}');
    stdout.writeln('Migrated: ${summary.migrated}');
    stdout.writeln('Skipped existing: ${summary.skippedExisting}');
    stdout.writeln('Skipped invalid: ${summary.skippedInvalid}');
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
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
    '?key=$apiKey',
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
  final data = _decodeJsonObject(response.body);

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

Future<_MigrationSummary> _runMigration({
  required http.Client client,
  required _MigrationConfig config,
  required String idToken,
}) async {
  var processed = 0;
  var migrated = 0;
  var skippedExisting = 0;
  var skippedInvalid = 0;
  var errors = 0;
  String? pageToken;
  var hasMore = true;

  while (hasMore) {
    final page = await _fetchDocumentsPage(
      client: client,
      projectId: config.projectId,
      collection: config.sourceCollection,
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
        final action = await _processDocument(
          client: client,
          config: config,
          idToken: idToken,
          document: document,
        );

        switch (action) {
          case _MigrationAction.migrated:
            migrated += 1;
          case _MigrationAction.skippedExisting:
            skippedExisting += 1;
          case _MigrationAction.skippedInvalid:
            skippedInvalid += 1;
        }
      } catch (error) {
        errors += 1;
        stderr.writeln('[ERROR] ${document.id}: $error');
      }
    }

    pageToken = page.nextPageToken;
    hasMore = hasMore && pageToken != null && pageToken.isNotEmpty;
  }

  return _MigrationSummary(
    processed: processed,
    migrated: migrated,
    skippedExisting: skippedExisting,
    skippedInvalid: skippedInvalid,
    errors: errors,
  );
}

Future<_MigrationAction> _processDocument({
  required http.Client client,
  required _MigrationConfig config,
  required String idToken,
  required _FirestoreDocument document,
}) async {
  final destinationDocument = await _getDocument(
    client: client,
    projectId: config.projectId,
    collection: config.destinationCollection,
    documentId: document.id,
    idToken: idToken,
  );

  if (destinationDocument != null && !config.overwriteExisting) {
    stdout.writeln(
      '[SKIP] ${document.id} | already exists in '
      '${config.destinationCollection}',
    );
    return _MigrationAction.skippedExisting;
  }

  final fields = _buildDestinationFields(document);
  final title = _readStringField(fields['title']);
  final audioUrl = _readStringField(fields['audioUrl']);
  final imageUrl = _readStringField(fields['imageUrl']);

  if (title.isEmpty || audioUrl.isEmpty || imageUrl.isEmpty) {
    stdout.writeln(
      '[SKIP] ${document.id} | missing required title/audioUrl/imageUrl',
    );
    return _MigrationAction.skippedInvalid;
  }

  final releaseYear = _readIntegerField(fields['releaseYear']);
  final audioType = _readStringField(fields['audioType']);
  final status = _readStringField(fields['status']);

  stdout.writeln(
    '[PLAN] ${document.id} | "$title" | year=${releaseYear ?? 'n/a'} | '
    'audioType=$audioType | status=$status',
  );

  if (!config.apply) {
    return _MigrationAction.migrated;
  }

  await _upsertDocument(
    client: client,
    projectId: config.projectId,
    collection: config.destinationCollection,
    documentId: document.id,
    fields: fields,
    updateMasks: fields.keys.toList(),
    idToken: idToken,
  );

  stdout.writeln('[DONE] ${document.id}');
  return _MigrationAction.migrated;
}

Map<String, dynamic> _buildDestinationFields(_FirestoreDocument document) {
  final sourceFields = Map<String, dynamic>.from(document.fields);
  final now = DateTime.now().toUtc().toIso8601String();
  final releaseYear =
      _readIntegerField(sourceFields['releaseYear']) ??
      _readIntegerField(sourceFields['year']) ??
      _readYearFromSavedAt(sourceFields['savedAt']);
  final savedAt =
      sourceFields['savedAt'] ??
      sourceFields['timestamp'] ??
      (releaseYear == null
          ? null
          : {'stringValue': DateTime.utc(releaseYear, 1, 1).toIso8601String()});

  if (savedAt != null) {
    sourceFields['savedAt'] = savedAt;
  }
  if (releaseYear != null) {
    sourceFields['releaseYear'] = {'integerValue': releaseYear.toString()};
    sourceFields['year'] = {'integerValue': releaseYear.toString()};
  }

  sourceFields['audioType'] = {
    'stringValue': _normalizeAudioType(
      _readStringField(sourceFields['audioType']),
    ),
  };
  sourceFields['trackInWeeklyStats'] = {'booleanValue': false};
  final status = _normalizeStatus(_readStringField(sourceFields['status']));
  sourceFields['status'] = {'stringValue': status};
  sourceFields['createdAt'] =
      sourceFields['createdAt'] ?? savedAt ?? {'stringValue': now};
  if (status == 'published' && !_hasDateField(sourceFields['publishedAt'])) {
    sourceFields['publishedAt'] = savedAt ?? {'stringValue': now};
  }
  sourceFields['migratedFrom'] = {'stringValue': 'yearly_songs'};
  sourceFields['legacyYearSongId'] = {'stringValue': document.id};
  sourceFields['migratedAt'] = {'stringValue': now};
  sourceFields['updatedAt'] = sourceFields['updatedAt'] ?? {'stringValue': now};

  sourceFields.remove('timestamp');

  return sourceFields;
}

Future<_DocumentsPage> _fetchDocumentsPage({
  required http.Client client,
  required String projectId,
  required String collection,
  required int pageSize,
  required String? pageToken,
  required String idToken,
}) async {
  final queryParameters = <String, String>{
    'pageSize': pageSize.toString(),
    'orderBy': '__name__',
    if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
  };
  final uri = Uri.https(
    'firestore.googleapis.com',
    '/v1/projects/$projectId/databases/(default)/documents/$collection',
    queryParameters,
  );

  final response = await client.get(
    uri,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
  );
  final data = _decodeJsonObject(response.body);

  if (response.statusCode >= 400) {
    final message =
        (data['error'] as Map<String, dynamic>?)?['message']?.toString() ??
        'Failed to load Firestore documents';
    throw Exception(message);
  }

  final documents = (data['documents'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(_FirestoreDocument.fromRest)
      .toList();

  return _DocumentsPage(
    documents: documents,
    nextPageToken: data['nextPageToken']?.toString(),
  );
}

Future<Map<String, dynamic>?> _getDocument({
  required http.Client client,
  required String projectId,
  required String collection,
  required String documentId,
  required String idToken,
}) async {
  final uri = Uri.https(
    'firestore.googleapis.com',
    '/v1/projects/$projectId/databases/(default)/documents/$collection/'
        '${Uri.encodeComponent(documentId)}',
  );

  final response = await client.get(
    uri,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 404) {
    return null;
  }

  final data = _decodeJsonObject(response.body);
  if (response.statusCode >= 400) {
    final message =
        (data['error'] as Map<String, dynamic>?)?['message']?.toString() ??
        'Failed to load Firestore document';
    throw Exception(message);
  }

  return data;
}

Future<void> _upsertDocument({
  required http.Client client,
  required String projectId,
  required String collection,
  required String documentId,
  required Map<String, dynamic> fields,
  required List<String> updateMasks,
  required String idToken,
}) async {
  final query = updateMasks
      .map((mask) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(mask)}')
      .join('&');
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/'
    '(default)/documents/$collection/${Uri.encodeComponent(documentId)}'
    '?$query',
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
    final data = _decodeJsonObject(response.body);
    final message =
        (data['error'] as Map<String, dynamic>?)?['message']?.toString() ??
        'Failed to write Firestore document';
    throw Exception(message);
  }
}

Map<String, dynamic> _decodeJsonObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  return <String, dynamic>{};
}

String _readStringField(Object? value) {
  if (value is! Map<String, dynamic>) {
    return '';
  }

  return value['stringValue']?.toString().trim() ?? '';
}

int? _readIntegerField(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final rawValue =
      value['integerValue'] ?? value['doubleValue'] ?? value['stringValue'];
  if (rawValue is num) {
    return rawValue.toInt();
  }

  return int.tryParse(rawValue?.toString() ?? '');
}

int? _readYearFromSavedAt(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final rawValue = value['timestampValue'] ?? value['stringValue'];
  final parsed = DateTime.tryParse(rawValue?.toString() ?? '');
  return parsed?.year;
}

bool _hasDateField(Object? value) {
  if (value is! Map<String, dynamic>) {
    return false;
  }

  final rawValue = value['timestampValue'] ?? value['stringValue'];
  return DateTime.tryParse(rawValue?.toString() ?? '') != null;
}

String _normalizeAudioType(String value) {
  return value.toLowerCase() == 'full' ? 'full' : 'short';
}

String _normalizeStatus(String value) {
  return switch (value.toLowerCase()) {
    'pending' => 'pending',
    'hidden' => 'hidden',
    'archived' => 'archived',
    _ => 'published',
  };
}

class _MigrationConfig {
  static const String helpText =
      'Usage:\n'
      '  dart run tool/migrate_yearly_songs_to_songs.dart '
      '[--email admin@gmail.com] [--password password] [--apply]\n'
      '\n'
      'Credential fallback:\n'
      '  - CLI flags win over environment variables\n'
      '  - Supported envs: FIREBASE_TOOL_EMAIL / FIREBASE_TOOL_PASSWORD\n'
      '  - Backend envs FIREBASE_BACKEND_EMAIL / FIREBASE_BACKEND_PASSWORD also work\n'
      '\n'
      'Options:\n'
      '  --email <value>          Firebase account email used to access Firestore.\n'
      '  --password <value>       Firebase account password.\n'
      '  --api-key <value>        Firebase Web API key. Defaults to current project config.\n'
      '  --project-id <value>     Firestore project id. Defaults to current project config.\n'
      '  --source <value>         Source collection. Default: yearly_songs.\n'
      '  --destination <value>    Destination collection. Default: songs.\n'
      '  --page-size <value>      Firestore page size. Default: 100.\n'
      '  --limit <value>          Process only the first N source docs.\n'
      '  --overwrite-existing     Overwrite existing destination documents.\n'
      '  --apply                  Actually write to Firestore. Without this flag the script is dry-run only.\n'
      '  --help                   Show this help.\n';

  final String email;
  final String password;
  final String apiKey;
  final String projectId;
  final String sourceCollection;
  final String destinationCollection;
  final int pageSize;
  final int? limit;
  final bool overwriteExisting;
  final bool apply;
  final bool showHelp;

  const _MigrationConfig({
    required this.email,
    required this.password,
    required this.apiKey,
    required this.projectId,
    required this.sourceCollection,
    required this.destinationCollection,
    required this.pageSize,
    required this.limit,
    required this.overwriteExisting,
    required this.apply,
    required this.showHelp,
  });

  factory _MigrationConfig.parse(List<String> args) {
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

    return _MigrationConfig(
      email:
          _readOptionOrEnv(
            options: options,
            optionKey: 'email',
            envKeys: const ['FIREBASE_TOOL_EMAIL', 'FIREBASE_BACKEND_EMAIL'],
          ) ??
          'admin@gmail.com',
      password:
          _readOptionOrEnv(
            options: options,
            optionKey: 'password',
            envKeys: const [
              'FIREBASE_TOOL_PASSWORD',
              'FIREBASE_BACKEND_PASSWORD',
            ],
          ) ??
          '',
      apiKey:
          _readOptionOrEnv(
            options: options,
            optionKey: 'api-key',
            envKeys: const ['FIREBASE_TOOL_API_KEY', 'FIREBASE_WEB_API_KEY'],
          ) ??
          'AIzaSyCaunJrZfmVkcX6XQidUh5fi6F7VntnZ8w',
      projectId:
          _readOptionOrEnv(
            options: options,
            optionKey: 'project-id',
            envKeys: const ['FIREBASE_TOOL_PROJECT_ID', 'FIREBASE_PROJECT_ID'],
          ) ??
          'appmusi-4ff75',
      sourceCollection: options['source'] ?? 'yearly_songs',
      destinationCollection: options['destination'] ?? 'songs',
      pageSize: int.tryParse(options['page-size'] ?? '') ?? 100,
      limit: int.tryParse(options['limit'] ?? ''),
      overwriteExisting: flags.contains('overwrite-existing'),
      apply: flags.contains('apply'),
      showHelp: flags.contains('help'),
    );
  }

  bool get isValid =>
      email.trim().isNotEmpty &&
      password.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      projectId.trim().isNotEmpty &&
      sourceCollection.trim().isNotEmpty &&
      destinationCollection.trim().isNotEmpty &&
      pageSize > 0;

  String get validationError {
    if (email.trim().isEmpty) {
      return 'Missing required argument: --email '
          '(or set FIREBASE_TOOL_EMAIL / FIREBASE_BACKEND_EMAIL)';
    }
    if (password.trim().isEmpty) {
      return 'Missing required argument: --password '
          '(or set FIREBASE_TOOL_PASSWORD / FIREBASE_BACKEND_PASSWORD)';
    }
    if (apiKey.trim().isEmpty) {
      return 'Missing required argument: --api-key';
    }
    if (projectId.trim().isEmpty) {
      return 'Missing required argument: --project-id';
    }
    if (sourceCollection.trim().isEmpty) {
      return 'Missing required argument: --source';
    }
    if (destinationCollection.trim().isEmpty) {
      return 'Missing required argument: --destination';
    }
    if (pageSize <= 0) {
      return 'Invalid --page-size';
    }

    return 'Invalid configuration';
  }

  static String? _readOptionOrEnv({
    required Map<String, String> options,
    required String optionKey,
    required List<String> envKeys,
  }) {
    final optionValue = options[optionKey]?.trim();
    if (optionValue != null && optionValue.isNotEmpty) {
      return optionValue;
    }

    for (final envKey in envKeys) {
      final envValue = Platform.environment[envKey]?.trim();
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    }

    return null;
  }
}

class _FirestoreDocument {
  final String name;
  final Map<String, dynamic> fields;

  const _FirestoreDocument({required this.name, required this.fields});

  String get id => Uri.decodeComponent(name.split('/').last);

  factory _FirestoreDocument.fromRest(Map<String, dynamic> data) {
    return _FirestoreDocument(
      name: data['name']?.toString() ?? '',
      fields: Map<String, dynamic>.from(
        data['fields'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class _DocumentsPage {
  final List<_FirestoreDocument> documents;
  final String? nextPageToken;

  const _DocumentsPage({required this.documents, required this.nextPageToken});
}

class _MigrationSummary {
  final int processed;
  final int migrated;
  final int skippedExisting;
  final int skippedInvalid;
  final int errors;

  const _MigrationSummary({
    required this.processed,
    required this.migrated,
    required this.skippedExisting,
    required this.skippedInvalid,
    required this.errors,
  });
}

enum _MigrationAction { migrated, skippedExisting, skippedInvalid }
