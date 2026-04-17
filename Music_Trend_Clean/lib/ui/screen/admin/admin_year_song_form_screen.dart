import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/app/utils/audio_file_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';
import 'package:login_flutter/ui/screen/admin/widgets/label_text.dart';
import 'package:login_flutter/ui/screen/genre/providers/year_song_provider.dart';

class AdminYearSongFormScreen extends ConsumerStatefulWidget {
  final SongEntity? initialSong;

  const AdminYearSongFormScreen({super.key, this.initialSong});

  @override
  ConsumerState<AdminYearSongFormScreen> createState() =>
      _AdminYearSongFormScreenState();
}

class _AdminYearSongFormScreenState
    extends ConsumerState<AdminYearSongFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  XFile? _pickedAudio;
  int? _selectedYear;

  bool get _isEditing => widget.initialSong != null;
  bool get _hasExistingImage => (widget.initialSong?.imageUrl ?? '').isNotEmpty;
  bool get _hasExistingAudio => (widget.initialSong?.audioUrl ?? '').isNotEmpty;
  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(
      (currentYear - 1950) + 2,
      (index) => currentYear + 1 - index,
    );

    final initialYear = widget.initialSong?.savedAt?.year;
    if (initialYear != null && !years.contains(initialYear)) {
      years.add(initialYear);
      years.sort((left, right) => right.compareTo(left));
    }

    return years;
  }

  @override
  void initState() {
    super.initState();

    final initialSong = widget.initialSong;
    if (initialSong == null) {
      return;
    }

    _titleController.text = initialSong.title;
    _artistController.text = initialSong.artist;
    _selectedYear = initialSong.savedAt?.year;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pickedImage = file;
      _pickedImageBytes = bytes;
    });
  }

  Future<void> _pickAudio() async {
    final file = await pickAudioFile();
    if (file == null || !mounted) return;
    setState(() => _pickedAudio = file);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.coverImageRequiredMessage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isEditing && _pickedAudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.audioFileRequiredMessage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.yearRequiredMessage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final song = SongEntity(
      id: widget.initialSong?.id ?? '',
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      audioUrl: widget.initialSong?.audioUrl ?? '',
      imageUrl: widget.initialSong?.imageUrl ?? '',
      savedAt: DateTime(_selectedYear!, 1, 1),
      trackInWeeklyStats: false,
    );

    if (_isEditing) {
      await ref
          .read(yearSongNotifierProvider.notifier)
          .updateSong(song, imageFile: _pickedImage, audioFile: _pickedAudio);
    } else {
      await ref
          .read(yearSongNotifierProvider.notifier)
          .addSong(song, _pickedImage!, _pickedAudio!);
    }

    if (!mounted) {
      return;
    }

    final state = ref.read(yearSongNotifierProvider);
    if (state is SongActionSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.actionSuccessMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      ref.read(yearSongNotifierProvider.notifier).loadSongs();
      Navigator.pop(context);
    } else if (state is SongError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorLabel}: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(yearSongNotifierProvider);
    final isLoading = state is SongLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editYearSongTitle : l10n.newYearSongTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8C52FF),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabelText(l10n.coverImageLabel),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isLoading ? null : _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedImage != null || _hasExistingImage
                          ? const Color(0xFF8C52FF)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _pickedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _pickedImageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : _hasExistingImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            widget.initialSong!.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) =>
                                _buildImagePlaceholder(l10n),
                          ),
                        )
                      : _buildImagePlaceholder(l10n),
                ),
              ),
              const SizedBox(height: 24),
              LabelText(l10n.audioFilePickerLabel),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isLoading ? null : _pickAudio,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedAudio != null || _hasExistingAudio
                          ? const Color(0xFF8C52FF)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pickedAudio != null || _hasExistingAudio
                            ? Icons.audio_file
                            : Icons.upload_file,
                        color: _pickedAudio != null || _hasExistingAudio
                            ? const Color(0xFF8C52FF)
                            : Colors.grey[400],
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _audioDisplayLabel(l10n),
                          style: TextStyle(
                            color: _pickedAudio != null || _hasExistingAudio
                                ? Colors.black87
                                : Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LabelText(l10n.songTitleLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                enabled: !isLoading,
                decoration: _inputDeco(l10n.songTitleHint),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.songTitleRequiredMessage
                    : null,
              ),
              const SizedBox(height: 20),
              LabelText(l10n.artistNameLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _artistController,
                enabled: !isLoading,
                decoration: _inputDeco(l10n.artistNameHint),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.artistNameRequiredMessage
                    : null,
              ),
              const SizedBox(height: 20),
              LabelText(l10n.yearLabel),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                decoration: _inputDeco(l10n.selectYearHint),
                items: _availableYears
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      ),
                    )
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) => setState(() => _selectedYear = value),
                validator: (value) =>
                    value == null ? l10n.yearRequiredMessage : null,
              ),
              const SizedBox(height: 36),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C52FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isEditing
                                  ? l10n.savingSongChanges
                                  : l10n.uploadingSong,
                            ),
                          ],
                        )
                      : Text(
                          _isEditing
                              ? l10n.saveSongChanges
                              : l10n.addYearSongLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400]),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFF8C52FF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );

  Widget _buildImagePlaceholder(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(l10n.chooseCoverImage, style: TextStyle(color: Colors.grey[500])),
      ],
    );
  }

  String _audioDisplayLabel(AppLocalizations l10n) {
    if (_pickedAudio != null) {
      return _pickedAudio!.name;
    }

    final audioUrl = widget.initialSong?.audioUrl ?? '';
    if (audioUrl.isNotEmpty) {
      return l10n.currentAudioWillBeKept(_extractFileName(audioUrl));
    }

    return l10n.selectAudioFile;
  }

  String _extractFileName(String url) {
    final uri = Uri.tryParse(url);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : url;

    return Uri.decodeComponent(lastSegment);
  }
}
