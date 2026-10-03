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

Future<void> _openInBrowser(String url) async {
  final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!launched) throw Exception('تعذّر فتح المتصفح');
}

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
