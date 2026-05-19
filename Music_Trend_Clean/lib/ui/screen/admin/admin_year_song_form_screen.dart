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
  String _selectedAudioType = SongAudioTypes.short;

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
    _selectedYear = initialSong.releaseYear ?? initialSong.savedAt?.year;
    _selectedAudioType = initialSong.audioType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

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
      audioType: _selectedAudioType,
      releaseYear: _selectedYear,
      trackInWeeklyStats: widget.initialSong?.trackInWeeklyStats ?? false,
      status: widget.initialSong?.status ?? SongStatuses.pending,
      moderationReason: widget.initialSong?.moderationReason ?? '',
      moderatedBy: widget.initialSong?.moderatedBy ?? '',
      moderatedAt: widget.initialSong?.moderatedAt,
      publishedAt: widget.initialSong?.publishedAt,
      updatedAt: widget.initialSong?.updatedAt,
      deletedAt: widget.initialSong?.deletedAt,
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
    if (state is! SongError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.actionSuccessMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      ref.read(yearSongNotifierProvider.notifier).loadSongs();
      Navigator.pop(context);
    } else {
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1180 : 720),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIntroCard(
                        title: _isEditing
                            ? l10n.editYearSongTitle
                            : l10n.newYearSongTitle,
                        subtitle: _isEditing
                            ? l10n.saveSongChanges
                            : l10n.addYearSongLabel,
                      ),
                      if (!_isEditing) ...[
                        const SizedBox(height: 16),
                        _buildPendingNotice(l10n),
                      ],
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildMediaPanel(l10n, isLoading)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildDetailsPanel(l10n, isLoading),
                            ),
                          ],
                        )
                      else ...[
                        _buildMediaPanel(l10n, isLoading),
                        const SizedBox(height: 24),
                        _buildDetailsPanel(l10n, isLoading),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C52FF), Color(0xFFB985FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C52FF).withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotice(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.adminPendingSubmissionNotice,
              style: const TextStyle(
                color: Color(0xFF9A6700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPanel(AppLocalizations l10n, bool isLoading) {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabelText(l10n.coverImageLabel),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isLoading ? null : _pickImage,
            child: Container(
              height: 220,
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
                        errorBuilder: (_, _, _) => _buildImagePlaceholder(l10n),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(AppLocalizations l10n, bool isLoading) {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  (year) =>
                      DropdownMenuItem<int>(value: year, child: Text('$year')),
                )
                .toList(),
            onChanged: isLoading
                ? null
                : (value) => setState(() => _selectedYear = value),
            validator: (value) =>
                value == null ? l10n.yearRequiredMessage : null,
          ),
          const SizedBox(height: 20),
          LabelText(_isVi ? 'Loại nhạc' : 'Audio type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedAudioType,
            decoration: _inputDeco(_isVi ? 'Chọn loại nhạc' : 'Select type'),
            items: const [
              DropdownMenuItem(
                value: SongAudioTypes.short,
                child: Text('Nhạc ngắn / Short'),
              ),
              DropdownMenuItem(
                value: SongAudioTypes.full,
                child: Text('Bản đầy đủ / Full'),
              ),
            ],
            onChanged: isLoading
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _selectedAudioType = value);
                  },
          ),
          const SizedBox(height: 36),
          SizedBox(height: 56, child: _buildSubmitButton(l10n, isLoading)),
        ],
      ),
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8C52FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Text(_isEditing ? l10n.savingSongChanges : l10n.uploadingSong),
              ],
            )
          : Text(
              _isEditing ? l10n.saveSongChanges : l10n.addYearSongLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
