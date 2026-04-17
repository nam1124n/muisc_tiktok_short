import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final config = _ImportConfig.parse(args);

  if (config.showHelp) {
    stdout.writeln(_ImportConfig.helpText);
    return;
  }

  if (!config.isValid) {
    stderr.writeln(config.validationError);
    stderr.writeln('');
    stderr.writeln(_ImportConfig.helpText);
    exitCode = 64;
    return;
  }

  final rootDirectory = Directory(config.rootPath);
  if (!rootDirectory.existsSync()) {
    stderr.writeln('Root folder does not exist: ${config.rootPath}');
    exitCode = 64;
    return;
  }

  final yearFolders = _discoverYearFolders(rootDirectory);
  if (yearFolders.isEmpty) {
    stderr.writeln('No music_YYYY folders found under ${rootDirectory.path}.');
    exitCode = 64;
    return;
  }

  stdout.writeln(
    config.apply
        ? 'Import mode: APPLY changes to Firestore.'
        : 'Import mode: DRY RUN only. Re-run with --apply to upload and write.',
  );
  stdout.writeln(
    'Root: ${rootDirectory.path} | Year folders: ${yearFolders.length} | Collection: ${config.collection}',
  );

  final client = http.Client();

  try {
    final idToken = await _signInWithPassword(
      client: client,
      apiKey: config.apiKey,
      email: config.email,
      password: config.password,
    );

    final summary = await _runImport(
      client: client,
      config: config,
      idToken: idToken,
      yearFolders: yearFolders,
    );

    stdout.writeln('');
    stdout.writeln('Folders scanned: ${summary.foldersScanned}');
    stdout.writeln('Entries processed: ${summary.processed}');
    stdout.writeln('Imported: ${summary.imported}');
    stdout.writeln('Skipped: ${summary.skipped}');
    stdout.writeln('Errors: ${summary.errors}');

    if (!config.apply) {
      stdout.writeln(
        'No Cloudinary assets or Firestore documents were changed.',
      );
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

List<_YearFolder> _discoverYearFolders(Directory rootDirectory) {
  final folderPattern = RegExp(r'^music_(\d{4})$');
  final rootName = _basename(rootDirectory.path);
  final directMatch = folderPattern.firstMatch(rootName);

  if (directMatch != null) {
    return [
      _YearFolder(
        directory: rootDirectory,
        year: int.parse(directMatch.group(1)!),
      ),
    ];
  }

  return rootDirectory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .map((directory) {
        final match = folderPattern.firstMatch(_basename(directory.path));
        if (match == null) {
          return null;
        }

        return _YearFolder(
          directory: directory,
          year: int.parse(match.group(1)!),
        );
      })
      .whereType<_YearFolder>()
      .toList()
    ..sort((left, right) => right.year.compareTo(left.year));
}

Future<_ImportSummary> _runImport({
  required http.Client client,
  required _ImportConfig config,
  required String idToken,
  required List<_YearFolder> yearFolders,
}) async {
  var processed = 0;
  var imported = 0;
  var skipped = 0;
  var errors = 0;

  for (final yearFolder in yearFolders) {
    stdout.writeln('');
    stdout.writeln(
      'Scanning ${_basename(yearFolder.directory.path)} (${yearFolder.directory.path})',
    );

    List<_ImportEntry> entries;
    try {
      entries = _loadEntriesForYearFolder(yearFolder, config);
    } catch (error) {
      errors += 1;
      stderr.writeln(
        '[ERROR] ${_basename(yearFolder.directory.path)} | failed to read entries: $error',
      );
      continue;
    }

    if (entries.isEmpty) {
      stdout.writeln(
        '[SKIP] ${_basename(yearFolder.directory.path)} | no importable rows',
      );
      continue;
    }

    for (final entry in entries) {
      if (config.limit != null && processed >= config.limit!) {
        return _ImportSummary(
          foldersScanned: yearFolders.length,
          processed: processed,
          imported: imported,
          skipped: skipped,
          errors: errors,
        );
      }

      processed += 1;

      try {
        final action = await _processEntry(
          client: client,
          config: config,
          idToken: idToken,
          entry: entry,
        );

        switch (action) {
          case _ImportAction.imported:
            imported += 1;
          case _ImportAction.skipped:
            skipped += 1;
        }
      } catch (error) {
        errors += 1;
        stderr.writeln(
          '[ERROR] ${entry.documentId} | ${_basename(entry.audioFile.path)}: $error',
        );
      }
    }
  }

  return _ImportSummary(
    foldersScanned: yearFolders.length,
    processed: processed,
    imported: imported,
    skipped: skipped,
    errors: errors,
  );
}

List<_ImportEntry> _loadEntriesForYearFolder(
  _YearFolder yearFolder,
  _ImportConfig config,
) {
  final manifestFile = File(
    _joinPath(yearFolder.directory.path, config.manifestName),
  );

  if (manifestFile.existsSync()) {
    return _loadManifestEntries(
      yearFolder: yearFolder,
      config: config,
      manifestFile: manifestFile,
    );
  }

  if (config.requireManifest) {
    throw Exception(
      'Missing ${config.manifestName}. Re-run without --require-manifest or add a manifest file.',
    );
  }

  return _loadAutoMatchedEntries(yearFolder, config);
}

List<_ImportEntry> _loadManifestEntries({
  required _YearFolder yearFolder,
  required _ImportConfig config,
  required File manifestFile,
}) {
  final rows = _parseCsvFile(manifestFile);
  if (rows.isEmpty) {
    throw Exception('Manifest is empty: ${manifestFile.path}');
  }

  final header = rows.first.map(_normalizeHeader).toList();
  final audioIndex = header.indexOf('audio');
  final imageIndex = header.indexOf('image');
  final titleIndex = header.indexOf('title');
  final artistIndex = header.indexOf('artist');
  final documentIdIndex = _findFirstIndex(header, [
    'document_id',
    'documentid',
  ]);

  if (audioIndex == -1 || imageIndex == -1) {
    throw Exception(
      'Manifest must contain at least "audio" and "image" columns.',
    );
  }

  final entries = <_ImportEntry>[];
  final usedDocumentIds = <String>{};

  for (var index = 1; index < rows.length; index += 1) {
    final row = rows[index];
    if (row.every((cell) => cell.trim().isEmpty)) {
      continue;
    }

    final audioValue = _readCsvCell(row, audioIndex);
    final imageValue = _readCsvCell(row, imageIndex);

    if (audioValue.isEmpty || imageValue.isEmpty) {
      throw Exception('Manifest row ${index + 1} is missing audio or image.');
    }

    final audioFile = _resolveRelativeFile(
      baseDirectory: yearFolder.directory,
      relativeOrAbsolutePath: audioValue,
    );
    final imageFile = _resolveRelativeFile(
      baseDirectory: yearFolder.directory,
      relativeOrAbsolutePath: imageValue,
    );

    if (!audioFile.existsSync()) {
      throw Exception(
        'Manifest row ${index + 1} audio file not found: ${audioFile.path}',
      );
    }

    if (!imageFile.existsSync()) {
      throw Exception(
        'Manifest row ${index + 1} image file not found: ${imageFile.path}',
      );
    }

    final fallbackMetadata = _deriveMetadataFromStem(
      _basenameWithoutExtension(audioFile.path),
      config.defaultArtist,
    );
    final title = _readCsvCell(row, titleIndex).trim();
    final artist = _readCsvCell(row, artistIndex).trim();
    final rawDocumentId = _readCsvCell(row, documentIdIndex).trim();
    final documentId = rawDocumentId.isEmpty
        ? _buildDocumentId(
            year: yearFolder.year,
            sourceStem: _basenameWithoutExtension(audioFile.path),
          )
        : _validateDocumentId(rawDocumentId, index + 1);

    if (!usedDocumentIds.add(documentId)) {
      throw Exception(
        'Manifest row ${index + 1} creates duplicate document id: $documentId',
      );
    }

    entries.add(
      _ImportEntry(
        year: yearFolder.year,
        audioFile: audioFile,
        imageFile: imageFile,
        title: title.isEmpty ? fallbackMetadata.title : title,
        artist: artist.isEmpty ? fallbackMetadata.artist : artist,
        documentId: documentId,
      ),
    );
  }

  return entries;
}

List<_ImportEntry> _loadAutoMatchedEntries(
  _YearFolder yearFolder,
  _ImportConfig config,
) {
  final files = yearFolder.directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => !_isHiddenFile(file.path))
      .toList();

  final audioFiles = <File>[];
  final imageFiles = <File>[];

  for (final file in files) {
    final extension = _extension(file.path);

    if (_audioExtensions.contains(extension)) {
      audioFiles.add(file);
    } else if (_imageExtensions.contains(extension)) {
      imageFiles.add(file);
    }
  }

  audioFiles.sort((left, right) => left.path.compareTo(right.path));
  imageFiles.sort((left, right) => left.path.compareTo(right.path));

  if (audioFiles.isEmpty) {
    stdout.writeln(
      '[SKIP] ${_basename(yearFolder.directory.path)} | no audio files found',
    );
    return const [];
  }

  if (imageFiles.isEmpty) {
    stdout.writeln(
      '[SKIP] ${_basename(yearFolder.directory.path)} | no image files found',
    );
    return const [];
  }

  final uniqueImagesByStem = <String, File>{};
  for (final imageFile in imageFiles) {
    final stem = _basenameWithoutExtension(imageFile.path).toLowerCase();
    uniqueImagesByStem.putIfAbsent(stem, () => imageFile);
  }

  final exactImageForAudioPath = <String, File>{};
  final reservedImagePaths = <String>{};
  for (final audioFile in audioFiles) {
    final stem = _basenameWithoutExtension(audioFile.path).toLowerCase();
    final exactImage = uniqueImagesByStem[stem];
    if (exactImage != null) {
      exactImageForAudioPath[audioFile.path] = exactImage;
      reservedImagePaths.add(exactImage.path);
    }
  }

  final fallbackImages = imageFiles
      .where((imageFile) => !reservedImagePaths.contains(imageFile.path))
      .toList();
  final reusableImages = fallbackImages.isNotEmpty
      ? fallbackImages
      : imageFiles;

  stdout.writeln(
    '[INFO] ${_basename(yearFolder.directory.path)} | found ${audioFiles.length} audio and ${imageFiles.length} image files.',
  );
  if (imageFiles.length < audioFiles.length) {
    stdout.writeln(
      '[INFO] ${_basename(yearFolder.directory.path)} | fewer images than audio files, so images will be reused.',
    );
  }

  final entries = <_ImportEntry>[];
  final usedDocumentIds = <String>{};
  var fallbackIndex = 0;

  for (final audioFile in audioFiles) {
    final imageFile =
        exactImageForAudioPath[audioFile.path] ??
        reusableImages[fallbackIndex++ % reusableImages.length];
    final metadata = _deriveMetadataFromStem(
      _basenameWithoutExtension(audioFile.path),
      config.defaultArtist,
    );
    final documentId = _buildDocumentId(
      year: yearFolder.year,
      sourceStem: _basenameWithoutExtension(audioFile.path),
    );

    if (!usedDocumentIds.add(documentId)) {
      throw Exception(
        'Auto-match in ${_basename(yearFolder.directory.path)} produced duplicate document id: $documentId',
      );
    }

    entries.add(
      _ImportEntry(
        year: yearFolder.year,
        audioFile: audioFile,
        imageFile: imageFile,
        title: metadata.title,
        artist: metadata.artist,
        documentId: documentId,
      ),
    );
  }

  return entries;
}

Future<_ImportAction> _processEntry({
  required http.Client client,
  required _ImportConfig config,
  required String idToken,
  required _ImportEntry entry,
}) async {
  final existingDocument = await _getDocument(
    client: client,
    projectId: config.projectId,
    collection: config.collection,
    documentId: entry.documentId,
    idToken: idToken,
  );

  if (existingDocument != null && !config.overwriteExisting) {
    stdout.writeln(
      '[SKIP] ${entry.documentId} | already exists in ${config.collection}',
    );
    return _ImportAction.skipped;
  }

  stdout.writeln(
    '[PLAN] ${entry.documentId} | year=${entry.year} | title="${entry.title}" | artist="${entry.artist}" | audio=${_basename(entry.audioFile.path)} | image=${_basename(entry.imageFile.path)}',
  );

  if (!config.apply) {
    return _ImportAction.imported;
  }

  final uploadResults = await Future.wait([
    _uploadToCloudinary(
      client: client,
      file: entry.imageFile,
      cloudName: config.cloudName,
      uploadPreset: config.uploadPreset,
      resourceType: 'image',
      fallbackFileName: 'cover.jpg',
    ),
    _uploadToCloudinary(
      client: client,
      file: entry.audioFile,
      cloudName: config.cloudName,
      uploadPreset: config.uploadPreset,
      resourceType: 'video',
      fallbackFileName: 'audio.mp3',
    ),
  ]);

  final savedAt = DateTime(entry.year, 1, 1).toIso8601String();
  final fields = {
    'title': {'stringValue': entry.title},
    'artist': {'stringValue': entry.artist},
    'imageUrl': {'stringValue': uploadResults[0]},
    'audioUrl': {'stringValue': uploadResults[1]},
    'savedAt': {'stringValue': savedAt},
    'year': {'integerValue': entry.year.toString()},
    'trackInWeeklyStats': {'booleanValue': false},
  };

  await _upsertDocument(
    client: client,
    projectId: config.projectId,
    collection: config.collection,
    documentId: entry.documentId,
    fields: fields,
    updateMasks: fields.keys.toList(),
    idToken: idToken,
  );

  stdout.writeln('[DONE] ${entry.documentId}');
  return _ImportAction.imported;
}

Future<String> _uploadToCloudinary({
  required http.Client client,
  required File file,
  required String cloudName,
  required String uploadPreset,
  required String resourceType,
  required String fallbackFileName,
}) async {
  final uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
  );

  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: _basename(file.path).isEmpty
            ? fallbackFileName
            : _basename(file.path),
      ),
    );

  final response = await client.send(request);
  final body = await response.stream.bytesToString();
  final json = jsonDecode(body) as Map<String, dynamic>;

  if (response.statusCode >= 400 || json['secure_url'] == null) {
    final message =
        (json['error'] as Map<String, dynamic>?)?['message']?.toString() ??
        'Upload file thất bại';
    throw Exception(message);
  }

  return json['secure_url']?.toString() ?? '';
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
    '/v1/projects/$projectId/databases/(default)/documents/$collection/${Uri.encodeComponent(documentId)}',
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

  final data = jsonDecode(response.body) as Map<String, dynamic>;
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
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/${Uri.encodeComponent(documentId)}?$query',
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
        'Failed to write Firestore document';
    throw Exception(message);
  }
}

List<List<String>> _parseCsvFile(File file) {
  final lines = const LineSplitter().convert(file.readAsStringSync());
  final rows = <List<String>>[];

  for (var index = 0; index < lines.length; index += 1) {
    final rawLine = lines[index];
    final trimmedLine = rawLine.trim();

    if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
      continue;
    }

    final row = _parseCsvLine(rawLine);
    if (rows.isEmpty && row.isNotEmpty) {
      row[0] = row[0].replaceFirst('\ufeff', '');
    }
    rows.add(row);
  }

  return rows;
}

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var index = 0; index < line.length; index += 1) {
    final character = line[index];

    if (character == '"') {
      final nextIsQuote = index + 1 < line.length && line[index + 1] == '"';
      if (inQuotes && nextIsQuote) {
        buffer.write('"');
        index += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (character == ',' && !inQuotes) {
      cells.add(buffer.toString().trim());
      buffer.clear();
      continue;
    }

    buffer.write(character);
  }

  cells.add(buffer.toString().trim());
  return cells;
}

String _normalizeHeader(String value) {
  return value.trim().toLowerCase().replaceAll(' ', '_');
}

int _findFirstIndex(List<String> values, List<String> candidates) {
  for (final candidate in candidates) {
    final index = values.indexOf(candidate);
    if (index != -1) {
      return index;
    }
  }

  return -1;
}

String _readCsvCell(List<String> row, int index) {
  if (index < 0 || index >= row.length) {
    return '';
  }

  return row[index].trim();
}

File _resolveRelativeFile({
  required Directory baseDirectory,
  required String relativeOrAbsolutePath,
}) {
  if (_isAbsolutePath(relativeOrAbsolutePath)) {
    return File(relativeOrAbsolutePath);
  }

  return File(_joinPath(baseDirectory.path, relativeOrAbsolutePath));
}

bool _isAbsolutePath(String path) {
  if (path.startsWith('/')) {
    return true;
  }

  return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
}

bool _isHiddenFile(String path) {
  final name = _basename(path);
  return name.startsWith('.');
}

String _extension(String path) {
  final name = _basename(path);
  final dotIndex = name.lastIndexOf('.');

  if (dotIndex == -1 || dotIndex == name.length - 1) {
    return '';
  }

  return name.substring(dotIndex + 1).toLowerCase();
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final lastSlash = normalized.lastIndexOf('/');
  if (lastSlash == -1) {
    return normalized;
  }

  return normalized.substring(lastSlash + 1);
}

String _basenameWithoutExtension(String path) {
  final name = _basename(path);
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0) {
    return name;
  }

  return name.substring(0, dotIndex);
}

String _joinPath(String left, String right) {
  if (left.isEmpty) {
    return right;
  }
  if (right.isEmpty) {
    return left;
  }

  final normalizedRight = right.startsWith(Platform.pathSeparator)
      ? right.substring(1)
      : right;

  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }

  return '$left${Platform.pathSeparator}$normalizedRight';
}

_DerivedMetadata _deriveMetadataFromStem(String stem, String defaultArtist) {
  final cleanedStem = stem
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final separatorIndex = cleanedStem.indexOf(' - ');

  if (separatorIndex <= 0 || separatorIndex >= cleanedStem.length - 3) {
    return _DerivedMetadata(title: cleanedStem, artist: defaultArtist);
  }

  return _DerivedMetadata(
    artist: cleanedStem.substring(0, separatorIndex).trim(),
    title: cleanedStem.substring(separatorIndex + 3).trim(),
  );
}

String _buildDocumentId({required int year, required String sourceStem}) {
  final slug = _latinize(sourceStem)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  return '$year-${slug.isEmpty ? 'song' : slug}';
}

String _validateDocumentId(String value, int rowNumber) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw Exception('Manifest row $rowNumber has an empty document id.');
  }
  if (trimmed.contains('/')) {
    throw Exception(
      'Manifest row $rowNumber document id must not contain "/": $trimmed',
    );
  }

  return trimmed;
}

String _latinize(String value) {
  const replacements = <String, String>{
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
    'A': 'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ',
    'E': 'ÈÉẸẺẼÊỀẾỆỂỄ',
    'I': 'ÌÍỊỈĨ',
    'O': 'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ',
    'U': 'ÙÚỤỦŨƯỪỨỰỬỮ',
    'Y': 'ỲÝỴỶỸ',
    'D': 'Đ',
  };

  var result = value;
  replacements.forEach((ascii, accentedCharacters) {
    for (final character in accentedCharacters.split('')) {
      result = result.replaceAll(character, ascii);
    }
  });

  return result;
}

const Set<String> _audioExtensions = {
  'mp3',
  'm4a',
  'wav',
  'aac',
  'ogg',
  'flac',
};

const Set<String> _imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

class _ImportSummary {
  final int foldersScanned;
  final int processed;
  final int imported;
  final int skipped;
  final int errors;

  const _ImportSummary({
    required this.foldersScanned,
    required this.processed,
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}

class _YearFolder {
  final Directory directory;
  final int year;

  const _YearFolder({required this.directory, required this.year});
}

class _ImportEntry {
  final int year;
  final File audioFile;
  final File imageFile;
  final String title;
  final String artist;
  final String documentId;

  const _ImportEntry({
    required this.year,
    required this.audioFile,
    required this.imageFile,
    required this.title,
    required this.artist,
    required this.documentId,
  });
}

class _DerivedMetadata {
  final String title;
  final String artist;

  const _DerivedMetadata({required this.title, required this.artist});
}

enum _ImportAction { imported, skipped }

class _ImportConfig {
  static const String helpText =
      'Usage:\n'
      '  dart run tool/import_yearly_songs.dart --root /path/to/downloads --email admin@gmail.com --password your_password [--apply]\n'
      '\n'
      'What the script scans:\n'
      '  - Every folder matching music_YYYY under --root\n'
      '  - Example: /home/you/Downloads/music_2026\n'
      '  - Skip folders like music_favorite or picture automatically\n'
      '\n'
      'Supported folder styles:\n'
      '  1. With manifest.csv in each music_YYYY folder\n'
      '  2. Without manifest.csv, the script prefers same-name images, otherwise it auto-assigns available images and reuses them if needed\n'
      '\n'
      'Manifest example:\n'
      '  audio,image,title,artist\n'
      '  Em Cua Ngay Hom Qua.mp3,1.jpeg,Em Cua Ngay Hom Qua,Son Tung M-TP\n'
      '  Hay Noi Tinh Yeu Noi Ay Bay.mp3,2.jpeg,Hay Noi Tinh Yeu Noi Ay Bay,Chua cap nhat\n'
      '\n'
      'Options:\n'
      '  --root <value>           Folder containing one or more music_YYYY directories.\n'
      '  --email <value>          Firebase account email used to access Firestore.\n'
      '  --password <value>       Firebase account password.\n'
      '  --api-key <value>        Firebase Web API key. Defaults to current project config.\n'
      '  --project-id <value>     Firestore project id. Defaults to current project config.\n'
      '  --collection <value>     Firestore collection name. Default: yearly_songs.\n'
      '  --cloud-name <value>     Cloudinary cloud name. Default: current app value.\n'
      '  --upload-preset <value>  Cloudinary upload preset. Default: current app value.\n'
      '  --manifest-name <value>  Manifest filename. Default: manifest.csv.\n'
      '  --default-artist <value> Artist used when filename does not contain "Artist - Title".\n'
      '  --limit <value>          Process only the first N entries.\n'
      '  --require-manifest       Fail folders that do not contain a manifest file.\n'
      '  --overwrite-existing     Re-upload media and overwrite existing Firestore documents with the same document id.\n'
      '  --apply                  Actually upload to Cloudinary and write to Firestore. Without this flag the script is dry-run only.\n'
      '  --help                   Show this help.\n';

  final String rootPath;
  final String email;
  final String password;
  final String apiKey;
  final String projectId;
  final String collection;
  final String cloudName;
  final String uploadPreset;
  final String manifestName;
  final String defaultArtist;
  final int? limit;
  final bool requireManifest;
  final bool overwriteExisting;
  final bool apply;
  final bool showHelp;

  const _ImportConfig({
    required this.rootPath,
    required this.email,
    required this.password,
    required this.apiKey,
    required this.projectId,
    required this.collection,
    required this.cloudName,
    required this.uploadPreset,
    required this.manifestName,
    required this.defaultArtist,
    required this.limit,
    required this.requireManifest,
    required this.overwriteExisting,
    required this.apply,
    required this.showHelp,
  });

  factory _ImportConfig.parse(List<String> args) {
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

    return _ImportConfig(
      rootPath: options['root'] ?? '',
      email: options['email'] ?? '',
      password: options['password'] ?? '',
      apiKey: options['api-key'] ?? 'AIzaSyCaunJrZfmVkcX6XQidUh5fi6F7VntnZ8w',
      projectId: options['project-id'] ?? 'appmusi-4ff75',
      collection: options['collection'] ?? 'yearly_songs',
      cloudName: options['cloud-name'] ?? 'ddy9wgrbj',
      uploadPreset: options['upload-preset'] ?? 'musicapp',
      manifestName: options['manifest-name'] ?? 'manifest.csv',
      defaultArtist: options['default-artist'] ?? 'Chua cap nhat',
      limit: int.tryParse(options['limit'] ?? ''),
      requireManifest: flags.contains('require-manifest'),
      overwriteExisting: flags.contains('overwrite-existing'),
      apply: flags.contains('apply'),
      showHelp: flags.contains('help'),
    );
  }

  bool get isValid =>
      rootPath.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      password.trim().isNotEmpty;

  String get validationError {
    if (rootPath.trim().isEmpty) {
      return 'Missing required argument: --root';
    }
    if (email.trim().isEmpty) {
      return 'Missing required argument: --email';
    }
    if (password.trim().isEmpty) {
      return 'Missing required argument: --password';
    }

    return 'Invalid configuration';
  }
}
