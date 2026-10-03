import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
    if (kIsWeb) {
      await _openInBrowser(url);
      return 'فُتح الملف في المتصفح لحفظه';
    }
    await _fetchBytes(url);
    await _openInBrowser(url);
    return 'تعذّر الحفظ المباشر، فُتح الملف في المتصفح';
  } catch (_) {
    try {
      await _openInBrowser(url);
      return 'تعذّر حفظ الملف، فُتح الرابط في المتصفح';
    } catch (_) {
      return 'تعذّر حفظ الملف، تحقق من الإنترنت';
    }
  }
}
