import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/music_track.dart';

class MusicCacheService extends ChangeNotifier {
  final http.Client _client;

  MusicCacheService({http.Client? client}) : _client = client ?? http.Client();

  final Set<String> _downloading = {};
  final Map<String, double> _progress = {};

  bool isDownloading(MusicTrack track) => _downloading.contains(track.id);

  double progressFor(MusicTrack track) => _progress[track.id] ?? 0;

  bool isCachedSync(MusicTrack track) => false;

  Future<String?> localPathFor(MusicTrack track) async {
    return null;
  }

  Future<void> download(
    MusicTrack track, {
    void Function(double progress)? onProgress,
  }) async {
    final url = track.audioUrl;
    if (url == null || url.trim().isEmpty) {
      throw StateError('لا يوجد ملف صوتي لهذه المعزوفة');
    }
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
      var received = 0;
      await for (final chunk in streamed.stream) {
        received += chunk.length;
        if (total > 0) {
          _progress[track.id] =
              (received / total).clamp(0.0, 1.0).toDouble();
        }
        onProgress?.call(_progress[track.id] ?? 0);
        notifyListeners();
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
    notifyListeners();
  }

  Future<List<int>?> cachedBytes(MusicTrack track) async {
    return null;
  }
}
