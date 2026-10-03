import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  Future<String> uploadPostImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('يجب تسجيل الدخول لرفع الصور');
    }
    final safeName = fileName.isEmpty ? 'post_image.jpg' : fileName;
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}__$safeName';
    final contentType = safeName.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    await _client.storage.from(AppConfig.postsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
          retryAttempts: 2,
        );
    return _client.storage.from(AppConfig.postsBucket).getPublicUrl(path);
  }

  Future<String> uploadPostVideo({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('يجب تسجيل الدخول لرفع الفيديو');
    }
    final safeName = fileName.isEmpty ? 'post_video.mp4' : fileName;
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}__$safeName';
    final contentType = _videoContentType(safeName);
    await _client.storage.from(AppConfig.postsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
          retryAttempts: 2,
        );
    return _client.storage.from(AppConfig.postsBucket).getPublicUrl(path);
  }

  Future<String> uploadMusic({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('يجب تسجيل الدخول لرفع المقاطع الصوتية');
    }
    final safeName = fileName.isEmpty ? 'track_audio.mp3' : fileName;
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}__$safeName';
    final contentType = _audioContentType(safeName);
    await _client.storage.from(AppConfig.musicBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
          retryAttempts: 2,
        );
    return _client.storage.from(AppConfig.musicBucket).getPublicUrl(path);
  }

  Future<void> deleteByPublicUrl(String publicUrl, {String? bucket}) async {
    final targetBucket = bucket ?? AppConfig.postsBucket;
    final marker = '/object/public/$targetBucket/';
    final index = publicUrl.indexOf(marker);
    if (index == -1) return;
    final path = publicUrl.substring(index + marker.length);
    if (path.isEmpty || path.contains('?')) return;
    try {
      await _client.storage.from(targetBucket).remove([path]);
    } catch (_) {
      // الحذف اختياري للتنظيف ولا يُفشل العملية
    }
  }

  String _audioContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    if (lower.endsWith('.opus')) return 'audio/ogg';
    if (lower.endsWith('.flac')) return 'audio/flac';
    if (lower.endsWith('.aiff')) return 'audio/aiff';
    if (lower.endsWith('.aif')) return 'audio/aiff';
    if (lower.endsWith('.amr')) return 'audio/amr';
    if (lower.endsWith('.mpeg')) return 'audio/mpeg';
    return 'audio/mpeg';
  }

  String _videoContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    return 'video/mp4';
  }
}