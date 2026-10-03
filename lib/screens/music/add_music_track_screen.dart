import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/music_track.dart';
import '../../services/auth_service.dart';
import '../../services/music_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/responsive_page.dart';

class AddMusicTrackScreen extends StatefulWidget {
  final MusicTrack? initialTrack;

  const AddMusicTrackScreen({super.key, this.initialTrack});

  @override
  State<AddMusicTrackScreen> createState() => _AddMusicTrackScreenState();
}

class _AddMusicTrackScreenState extends State<AddMusicTrackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final AudioPlayer _player;
  late final Timer _timer;

  String? _audioUrl;
  PlatformFile? _audioFile;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isPlaying) return;
    });

    final track = widget.initialTrack;
    if (track != null) {
      _titleController.text = track.title;
      _notesController.text = track.notes ?? '';
      _descriptionController.text = track.description ?? '';
      _audioUrl = track.audioUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    _timer.cancel();
    _player.dispose();
    super.dispose();
  }

  String get _audioLabel => _audioFile?.name ?? _audioUrl ?? '';

  Future<void> _pickAudio() async {
    if (_isLoading || _isUploading) return;
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
    );
    if (result.isEmpty || !mounted) return;
    final file = result.first;
    setState(() {
      _audioFile = file;
      _audioUrl = null;
    });
  }

  void _clearAudio() {
    setState(() {
      _audioFile = null;
      _audioUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final canEditMusic = auth.canEditMusic;

    final saving = _isLoading || _isUploading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTrack != null ? 'تعديل النشيد' : 'معزوفة جديدة',
        ),
        actions: [
          if (canEditMusic) ...[
            IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: 'حفظ',
              onPressed: saving ? null : _submitTrack,
            ),
          ],
        ],
      ),
      body: ResponsivePage(
        maxWidth: 850,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المعزوفة',
                      hintText: 'ادخل اسم المعزوفة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يجب إدخال اسم المعزوفة';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      hintText: 'وصف للمعزوفة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                    maxLines: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'النوتات (دو - ري - مي)',
                      hintText: 'مثل: دو - ري - مي - Fa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_rounded),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المقطع الصوتي الرئيسي',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_audioLabel.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.audio_file_rounded),
                          title: Text(
                            _audioLabel.length > 40
                                ? '${_audioLabel.substring(0, 40)}...'
                                : _audioLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'إزالة',
                            onPressed: saving ? null : _clearAudio,
                          ),
                        )
                      else
                        InkWell(
                          onTap: saving ? null : _pickAudio,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.upload_file_rounded,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text('اختر ملف صوتي'),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: saving ? null : _pickAudio,
                        icon: const Icon(Icons.music_note_rounded),
                        label: const Text('اختيار ملف صوتي'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      saving || _titleController.text.trim().isEmpty
                          ? null
                          : _submitTrack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: saving
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
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
                              _isUploading
                                  ? 'جاري رفع المقطع الصوتي...'
                                  : 'جاري الحفظ...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'حفظ المعزوفة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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

  Future<void> _submitTrack() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final musicService = context.read<MusicService>();
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null;
      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      String? audioUrl = _audioUrl;
      if (_audioFile != null) {
        setState(() => _isUploading = true);
        try {
          final storage = context.read<StorageService>();
          final bytesData = (_audioFile as dynamic).bytes;
          if (bytesData == null) {
            throw Exception('تعذّر قراءة ملف الصوت');
          }
          final data = bytesData is Uint8List ? bytesData : Uint8List.fromList(bytesData);
          audioUrl = await storage.uploadMusic(
            bytes: data,
            fileName: _audioFile!.name,
          );
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      }

      if (widget.initialTrack != null) {
        await musicService.updateTrack(
          MusicTrack(
            id: widget.initialTrack!.id,
            title: title,
            description: description,
            notes: notes,
            audioUrl: audioUrl,
            createdAt: widget.initialTrack?.createdAt,
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل المعزوفة بنجاح')),
        );
      } else {
        await musicService.createTrack(
          title: title,
          description: description,
          notes: notes,
          audioUrl: audioUrl,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المعزوفة بنجاح')),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ، حاول مرة أخرى'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}