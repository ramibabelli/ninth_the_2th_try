import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<Uint8List> _fetchBytes(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('فشل التحميل من الخادم');
  }
  return response.bodyBytes;
}

String _fileNameFromUrl(String url) {
  final clean = url.split('?').first;
  final segments = clean.split('/');
  final last = segments.isNotEmpty ? segments.last : '';
  return last.isEmpty ? 'post_media' : last;
}

String _baseName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0) return fileName;
  return fileName.substring(0, dot);
}

Future<void> _openInBrowser(String url) async {
  final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!launched) throw Exception('تعذّر فتح المتصفح');
}

/// يحفظ صورة أو فيديو من رابط عام إلى جهاز المستخدم.
/// يعمل على أندرويد/iOS/ماك/ويندوز/لينكس عبر المعرض،
/// وعلى الويب (وغير المدعوم) يفتح الرابط ليُحفظ يدويًا.
/// يرجع رسالة تُعرض للمستخدم.
Future<String> saveMediaToDevice({
  required String url,
  required bool isVideo,
}) async {
  try {
    final bytes = await _fetchBytes(url);
    final fileName = _fileNameFromUrl(url);

    if (kIsWeb) {
      await _openInBrowser(url);
      return 'فُتح الملف في المتصفح لحفظه';
    }

    if (!await Gal.hasAccess()) {
      final granted = await Gal.requestAccess();
      if (!granted) return 'تم رفض إذن الحفظ في المعرض';
    }

    if (isVideo) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await Gal.putVideo(file.path, album: 'Ninth Scout');
      return 'تم حفظ الفيديو في معرض الجهاز';
    }

    await Gal.putImageBytes(bytes, name: _baseName(fileName), album: 'Ninth Scout');
    return 'تم حفظ الصورة في معرض الجهاز';
  } on GalException {
    return 'تعذّر الحفظ، امنح إذن الوصول إلى الصور ثم حاول مجددًا';
  } catch (_) {
    try {
      await _openInBrowser(url);
      return 'تعذّر الحفظ المباشر، فُتح الملف في المتصفح';
    } catch (_) {
      return 'تعذّر حفظ الملف، تحقق من الإنترنت';
    }
  }
}
