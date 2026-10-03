import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

Future<Duration?> videoDurationImpl(String path, {Uint8List? bytes}) async {
  VideoPlayerController controller;
  if (kIsWeb && bytes != null) {
    controller = VideoPlayerController.contentUri(Uri.dataFromBytes(bytes));
  } else {
    controller = VideoPlayerController.file(File(path));
  }
  try {
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();
    return duration;
  } catch (_) {
    try {
      await controller.dispose();
    } catch (_) {}
    return null;
  }
}