// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:image_picker/image_picker.dart';

const XTypeGroup _audioTypeGroup = XTypeGroup(
  label: 'audio',
  extensions: <String>['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'],
  mimeTypes: <String>[
    'audio/mpeg',
    'audio/mp4',
    'audio/x-m4a',
    'audio/wav',
    'audio/x-wav',
    'audio/aac',
    'audio/ogg',
    'audio/flac',
  ],
  uniformTypeIdentifiers: <String>['public.audio'],
);

Future<XFile?> pickAudioFile() async {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    try {
      return await FileSelectorPlatform.instance.openFile(
        acceptedTypeGroups: const <XTypeGroup>[_audioTypeGroup],
      );
    } catch (_) {
      // Fall through to the legacy picker if no desktop file selector is registered.
    }
  }

  return ImagePicker().pickMedia();
}
