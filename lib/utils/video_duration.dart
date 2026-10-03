import 'dart:typed_data';

import 'video_duration_stub.dart' if (dart.library.io) 'video_duration_io.dart';

/// يرجع مدة الفيديو في المسار المعطى.
/// يرجع null في البيئات غير المدعومة (مثل الويب) أو عند فشل الفحص.
Future<Duration?> videoDurationOf(String path) => videoDurationImpl(path);

/// يتحقق أن الفيديو لا يتجاوز المدة القصوى.
/// عند تعذّر الفحص يُفسَّر ذلك كقبول (للأمان لا نمنع المستخدم بلا سبب).
Future<bool> isVideoWithinLimit(
  String path, {
  Uint8List? bytes,
  Duration max = const Duration(minutes: 1),
}) async {
  final duration = await videoDurationImpl(path, bytes: bytes);
  if (duration == null) return true;
  return duration <= max;
}