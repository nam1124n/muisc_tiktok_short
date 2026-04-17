// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:image_picker/image_picker.dart';

Future<XFile?> pickAudioFile() {
  final completer = Completer<XFile?>();
  final input = html.FileUploadInputElement()
    ..accept = 'audio/*,.mp3,.m4a,.wav,.aac,.ogg,.flac'
    ..multiple = false;

  input.onChange.first.then((_) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }

    completer.complete(
      XFile(
        html.Url.createObjectUrl(file),
        name: file.name,
        length: file.size,
        mimeType: file.type,
      ),
    );
  });

  input.click();
  return completer.future;
}
