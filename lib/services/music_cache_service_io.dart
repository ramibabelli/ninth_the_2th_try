import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/music_track.dart';

/// يخزن المعزوفات محلياً على جهاز المستخدم للتشغيل دون إنترنت.
class MusicCacheService extends ChangeNotifier {
  final http.Client _client;

  MusicCacheService({http.Client? client}) : _client = client ?? http.Client();

  Directory? _cacheDir;
  bool _ready = false;
  final Set<String> _downloading = {};
  final Map<String, double> _progress = {};

  Future<Directory> _dir() async {
    if (_ready && _cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/music_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _cacheDir = dir;
    _ready = true;
    return dir;
  }

  String _fileName(MusicTrack track) {
    var ext = '.mp3';
    final url = track.audioUrl;
    if (url != null) {
      try {
        final path = Uri.parse(url).path;
        final dot = path.lastIndexOf('.');
        if (dot != -1 && dot < path.length - 1) {
          final candidate = path.substring(dot);
          if (candidate.length <= 10 &&
              RegExp(r'^\.[A-Za-z0-9]+$').hasMatch(candidate)) {
            ext = candidate;
          }
        }
      } catch (_) {
        // تجاهل روابط غير صالحة
      }
    }
    final safeId = track.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '$safeId$ext';
  }

  String? _pathFor(MusicTrack track) {
    final dir = _cacheDir;
    if (dir == null) return null;
    final file = File('${dir.path}/${_fileName(track)}');
    return file.existsSync() ? file.path : null;
  }

  bool isDownloading(MusicTrack track) => _downloading.contains(track.id);

  double progressFor(MusicTrack track) => _progress[track.id] ?? 0;

  bool isCachedSync(MusicTrack track) => _pathFor(track) != null;

  Future<String?> localPathFor(MusicTrack track) async {
    await _dir();
    return _pathFor(track);
  }

  Future<void> download(
    MusicTrack track, {
    void Function(double progress)? onProgress,
  }) async {
    final url = track.audioUrl;
    if (url == null || url.trim().isEmpty) {
      throw StateError('لا يوجد ملف صوتي لهذه المعزوفة');
    }
    final dir = await _dir();
    final file = File('${dir.path}/${_fileName(track)}');
    if (file.existsSync()) return;
    if (_downloading.contains(track.id)) return;

    _downloading.add(track.id);
    _progress[track.id] = 0;
    notifyListeners();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamed = await _client.send(request);
      if (streamed.statusCode != 200) {
        throw http.ClientException(
          'فشل التنزيل (${streamed.statusCode})',
          Uri.parse(url),
        );
      }

      final total = streamed.contentLength ?? 0;
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in streamed.stream) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0) {
            _progress[track.id] =
                (received / total).clamp(0.0, 1.0).toDouble();
          }
          onProgress?.call(_progress[track.id] ?? 0);
          notifyListeners();
        }
      } finally {
        await sink.close();
      }

      _progress.remove(track.id);
      notifyListeners();
    } catch (_) {
      _progress.remove(track.id);
      notifyListeners();
      rethrow;
    } finally {
      _downloading.remove(track.id);
      notifyListeners();
    }
  }

  Future<void> delete(MusicTrack track) async {
    await _dir();
    final file = File('${_cacheDir!.path}/${_fileName(track)}');
    if (file.existsSync()) {
      await file.delete();
      notifyListeners();
    }
  }
}
